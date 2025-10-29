//
//  BackupViewModel.swift
//  Ledger 8
//
//  Created by MVVM Refactoring on 10/28/25.
//

import Foundation
import SwiftUI

@Observable
@MainActor
class BackupViewModel {
    // MARK: - UI State
    var isBackingUp = false
    var isRestoring = false
    var progress: Double = 0.0
    var statusMessage = ""
    var errorMessage: String?
    
    // MARK: - Backup Operations State
    var lastIntegrityCheck: BackupIntegrityResult?
    var skipChecksumValidation = false
    
    // MARK: - Auto-backup UI State
    var showingBackupsList = false
    var showingDiagnostics = false
    var autoBackupFiles: [AutoBackupInfo] = []
    var diagnostics: AutoBackupDiagnostics?
    
    // MARK: - Private Properties
    private let backupService: BackupService
    private let autoBackupService: AutoBackupService
    
    // MARK: - Computed Properties
    var lastAutoBackupDate: Date? {
        autoBackupService.lastAutoBackupDate
    }
    
    var autoBackupEnabled: Bool {
        autoBackupService.autoBackupEnabled
    }
    
    var autoBackupFrequency: AutoBackupFrequency {
        autoBackupService.autoBackupFrequency
    }
    
    var maxBackupsToKeep: Int {
        autoBackupService.maxBackupsToKeep
    }
    
    var isAutoBackupHealthy: Bool {
        diagnostics?.status == .healthy
    }
    
    // MARK: - Initialization
    init(backupService: BackupService, autoBackupService: AutoBackupService) {
        self.backupService = backupService
        self.autoBackupService = autoBackupService
        
        setupObservers()
        refreshAutoBackupFiles()
    }
    
    // MARK: - Backup Operations
    
    func createCompleteBackup() async {
        isBackingUp = true
        progress = 0.0
        errorMessage = nil
        statusMessage = "Starting backup..."
        
        defer { isBackingUp = false }
        
        do {
            let fileURL = try await backupService.createCompleteBackup { [weak self] progress, message in
                Task { @MainActor in
                    self?.progress = progress
                    self?.statusMessage = message
                }
            }
            
            progress = 1.0
            statusMessage = "Backup created successfully!"
            
            // Refresh backup files list
            refreshAutoBackupFiles()
            
        } catch {
            errorMessage = "Failed to create backup: \(error.localizedDescription)"
            statusMessage = ""
        }
    }
    
    func restoreCompleteBackup(fileURL: URL, replaceExisting: Bool = false) async {
        isRestoring = true
        progress = 0.0
        errorMessage = nil
        statusMessage = "Starting restore..."
        
        defer { isRestoring = false }
        
        do {
            try await backupService.restoreCompleteBackup(
                fileURL: fileURL,
                replaceExisting: replaceExisting,
                skipChecksumValidation: skipChecksumValidation
            ) { [weak self] progress, message in
                Task { @MainActor in
                    self?.progress = progress
                    self?.statusMessage = message
                }
            }
            
            progress = 1.0
            statusMessage = "Restore completed successfully!"
            
        } catch {
            errorMessage = "Failed to restore backup: \(error.localizedDescription)"
            statusMessage = ""
        }
    }
    
    func validateBackupFile(at fileURL: URL) async {
        statusMessage = "Validating backup file..."
        errorMessage = nil
        
        do {
            let integrityResult = try await backupService.validateBackupFile(at: fileURL)
            lastIntegrityCheck = integrityResult
            statusMessage = integrityResult.summary
            
        } catch {
            errorMessage = "Validation failed: \(error.localizedDescription)"
            statusMessage = ""
        }
    }
    
    func emergencyRestore(fileURL: URL, replaceExisting: Bool = false) async {
        let originalSetting = skipChecksumValidation
        skipChecksumValidation = true
        
        defer { skipChecksumValidation = originalSetting }
        
        await restoreCompleteBackup(fileURL: fileURL, replaceExisting: replaceExisting)
    }
    
    // MARK: - Auto-Backup Operations
    
    func updateAutoBackupSettings(enabled: Bool, frequency: AutoBackupFrequency, maxBackups: Int) {
        autoBackupService.updateSettings(enabled: enabled, frequency: frequency, maxBackups: maxBackups)
        refreshDiagnostics()
    }
    
    func performManualAutoBackup() async {
        await autoBackupService.performBackupIfNeeded(trigger: .manual)
        refreshAutoBackupFiles()
        refreshDiagnostics()
    }
    
    func restartAutoBackupSystem() {
        autoBackupService.restartSystem()
        refreshDiagnostics()
    }
    
    // MARK: - UI Actions
    
    func showBackupsList() {
        refreshAutoBackupFiles()
        showingBackupsList = true
    }
    
    func showDiagnostics() {
        refreshDiagnostics()
        showingDiagnostics = true
    }
    
    func clearError() {
        errorMessage = nil
    }
    
    func resetProgress() {
        progress = 0.0
        statusMessage = ""
    }
    
    // MARK: - Private Methods
    
    private func setupObservers() {
        // Listen for auto-backup completion notifications
        NotificationCenter.default.addObserver(
            forName: .autoBackupCompleted,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.refreshAutoBackupFiles()
        }
        
        NotificationCenter.default.addObserver(
            forName: .autoBackupFailed,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let error = notification.userInfo?["error"] as? Error {
                self?.statusMessage = "Auto-backup failed: \(error.localizedDescription)"
            }
        }
    }
    
    private func refreshAutoBackupFiles() {
        autoBackupFiles = autoBackupService.getAutoBackupFiles()
    }
    
    private func refreshDiagnostics() {
        diagnostics = autoBackupService.validateSystem()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Helper Extensions

extension BackupViewModel {
    
    var formattedLastBackupDate: String {
        guard let date = lastAutoBackupDate else { return "Never" }
        
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    var backupStatusIcon: String {
        if isBackingUp { return "arrow.clockwise" }
        if isRestoring { return "arrow.down.circle" }
        if let diagnostics = diagnostics {
            return diagnostics.status.icon
        }
        return "folder"
    }
    
    var backupStatusColor: Color {
        if isBackingUp || isRestoring { return .blue }
        if let diagnostics = diagnostics {
            return diagnostics.status.color
        }
        return .primary
    }
}