//
//  PoliceAPI.swift
//  CrimeNearMe
//
//  Service layer for interacting with the UK Police API (data.police.uk)
//

import Foundation

/// Service class for fetching crime data from the UK Police API
/// 
/// This class provides methods to query crime data by location and date range.
/// It includes robust error handling and fallback mechanisms for when data
/// is unavailable for specific months or locations.
/// 
/// The UK Police API provides crime data with some limitations:
/// - Data is typically 2-3 months behind current date
/// - Some months may have no data available (404 responses)
/// - Rate limiting may apply for high-frequency requests
final class PoliceAPI {
    /// Shared singleton instance
    static let shared = PoliceAPI()
    
    /// Base URL for the UK Police API
    private let base = URL(string: "https://data.police.uk/api")!

    // MARK: - Public API Methods

    /// Fetches crimes for a specific month and location
    /// 
    /// This method queries the UK Police API for crime data within a specific
    /// time period and geographic area. You can specify either coordinates
    /// or a polygon boundary for the search area.
    /// 
    /// - Parameters:
    ///   - lat: Latitude coordinate (ignored if poly is provided)
    ///   - lng: Longitude coordinate (ignored if poly is provided)
    ///   - poly: Polygon boundary string in "lat1,lon1:lat2,lon2:..." format
    ///   - isoMonth: Month in YYYY-MM format (e.g., "2024-06")
    /// - Returns: Array of Crime objects for the specified criteria
    /// - Throws: PoliceAPIError for various failure conditions
    func crimes(lat: Double? = nil, lng: Double? = nil, poly: String? = nil, isoMonth: String) async throws -> [Crime] {
        var comps = URLComponents(
            url: base.appendingPathComponent("crimes-street/all-crime"),
            resolvingAgainstBaseURL: false
        )!

        var items: [URLQueryItem] = [
            .init(name: "date", value: isoMonth)
        ]

        if let poly = poly {
            items.append(.init(name: "poly", value: poly))
        } else if let lat = lat, let lng = lng {
            items.append(.init(name: "lat", value: String(lat)))
            items.append(.init(name: "lng", value: String(lng)))
        }

        comps.queryItems = items

        guard let url = comps.url else { throw PoliceAPIError.badBody("bad URL components") }

        print("[DEBUG][GET]", url.absoluteString)

        let (data, resp) = try await URLSession.shared.data(from: url)
        guard let http = resp as? HTTPURLResponse else { throw PoliceAPIError.http(-1) }

        if http.statusCode == 404 {
            throw PoliceAPIError.noDataForMonth
        }
        guard (200..<300).contains(http.statusCode) else {
            throw PoliceAPIError.http(http.statusCode)
        }

        do {
            return try JSONDecoder().decode([Crime].self, from: data)
        } catch {
            let snippet = String(data: data.prefix(200), encoding: .utf8) ?? "non-utf8"
            throw PoliceAPIError.badBody(snippet)
        }
    }

    /// Fetches crimes across multiple polygons and multiple months
    /// 
    /// This method performs bulk queries across multiple geographic areas
    /// and time periods, merging all results into a single dataset.
    /// It's used to get comprehensive coverage of the Manchester area.
    /// 
    /// - Parameters:
    ///   - monthsBack: Number of months to query (including current month)
    ///   - polys: Array of polygon boundary strings
    ///   - start: Starting date for the query range
    /// - Returns: Tuple containing the months queried and merged crime array
    /// - Throws: PoliceAPIError if all queries fail
    func crimesLastMonths(
        monthsBack: Int,
        polys: [String],
        from start: Date
    ) async throws -> (months: [String], crimes: [Crime]) {
        let count = max(1, monthsBack)
        var monthsUsed: [String] = []
        var merged: [Crime] = []

        for back in 0..<count {
            let d = Calendar.current.date(byAdding: .month, value: -back, to: start)!
            let m = Self.isoMonth(d)

            var monthTotal = 0
            for p in polys {
                do {
                    let chunk = try await crimes(poly: p, isoMonth: m)
                    merged.append(contentsOf: chunk)
                    monthTotal += chunk.count
                    print("[DEBUG][POLY]", m, "count=\(chunk.count)", "poly=\(p)")
                } catch let e as PoliceAPIError {
                    switch e {
                    case .noDataForMonth:
                        print("[DEBUG][POLY]", m, "→ 404 for poly=\(p)")
                    case .badBody(let snippet):
                        print("[DEBUG][POLY]", m, "→ bad body for poly=\(p):", snippet)
                    case .http(let code):
                        print("[DEBUG][POLY]", m, "→ HTTP \(code) for poly=\(p)")
                    }
                    continue // try next poly for the same month
                } catch {
                    print("[DEBUG][POLY]", m, "→ error for poly=\(p):", error.localizedDescription)
                    continue
                }
            }

            // Record that we attempted this calendar month (even if empty), then move on
            monthsUsed.append(m)
            print("[DEBUG][MONTH]", m, "→ monthTotal=\(monthTotal)")
        }

        return (monthsUsed, merged)
    }
    
