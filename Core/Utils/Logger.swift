//
//  Logger.swift
//  Club Ralley
//
//  Centralized logging utility that can be disabled in production builds.
//  Use Logger.debug() instead of print() for development logging.
//

import Foundation

/// Centralized logger for Club Ralley
/// In DEBUG builds, logs are printed to console
/// In RELEASE builds, logs are suppressed for performance
enum Logger {

    /// Log levels for filtering
    enum Level: String {
        case debug = "DEBUG"
        case info = "INFO"
        case warning = "WARNING"
        case error = "ERROR"
    }

    /// Whether logging is enabled (compile-time flag)
    #if DEBUG
    private static let isEnabled = true
    #else
    private static let isEnabled = false
    #endif

    /// Log a debug message (development only)
    static func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .debug, file: file, function: function, line: line)
    }

    /// Log an info message
    static func info(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .info, file: file, function: function, line: line)
    }

    /// Log a warning message
    static func warning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .warning, file: file, function: function, line: line)
    }

    /// Log an error message (always logged, even in release for crash reports)
    static func error(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        // Errors are always logged
        let filename = URL(fileURLWithPath: file).lastPathComponent
        print("[\(Level.error.rawValue)] \(filename):\(line) - \(message)")
    }

    /// Internal logging function
    private static func log(_ message: String, level: Level, file: String, function: String, line: Int) {
        guard isEnabled else { return }

        let filename = URL(fileURLWithPath: file).lastPathComponent
        let timestamp = DateFormatter.logFormatter.string(from: Date())

        switch level {
        case .debug:
            print("[\(timestamp)] \(message)")
        case .info:
            print("[INFO] \(filename) - \(message)")
        case .warning:
            print("[WARNING] \(filename):\(line) - \(message)")
        case .error:
            print("[ERROR] \(filename):\(line) - \(message)")
        }
    }
}

// MARK: - DateFormatter Extension

private extension DateFormatter {
    static let logFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()
}
