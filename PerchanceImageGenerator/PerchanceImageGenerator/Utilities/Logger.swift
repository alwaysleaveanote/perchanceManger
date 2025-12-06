//
//  Logger.swift
//  PerchanceImageGenerator
//
//  A centralized logging utility providing consistent, configurable logging
//  throughout the application with support for different log levels and categories.
//

import Foundation
import os.log

// MARK: - Log Level

/// Defines the severity level of log messages
enum LogLevel: Int, Comparable, CustomStringConvertible {
    case debug = 0
    case info = 1
    case warning = 2
    case error = 3
    
    var description: String {
        switch self {
        case .debug: return "DEBUG"
        case .info: return "INFO"
        case .warning: return "WARNING"
        case .error: return "ERROR"
        }
    }
    
    var emoji: String {
        switch self {
        case .debug: return "🔍"
        case .info: return "ℹ️"
        case .warning: return "⚠️"
        case .error: return "❌"
        }
    }
    
    static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

// MARK: - Log Category

/// Categories for organizing log messages by feature area
enum LogCategory: String {
    case app = "App"
    case theme = "Theme"
    case preset = "Preset"
    case character = "Character"
    case prompt = "Prompt"
    case navigation = "Navigation"
    case ui = "UI"
    case data = "Data"
    case network = "Network"
    
    var osLog: OSLog {
        OSLog(subsystem: Logger.subsystem, category: rawValue)
    }
}

// MARK: - Logger

/// Centralized logging utility for the application
///
/// Usage:
/// ```swift
/// Logger.debug("Loading theme", category: .theme)
/// Logger.info("User selected character: \(name)", category: .character)
/// Logger.warning("Theme file not found", category: .theme)
/// Logger.error("Failed to save data: \(error)", category: .data)
/// ```
enum Logger {
    
    // MARK: - Configuration
    
    /// The app's bundle identifier used as the logging subsystem
    static let subsystem = Bundle.main.bundleIdentifier ?? "com.perchance.imagegenerator"
    
    /// Minimum log level to output (messages below this level are ignored)
    /// Set to .debug for development, .info or .warning for production
    #if DEBUG
    static var minimumLevel: LogLevel = .debug
    #else
    static var minimumLevel: LogLevel = .info
    #endif
    
    /// Whether to include timestamps in console output
    static var includeTimestamp: Bool = true
    
    /// Whether to include file/line information in console output
    static var includeLocation: Bool = true
    
    // MARK: - Private Properties
    
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()
    
    // MARK: - Public Logging Methods
    
    /// Log a debug message (for detailed development information)
    /// - Parameters:
    ///   - message: The message to log
    ///   - category: The category for this log message
    ///   - file: The source file (auto-populated)
    ///   - function: The function name (auto-populated)
    ///   - line: The line number (auto-populated)
    static func debug(
        _ message: @autoclosure () -> String,
        category: LogCategory = .app,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(level: .debug, message: message(), category: category, file: file, function: function, line: line)
    }
    
    /// Log an info message (for general operational information)
    /// - Parameters:
    ///   - message: The message to log
    ///   - category: The category for this log message
    ///   - file: The source file (auto-populated)
    ///   - function: The function name (auto-populated)
    ///   - line: The line number (auto-populated)
    static func info(
        _ message: @autoclosure () -> String,
        category: LogCategory = .app,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(level: .info, message: message(), category: category, file: file, function: function, line: line)
    }
    
    /// Log a warning message (for potentially problematic situations)
    /// - Parameters:
    ///   - message: The message to log
    ///   - category: The category for this log message
    ///   - file: The source file (auto-populated)
    ///   - function: The function name (auto-populated)
    ///   - line: The line number (auto-populated)
    static func warning(
        _ message: @autoclosure () -> String,
        category: LogCategory = .app,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(level: .warning, message: message(), category: category, file: file, function: function, line: line)
    }
    
    /// Log an error message (for error conditions)
    /// - Parameters:
    ///   - message: The message to log
    ///   - category: The category for this log message
    ///   - file: The source file (auto-populated)
    ///   - function: The function name (auto-populated)
    ///   - line: The line number (auto-populated)
    static func error(
        _ message: @autoclosure () -> String,
        category: LogCategory = .app,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(level: .error, message: message(), category: category, file: file, function: function, line: line)
    }
    
    // MARK: - Private Implementation
    
    private static func log(
        level: LogLevel,
        message: String,
        category: LogCategory,
        file: String,
        function: String,
        line: Int
    ) {
        // Skip if below minimum level
        guard level >= minimumLevel else { return }
        
        // Build the log message
        var components: [String] = []
        
        if includeTimestamp {
            components.append(dateFormatter.string(from: Date()))
        }
        
        components.append("[\(category.rawValue)]")
        components.append(level.emoji)
        
        if includeLocation {
            let fileName = (file as NSString).lastPathComponent
            components.append("[\(fileName):\(line)]")
        }
        
        components.append(message)
        
        let fullMessage = components.joined(separator: " ")
        
        // Output to console
        print(fullMessage)
        
        // Also log to unified logging system for Console.app
        let osLogType: OSLogType
        switch level {
        case .debug: osLogType = .debug
        case .info: osLogType = .info
        case .warning: osLogType = .default
        case .error: osLogType = .error
        }
        
        os_log("%{public}@", log: category.osLog, type: osLogType, message)
    }
}

// MARK: - Convenience Extensions

extension Logger {
    
    /// Log the entry into a function (useful for tracing execution flow)
    /// - Parameters:
    ///   - category: The category for this log message
    ///   - file: The source file (auto-populated)
    ///   - function: The function name (auto-populated)
    ///   - line: The line number (auto-populated)
    static func trace(
        category: LogCategory = .app,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        debug("→ \(function)", category: category, file: file, function: function, line: line)
    }
    
    /// Log a value for debugging purposes
    /// - Parameters:
    ///   - label: A label describing the value
    ///   - value: The value to log
    ///   - category: The category for this log message
    ///   - file: The source file (auto-populated)
    ///   - function: The function name (auto-populated)
    ///   - line: The line number (auto-populated)
    static func value<T>(
        _ label: String,
        _ value: T,
        category: LogCategory = .app,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        debug("\(label) = \(value)", category: category, file: file, function: function, line: line)
    }
}
