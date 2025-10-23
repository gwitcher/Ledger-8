//
//  InvoiceLogger.swift
//  Ledger 8
//
//  Created by Enterprise Enhancement System
//

import Foundation
import os.log

/// Centralized logging system for invoice operations
/// Provides structured logging with appropriate log levels and categories
final class InvoiceLogger {
    
    // MARK: - Log Categories
    
    static let pdfGeneration = Logger(subsystem: "com.ledger8.invoice", category: "PDFGeneration")
    static let fileOperations = Logger(subsystem: "com.ledger8.invoice", category: "FileOperations")
    static let dataValidation = Logger(subsystem: "com.ledger8.invoice", category: "DataValidation")
    static let userInteraction = Logger(subsystem: "com.ledger8.invoice", category: "UserInteraction")
    static let performance = Logger(subsystem: "com.ledger8.invoice", category: "Performance")
    static let security = Logger(subsystem: "com.ledger8.invoice", category: "Security")
    
    // MARK: - Convenience Methods
    
    /// Logs PDF generation events
    static func logPDFGeneration(_ level: OSLogType, _ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        let location = "\(URL(fileURLWithPath: file).lastPathComponent):\(function):\(line)"
        pdfGeneration.log(level: level, "[\(location)] \(message)")
    }
    
    /// Logs file operation events
    static func logFileOperation(_ level: OSLogType, _ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        let location = "\(URL(fileURLWithPath: file).lastPathComponent):\(function):\(line)"
        fileOperations.log(level: level, "[\(location)] \(message)")
    }
    
    /// Logs data validation events
    static func logDataValidation(_ level: OSLogType, _ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        let location = "\(URL(fileURLWithPath: file).lastPathComponent):\(function):\(line)"
        dataValidation.log(level: level, "[\(location)] \(message)")
    }
    
    /// Logs user interaction events
    static func logUserInteraction(_ level: OSLogType, _ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        let location = "\(URL(fileURLWithPath: file).lastPathComponent):\(function):\(line)"
        userInteraction.log(level: level, "[\(location)] \(message)")
    }
    
    /// Logs performance-related events
    static func logPerformance(_ level: OSLogType, _ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        let location = "\(URL(fileURLWithPath: file).lastPathComponent):\(function):\(line)"
        performance.log(level: level, "[\(location)] \(message)")
    }
    
    /// Logs security-related events
    static func logSecurity(_ level: OSLogType, _ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        let location = "\(URL(fileURLWithPath: file).lastPathComponent):\(function):\(line)"
        security.log(level: level, "[\(location)] \(message)")
    }
    
    // MARK: - Performance Timing
    
    /// Measures execution time of operations
    static func measureTime<T>(
        operation: String,
        category: Logger = performance,
        execute: () throws -> T
    ) rethrows -> T {
        let startTime = CFAbsoluteTimeGetCurrent()
        defer {
            let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
            category.info("⏱️ \(operation) completed in \(String(format: "%.3f", timeElapsed))s")
        }
        return try execute()
    }
    
    /// Measures execution time of async operations
    static func measureTimeAsync<T>(
        operation: String,
        category: Logger = performance,
        execute: () async throws -> T
    ) async rethrows -> T {
        let startTime = CFAbsoluteTimeGetCurrent()
        defer {
            let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
            category.info("⏱️ \(operation) completed in \(String(format: "%.3f", timeElapsed))s")
        }
        return try await execute()
    }
}

// MARK: - Error Logging Extensions

extension Error {
    /// Logs an error with context information
    func logError(to logger: Logger, context: String, file: String = #file, function: String = #function, line: Int = #line) {
        let location = "\(URL(fileURLWithPath: file).lastPathComponent):\(function):\(line)"
        logger.error("❌ [\(location)] \(context): \(self.localizedDescription)")
    }
    
    /// Logs an error with context to the appropriate invoice logger
    func logInvoiceError(category: Logger, context: String, file: String = #file, function: String = #function, line: Int = #line) {
        let location = "\(URL(fileURLWithPath: file).lastPathComponent):\(function):\(line)"
        category.error("❌ [\(location)] \(context): \(self.localizedDescription)")
    }
}

// MARK: - Success Logging Helpers

extension InvoiceLogger {
    /// Logs successful operations
    static func logSuccess(_ message: String, category: Logger, file: String = #file, function: String = #function, line: Int = #line) {
        let location = "\(URL(fileURLWithPath: file).lastPathComponent):\(function):\(line)"
        category.info("✅ [\(location)] \(message)")
    }
    
    /// Logs warning conditions
    static func logWarning(_ message: String, category: Logger, file: String = #file, function: String = #function, line: Int = #line) {
        let location = "\(URL(fileURLWithPath: file).lastPathComponent):\(function):\(line)"
        category.notice("⚠️ [\(location)] \(message)")
    }
}