//
//  PoliceAPI.swift
//  CrimeNearMe
//
//  Updated: robust month fallback + multi-month fetch
//

import Foundation

final class PoliceAPI {
    static let shared = PoliceAPI()
    private let base = URL(string: "https://data.police.uk/api")!

    // MARK: - Public APIs

    /// Fetch crimes for a given month. If `poly` is provided, it is used instead of lat/lng.
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

    
    /// Fetch crimes across multiple polygons and multiple months, merged together (no dedup).
    /// Always includes the previous `monthsBack` months including the current month.
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
    // MARK: - Formatting

    /// yyyy-MM for API
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

// MARK: - Errors & helpers

enum PoliceAPIError: Error {
    case noDataForMonth
    case http(Int)
    case badBody(String) // keep a short snippet for logs
}

struct PoliceErrorMessage: Decodable { let error: String }
