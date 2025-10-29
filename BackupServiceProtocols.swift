//
//  BackupServiceProtocols.swift
//  Ledger 8
//
//  Created by MVVM Refactoring on 10/28/25.
//

import Foundation
import SwiftData

// MARK: - Backup Service Protocol

protocol BackupServiceProtocol {
    var checksumValidationEnabled: Bool { get set }
    
    func updateModelContext(_ context: ModelContext)
    
    /// Creates a complete backup with progress reporting
    func createCompleteBackup(progressHandler: @escaping (Double, String) -> Void) async throws -> URL
    
    /// Restores a complete backup with progress reporting
    func restoreCompleteBackup(
        fileURL: URL,
        replaceExisting: Bool,
        skipChecksumValidation: Bool,
        progressHandler: @escaping (Double, String) -> Void
    ) async throws
    
    /// Validates an existing backup file without restoring it
    func validateBackupFile(at fileURL: URL) async throws -> BackupIntegrityResult
    
    /// Recalculates checksum for a backup file
    func recalculateBackupChecksum(at fileURL: URL) async throws -> String
    
    /// Clear all data from the model context
    func clearAllData() async throws
}

// MARK: - Auto Backup Service Protocol

protocol AutoBackupServiceProtocol {
    var autoBackupEnabled: Bool { get }
    var autoBackupFrequency: AutoBackupFrequency { get }
    var maxBackupsToKeep: Int { get }
    var lastAutoBackupDate: Date? { get }
    
    func updateModelContext(_ context: ModelContext)
    
    /// Updates auto-backup settings
    func updateSettings(enabled: Bool, frequency: AutoBackupFrequency, maxBackups: Int)
    
    /// Performs backup if needed based on trigger
    func performBackupIfNeeded(trigger: AutoBackupTrigger) async
    
    /// Gets list of auto-backup files
    func getAutoBackupFiles() -> [AutoBackupInfo]
    
    /// Validates the auto-backup system
    func validateSystem() -> AutoBackupDiagnostics
    
    /// Restarts the auto-backup system
    func restartSystem()
    
    /// Triggers a data change backup
    func triggerDataChangeBackup()
}

// MARK: - Backup Integrity Service Protocol

protocol BackupIntegrityServiceProtocol {
    /// Validates a backup file's integrity
    func validateBackupFile(at fileURL: URL) async throws -> BackupIntegrityResult
    
    /// Calculates checksum for data
    func calculateChecksum(for data: Data) -> String
    
    /// Validates checksum against expected value
    func validateChecksum(jsonData: Data, expectedChecksum: String?) -> ChecksumValidationResult
    
    /// Comprehensive validation of backup file integrity
    func validateBackupIntegrity(fileData: Data, extractedJSON: Data, backup: CompleteLedgerBackup) -> BackupIntegrityResult
}

// MARK: - Backup File Service Protocol

protocol BackupFileServiceProtocol {
    /// Gets list of manual backup files
    func getManualBackupFiles() async throws -> [BackupFileInfo]
    
    /// Deletes a backup file
    func deleteBackup(at url: URL) async throws
    
    /// Gets detailed information about a backup file
    func getBackupDetails(at url: URL) async throws -> BackupDetailsInfo
    
    /// Organizes backup files by moving them to appropriate folders
    func organizeBackupFiles() async throws
    
    /// Calculates total size of all backup files
    func getTotalBackupSize() async throws -> Int64
    
    /// Cleans up old backup files beyond retention limits
    func cleanupOldBackups(maxToKeep: Int) async throws
}

// MARK: - Backup Coordinator Protocol

protocol BackupCoordinatorProtocol {
    var backupService: BackupServiceProtocol { get }
    var autoBackupService: AutoBackupServiceProtocol { get }
    var integrityService: BackupIntegrityServiceProtocol { get }
    var fileService: BackupFileServiceProtocol { get }
    
    func updateModelContext(_ context: ModelContext)
    
    // ViewModel creation methods
    func createBackupOperationsViewModel() -> BackupOperationsViewModel
    func createAutoBackupSettingsViewModel() -> AutoBackupSettingsViewModel
    func createBackupListViewModel() -> BackupListViewModel
}