    /// Try current month, then previous, up to `window` months back (default 6); return the first non-empty month.
    /// Useful when you only want ONE month’s snapshot.
    func crimesWithFallback(
        lat: Double,
        lng: Double,
        from start: Date,
        window: Int = 6
    ) async throws -> (month: String, crimes: [Crime]) {
        for back in 0..<max(1, window) {
            let d = Calendar.current.date(byAdding: .month, value: -back, to: start)!
            let m = Self.isoMonth(d)
            do {
                let list = try await crimes(lat: lat, lng: lng, isoMonth: m)
                print("[DEBUG][MONTH]", m, "→ totalReturned:", list.count)
                if !list.isEmpty { return (m, list) }
            } catch let e as PoliceAPIError {
                switch e {
                case .noDataForMonth:
                    print("[DEBUG][MONTH]", m, "→ 404/empty month")
                case .badBody(let snippet):
                    print("[DEBUG][MONTH]", m, "→ unexpected body:", snippet)
                case .http(let code):
                    print("[DEBUG][MONTH]", m, "→ HTTP error:", code)
                }
                // continue to next month
            } catch {
                print("[DEBUG][MONTH]", m, "→ generic error:", error.localizedDescription)
            }
        }
        // Nothing usable; return oldest attempted month with empty
        let oldest = Self.isoMonth(Calendar.current.date(byAdding: .month, value: -(max(1, window) - 1), to: start)!)
        return (oldest, [])
    }

    /// Fetch up to `monthsBack` months (including current month) and MERGE results.
    /// Returns the list of months actually used (newest → oldest) and the combined crimes.
    /// NOTE: no de-duplication — we trust the API entries are distinct enough for counting.
    func crimesLast(
        monthsBack: Int,
        lat: Double,
        lng: Double,
        from start: Date
    ) async throws -> (months: [String], crimes: [Crime]) {
        let count = max(1, monthsBack)

        var monthsUsed: [String] = []
        var merged: [Crime] = []

        for back in 0..<count {
            let d = Calendar.current.date(byAdding: .month, value: -back, to: start)!
            let m = Self.isoMonth(d)
            do {
                let list = try await crimes(lat: lat, lng: lng, isoMonth: m)
                print("[DEBUG][MONTH]", m, "→ totalReturned:", list.count)

                if !list.isEmpty {
                    monthsUsed.append(m)
                    // No dedup — append everything
                    merged.append(contentsOf: list)
                }
            } catch let e as PoliceAPIError {
                switch e {
                case .noDataForMonth:
                    print("[DEBUG][MONTH]", m, "→ 404/empty month")
                case .badBody(let snippet):
                    print("[DEBUG][MONTH]", m, "→ unexpected body:", snippet)
                case .http(let code):
                    print("[DEBUG][MONTH]", m, "→ HTTP error:", code)
                }
                // continue to next month
            } catch {
                print("[DEBUG][MONTH]", m, "→ generic error:", error.localizedDescription)
            }
        }

        return (monthsUsed, merged)
    }
    // MARK: - Date Formatting Utilities

    /// Converts a Date to ISO month format required by the Police API
    /// - Parameter date: The date to convert
    /// - Returns: ISO month string in YYYY-MM format (e.g., "2024-06")
    static func isoMonth(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM"
        f.timeZone = .gmt
        return f.string(from: date)
    }

    /// “June 2025” for UI
    static func humanMonth(_ iso: String) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM"
        f.timeZone = .gmt
        guard let d = f.date(from: iso) else { return iso }
        let out = DateFormatter()
        out.dateFormat = "LLLL yyyy"
        out.timeZone = .gmt
        return out.string(from: d)
    }
}

// MARK: - Error Handling

/// Errors that can occur when interacting with the UK Police API
enum PoliceAPIError: Error {
    /// The requested month has no available crime data (404 response)
    case noDataForMonth
    
    /// HTTP error occurred with the given status code
    case http(Int)
    
    /// Response body could not be parsed as expected format
    /// Contains a snippet of the response body for debugging
    case badBody(String)
}

/// Helper structure for parsing API error responses
struct PoliceErrorMessage: Decodable { 
    let error: String 
}
