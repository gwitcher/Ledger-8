//
//  BackupOperationsViewModel.swift
//  Ledger 8
//
//  Created by Gabe Witcher on 10/28/25.
//

import Foundation
import SwiftUI

@Observable
@MainActor
class BackupOperationsViewModel {
    // MARK: - UI State
    var isBackingUp = false
    var isRestoring = false
    var progress: Double = 0.0
    var statusMessage = ""
    var errorMessage: String?
    var showingFilePicker = false
    var showingBackupComplete = false
    var showingRestoreConfirmation = false
    
    // MARK: - Backup Integrity State
    var checksumValidationEnabled = true
    var skipChecksumValidation = false
    var lastIntegrityCheck: BackupIntegrityResult?
    var showingIntegrityDetails = false
    
    // MARK: - Private Properties
    private let backupService: BackupService
    private let integrityService: BackupIntegrityService
    
    // MARK: - Initialization
    init(backupService: BackupService, integrityService: BackupIntegrityService) {
        self.backupService = backupService
        self.integrityService = integrityService
        self.checksumValidationEnabled = integrityService.isValidationEnabled
    }
    
    // MARK: - Backup Operations
    
    func createBackup() async {
        isBackingUp = true
        progress = 0.0
        errorMessage = nil
        statusMessage = "Starting backup..."
        
        defer { 
            isBackingUp = false
            if errorMessage == nil {
                showingBackupComplete = true
            }
        }
        
        do {
            let backupURL = try await backupService.createCompleteBackup { [weak self] currentProgress, message in
                Task { @MainActor in
                    self?.progress = currentProgress
                    self?.statusMessage = message
                }
            }
            
            progress = 1.0
            statusMessage = "Backup created successfully!"
            
        } catch {
            errorMessage = error.localizedDescription
            statusMessage = "Backup failed"
        }
    }
    
    func restoreBackup(from fileURL: URL, replaceExisting: Bool = false) async {
        isRestoring = true
        progress = 0.0
        errorMessage = nil
        statusMessage = "Starting restore..."
        
        defer { isRestoring = false }
        
        do {
            try await backupService.restoreCompleteBackup(
                fileURL: fileURL,
                replaceExisting: replaceExisting,
                skipValidation: skipChecksumValidation
            ) { [weak self] currentProgress, message in
                Task { @MainActor in
                    self?.progress = currentProgress
                    self?.statusMessage = message
                }
            }
            
            progress = 1.0
            statusMessage = "Restore completed successfully!"
            
        } catch {
            errorMessage = error.localizedDescription
            statusMessage = "Restore failed"
        }
    }
    
    func validateBackupFile(at fileURL: URL) async {
        statusMessage = "Validating backup file..."
        errorMessage = nil
        
        do {
            let integrityResult = try await integrityService.validateBackupFile(at: fileURL)
            lastIntegrityCheck = integrityResult
            statusMessage = integrityResult.summary
            showingIntegrityDetails = true
            
        } catch {
            errorMessage = error.localizedDescription
            statusMessage = "Validation failed"
        }
    }
    
    func emergencyRestore(from fileURL: URL, replaceExisting: Bool = false) async {
        let originalSetting = skipChecksumValidation
        skipChecksumValidation = true
        
        defer { skipChecksumValidation = originalSetting }
        
        await restoreBackup(from: fileURL, replaceExisting: replaceExisting)
    }
    
    // MARK: - UI Actions
    
    func showFilePicker() {
        showingFilePicker = true
    }
    
    func showRestoreConfirmation() {
        showingRestoreConfirmation = true
    }
    
    func dismissBackupComplete() {
        showingBackupComplete = false
    }
    
    func dismissIntegrityDetails() {
        showingIntegrityDetails = false
    }
    
    func toggleChecksumValidation() {
        checksumValidationEnabled.toggle()
        integrityService.setValidationEnabled(checksumValidationEnabled)
    }
    
    func clearError() {
        errorMessage = nil
    }
    
    // MARK: - Computed Properties
    
    var canPerformOperations: Bool {
        !isBackingUp && !isRestoring
    }
    
    var operationInProgress: Bool {
        isBackingUp || isRestoring
    }
    
    var progressDescription: String {
        if isBackingUp {
            return "Creating backup: \(Int(progress * 100))%"
        } else if isRestoring {
            return "Restoring backup: \(Int(progress * 100))%"
        } else {
            return ""
        }
    }
    
    var hasError: Bool {
        errorMessage != nil
    }
    
    var shouldShowProgress: Bool {
        operationInProgress && progress > 0
    }
}

// MARK: - Helper Extensions

extension BackupOperationsViewModel {
    
    func reset() {
        isBackingUp = false
        isRestoring = false
        progress = 0.0
        statusMessage = ""
        errorMessage = nil
        lastIntegrityCheck = nil
        showingFilePicker = false
        showingBackupComplete = false
        showingRestoreConfirmation = false
        showingIntegrityDetails = false
    }
    
    var statusColor: Color {
        if hasError {
            return .red
        } else if operationInProgress {
            return .blue
        } else if statusMessage.contains("successfully") {
            return .green
        } else {
            return .primary
        }
    }
}