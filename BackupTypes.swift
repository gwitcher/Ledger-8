//
//  BackupTypes.swift
//  Ledger 8
//
//  Created by MVVM Refactoring on 10/28/25.
//

import Foundation
import SwiftUI

// MARK: - Auto Backup Types

enum AutoBackupFrequency: Int, CaseIterable, Identifiable {
    case never = 0
    case hourly = 1
    case daily = 2
    case weekly = 3
    case monthly = 4
    
    var id: Int { rawValue }
    
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

enum AutoBackupSystemStatus {
    case healthy
    case warning
    case error
    
    var icon: String {
        switch self {
        case .healthy: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .error: return "xmark.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .healthy: return .green
        case .warning: return .orange
        case .error: return .red
        }
    }
}

struct AutoBackupDiagnostics {
    let status: AutoBackupSystemStatus
    let issues: [String]
    let warnings: [String]
    let info: [String]
    let lastValidated: Date
    
    var hasIssues: Bool { !issues.isEmpty }
    var hasWarnings: Bool { !warnings.isEmpty }
    
    var summary: String {
        switch status {
        case .healthy: return "System is healthy"
        case .warning: return "\(warnings.count) warning(s)"
        case .error: return "\(issues.count) issue(s) found"
        }
    }
}

// MARK: - Backup File Types

struct BackupFileInfo {
    let url: URL
    let fileName: String
    let creationDate: Date
    let fileSize: Int64
    let isAutoBackup: Bool
    
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

struct BackupDetailsInfo {
    let metadata: CompleteBackupMetadata
    let clientsCount: Int
    let projectsCount: Int
    let itemsCount: Int
    let invoicesCount: Int
    let hasIntegrityData: Bool
    
    var summary: String {
        "\(clientsCount) clients, \(projectsCount) projects, \(itemsCount) items, \(invoicesCount) invoices"
    }
}

// MARK: - Complete Backup Types

struct CompleteBackupMetadata {
    var appVersion: String
    var backupVersion: String
    var createdDate: Date
    var deviceName: String
    var fileSize: Int?
    var contentChecksum: String?
    var checksumAlgorithm: String?
    
    init() {
        self.appVersion = "Ledger 8"
        self.backupVersion = "2.0"
        self.createdDate = Date()
        self.deviceName = ProcessInfo.processInfo.hostName
    }
}

struct CompleteLedgerBackup: Codable {
    var metadata = CompleteBackupMetadata()
    var appSettings = BackupAppSettings()
    var clients: [CompleteBackupClient] = []
    var projects: [CompleteBackupProject] = []
    var items: [CompleteBackupItem] = []
    var invoices: [CompleteBackupInvoice] = []
}

// MARK: - Error Types

enum BackupError: LocalizedError {
    case fileAccessDenied
    case corruptedBackup(String)
    case checksumValidationFailed(String)
    case incompatibleVersion
    case unsupportedBackupVersion(String)
    case invalidBackupFile(String)
    case serviceNotAvailable(String)
    case operationCancelled
    
    var errorDescription: String? {
        switch self {
        case .fileAccessDenied:
            return "Access to backup file denied"
        case .corruptedBackup(let details):
            return "Backup file is corrupted: \(details)"
        case .checksumValidationFailed(let details):
            return "Backup integrity validation failed: \(details)"
        case .incompatibleVersion:
            return "Backup was created with an incompatible version"
        case .unsupportedBackupVersion(let version):
            return "Unsupported backup version: \(version)"
        case .invalidBackupFile(let details):
            return "Invalid backup file: \(details)"
        case .serviceNotAvailable(let service):
            return "Required service not available: \(service)"
        case .operationCancelled:
            return "Operation was cancelled"
        }
    }
}

// MARK: - Legacy Compatibility Types

typealias ComprehensiveBackupError = BackupError

// MARK: - Notification Names

extension Notification.Name {
    static let autoBackupCompleted = Notification.Name("autoBackupCompleted")
    static let autoBackupFailed = Notification.Name("autoBackupFailed")
    static let autoBackupSystemRestarted = Notification.Name("autoBackupSystemRestarted")
}