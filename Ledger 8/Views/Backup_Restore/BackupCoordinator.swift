//
//  BackupCoordinator.swift
//  Ledger 8
//
//  Created by Gabe Witcher on 10/28/25.
//

import Foundation
import SwiftData

/// Coordinates between all backup-related services
/// This replaces the old ComprehensiveBackupManager's coordination role
@MainActor
class BackupCoordinator {
    
    // MARK: - Services
    let backupService: BackupService
    let autoBackupService: AutoBackupService
    let integrityService: BackupIntegrityService
    let fileService: BackupFileService
    
    // MARK: - Initialization
    init(modelContext: ModelContext) {
        self.integrityService = ComprehensiveBackupIntegrityService()
        self.backupService = ComprehensiveBackupService(
            modelContext: modelContext,
            integrityService: integrityService
        )
        self.autoBackupService = ComprehensiveAutoBackupService(modelContext: modelContext)
        self.fileService = ComprehensiveBackupFileService()
    }
    
    // MARK: - Convenience Methods
    
    /// Updates model context across all services
    func updateModelContext(_ context: ModelContext) {
        if let backupService = backupService as? ComprehensiveBackupService {
            backupService.updateModelContext(context)
        }
        if let autoBackupService = autoBackupService as? ComprehensiveAutoBackupService {
            autoBackupService.updateModelContext(context)
        }
    }
    
    /// Creates ViewModels with proper dependency injection
    func createBackupOperationsViewModel() -> BackupOperationsViewModel {
        return BackupOperationsViewModel(
            backupService: backupService,
            integrityService: integrityService
        )
    }
    
    func createAutoBackupSettingsViewModel() -> AutoBackupSettingsViewModel {
        return AutoBackupSettingsViewModel(autoBackupService: autoBackupService)
    }
    
    func createBackupListViewModel() -> BackupListViewModel {
        return BackupListViewModel(
            backupFileService: fileService,
            autoBackupService: autoBackupService
        )
    }
}

// MARK: - Legacy Compatibility Bridge
// This provides a bridge for existing code while you migrate to the new architecture

@MainActor
class LegacyBackupManagerBridge {
    private let coordinator: BackupCoordinator
    
    init(coordinator: BackupCoordinator) {
        self.coordinator = coordinator
    }
    
    // Legacy methods that delegate to the new services
    var autoBackupEnabled: Bool {
        coordinator.autoBackupService.autoBackupEnabled
    }
    
    var autoBackupFrequency: AutoBackupFrequency {
        coordinator.autoBackupService.autoBackupFrequency
    }
    
    var maxBackupsToKeep: Int {
        coordinator.autoBackupService.maxBackupsToKeep
    }
    
    var lastAutoBackupDate: Date? {
        coordinator.autoBackupService.lastAutoBackupDate
    }
    
    func updateAutoBackupSettings(enabled: Bool, frequency: AutoBackupFrequency, maxBackups: Int) {
        coordinator.autoBackupService.updateSettings(
            enabled: enabled,
            frequency: frequency,
            maxBackups: maxBackups
        )
    }
    
    func createCompleteBackup() async throws -> URL {
        return try await coordinator.backupService.createCompleteBackup { _, _ in
            // Legacy version doesn't report progress
        }
    }
    
    func restoreCompleteBackup(fileURL: URL, replaceExisting: Bool = false) async throws {
        try await coordinator.backupService.restoreCompleteBackup(
            fileURL: fileURL,
            replaceExisting: replaceExisting,
            skipValidation: false
        ) { _, _ in
            // Legacy version doesn't report progress
        }
    }
    
    func validateBackupFile(at fileURL: URL) async throws -> BackupIntegrityResult {
        return try await coordinator.integrityService.validateBackupFile(at: fileURL)
    }
    
    func getAutoBackupFiles() -> [AutoBackupInfo] {
        return coordinator.autoBackupService.getAutoBackupFiles()
    }
    
    func performAutoBackupIfNeeded(trigger: AutoBackupTrigger = .timer) async {
        await coordinator.autoBackupService.performAutoBackupIfNeeded(trigger: trigger)
    }
}