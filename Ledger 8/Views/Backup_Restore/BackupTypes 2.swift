//
//  BackupTypes.swift
//  Ledger 8
//
//  Created by MVVM Refactoring on 10/28/25.
//

import Foundation
import SwiftUI

// MARK: - Auto Backup Frequency

enum AutoBackupFrequency: Int, CaseIterable {
    case never = 0
    case hourly = 1
    case daily = 2
    case weekly = 3
    case monthly = 4
    
    var displayName: String {
        switch self {
        case .never: return "Never"
        case .hourly: return "Every Hour"
        case .daily: return "Daily"
        case .weekly: return "Weekly"  
        case .monthly: return "Monthly"
        }
    }
    
    var timeInterval: TimeInterval {
        switch self {
        case .never: return 0
        case .hourly: return 3600 // 1 hour
        case .daily: return 86400 // 24 hours
        case .weekly: return 604800 // 7 days
        case .monthly: return 2592000 // 30 days
        }
    }
}

// MARK: - Auto Backup Trigger

enum AutoBackupTrigger {
    case timer
    case appBackground
    case appTerminating
    case dataChange
    case manual
    
    var description: String {
        switch self {
        case .timer: return "scheduled timer"
        case .appBackground: return "app background"
        case .appTerminating: return "app terminating"
        case .dataChange: return "data change"
        case .manual: return "manual trigger"
        }
    }
}

// MARK: - Backup Info Structures

struct AutoBackupInfo {
    let url: URL
    let fileName: String
    let creationDate: Date
    let fileSize: Int64
    
    var formattedFileSize: String {
        ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: creationDate)
    }
    
    var relativeDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: creationDate, relativeTo: Date())
    }
}

// MARK: - System Diagnostics

enum AutoBackupSystemStatus {
    case healthy
    case warning
    case error
}

struct AutoBackupDiagnostics {
    let status: AutoBackupSystemStatus
    let issues: [String]
    let warnings: [String]
    let info: [String]
    let lastValidated: Date
    
    var summary: String {
        switch status {
        case .healthy:
            return "System is healthy"
        case .warning:
            return "System has \(warnings.count) warning(s)"
        case .error:
            return "System has \(issues.count) error(s)"
        }
    }
}

// MARK: - Checksum Validation

enum ChecksumValidationResult {
    case valid(String)
    case mismatch(expected: String, calculated: String)
    case noChecksumStored
}

struct BackupIntegrityResult {
    let isValid: Bool
    let hasWarnings: Bool
    let validationResults: [String]
    let warnings: [String]
    let checksumResult: ChecksumValidationResult
    
    var summary: String {
        if isValid {
            if hasWarnings {
                return "✅ Valid (with \(warnings.count) warnings)"
            } else {
                return "✅ Valid"
            }
        } else {
            return "❌ Invalid (\(validationResults.filter { $0.contains("❌") }.count) errors)"
        }
    }
}

// MARK: - Backup Errors

enum BackupError: LocalizedError {
    case serviceNotAvailable(String)
    case invalidBackupFile(String)
    case corruptedBackup(String)
    case fileAccessDenied
    case operationInProgress
    case insufficientStorage
    
    var errorDescription: String? {
        switch self {
        case .serviceNotAvailable(let message):
            return "Backup service unavailable: \(message)"
        case .invalidBackupFile(let message):
            return "Invalid backup file: \(message)"
        case .corruptedBackup(let message):
            return "Corrupted backup: \(message)"
        case .fileAccessDenied:
            return "File access denied"
        case .operationInProgress:
            return "Another backup operation is in progress"
        case .insufficientStorage:
            return "Insufficient storage space"
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let autoBackupCompleted = Notification.Name("autoBackupCompleted")
    static let autoBackupFailed = Notification.Name("autoBackupFailed")
    static let autoBackupSystemRestarted = Notification.Name("autoBackupSystemRestarted")
}

// MARK: - Backup File Header (Existing from legacy code)

struct BackupFileHeader {
    static let magicBytes: [UInt8] = [0x4C, 0x38, 0x42, 0x4B] // "L8BK"
    static let currentVersion: UInt16 = 1
    static let headerLength = 8 // 4 bytes magic + 2 bytes version + 2 bytes reserved
    
    static func isValidBackupFile(_ data: Data) -> Bool {
        guard data.count >= headerLength else { return false }
        let headerMagic = Array(data.prefix(4))
        return headerMagic == magicBytes
    }
    
    static func createBackupFileData(jsonData: Data) -> Data {
        var fileData = Data()
        
        // Add magic bytes
        fileData.append(contentsOf: magicBytes)
        
        // Add version (little endian)
        withUnsafeBytes(of: currentVersion.littleEndian) { bytes in
            fileData.append(contentsOf: bytes)
        }
        
        // Add reserved bytes
        fileData.append(contentsOf: [0x00, 0x00])
        
        // Add JSON data
        fileData.append(jsonData)
        
        return fileData
    }
    
    static func extractJSONData(from data: Data) -> (jsonData: Data, hasHeader: Bool) {
        if isValidBackupFile(data) {
            let jsonData = data.dropFirst(headerLength)
            return (Data(jsonData), true)
        } else {
            return (data, false)
        }
    }
}