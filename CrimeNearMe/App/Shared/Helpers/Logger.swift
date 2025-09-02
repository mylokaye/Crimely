//
//  Logger.swift
//  CrimeNearMe
//
//  Centralized logging utilities for the application
//

import Foundation
import os.log

/// Centralized logging system for the CrimeNearMe application
/// 
/// This enum provides different log categories and handles debug vs release
/// builds appropriately. In debug builds, logs are printed to console.
/// In release builds, they use the unified logging system.
enum AppLogger {
    /// API-related logging (network requests, responses, errors)
    case api
    
    /// Location and geocoding related logging
    case location
    
    /// General app flow and state changes
    case app
    
    /// Error conditions and exceptions
    case error
    
    /// The underlying OSLog instance for this category
    private var osLog: OSLog {
        switch self {
        case .api:
            return OSLog(subsystem: "com.crimenerame.app", category: "API")
        case .location:
            return OSLog(subsystem: "com.crimenerame.app", category: "Location")
        case .app:
            return OSLog(subsystem: "com.crimenerame.app", category: "App")
        case .error:
            return OSLog(subsystem: "com.crimenerame.app", category: "Error")
        }
    }
    
    /// Logs a message with the specified log level
    /// - Parameters:
    ///   - message: The message to log
    ///   - type: The log type (default: .default)
    func log(_ message: String, type: OSLogType = .default) {
        #if DEBUG
        print("[\(self)] \(message)")
        #else
        os_log("%@", log: osLog, type: type, message)
        #endif
    }
    
    /// Logs an error message
    /// - Parameter message: The error message to log
    func error(_ message: String) {
        log(message, type: .error)
    }
    
    /// Logs a debug message (only in debug builds)
    /// - Parameter message: The debug message to log
    func debug(_ message: String) {
        #if DEBUG
        log(message, type: .debug)
        #endif
    }
}