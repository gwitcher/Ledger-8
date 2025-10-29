//
//  BackupOperationsViewModel.swift
//  Ledger 8
//
//  Created by MVVM Refactoring on 10/28/25.
//

import Foundation
import SwiftUI

@Observable
@MainActor
class BackupOperationsViewModel {
    
    // MARK: - UI State
    var isBackingUp = false
    var isRestoring = false
    var isValidating = false
    var progress: Double = 0.0
    var statusMessage = ""
    var errorMessage: String?
    
    // MARK: - Operation Results
    var lastCreatedBackupURL: URL?
    var lastIntegrityCheck: BackupIntegrityResult?
    var showingBackupComplete = false
    var showingRestoreComplete = false
    var skipChecksumValidation = false
    
    // MARK: - Private Properties
    private let backupService: BackupServiceProtocol
    private let integrityService: BackupIntegrityServiceProtocol
    
    // MARK: - Computed Properties
    var canPerformOperations: Bool {
        !isBackingUp && !isRestoring && !isValidating
    }
    
    var shouldShowProgress: Bool {
        isBackingUp || isRestoring || isValidating
    }
    
    var statusColor: Color {
        if hasError { return .red }
        if shouldShowProgress { return .blue }
        if showingBackupComplete || showingRestoreComplete { return .green }
        return .primary
    }
    
    var hasError: Bool {
        errorMessage != nil
    }
    
    var operationInProgress: String? {
        if isBackingUp { return "Creating backup..." }
        if isRestoring { return "Restoring backup..." }
        if isValidating { return "Validating backup..." }
        return nil
    }
    
    // MARK: - Initialization
    init(backupService: BackupServiceProtocol, integrityService: BackupIntegrityServiceProtocol) {
        self.backupService = backupService
        self.integrityService = integrityService
    }
    
    // MARK: - Backup Operations
    
    func createBackup() async {
        guard canPerformOperations else { return }
        
        isBackingUp = true
        progress = 0.0
        errorMessage = nil
        statusMessage = "Starting backup..."
        lastCreatedBackupURL = nil
        showingBackupComplete = false
        
        defer { 
            isBackingUp = false 
        }
        
        do {
            let fileURL = try await backupService.createCompleteBackup { [weak self] progress, message in
                Task { @MainActor in
                    self?.progress = progress
                    self?.statusMessage = message
                }
            }
            
            progress = 1.0
            statusMessage = "Backup created successfully!"
            lastCreatedBackupURL = fileURL
            showingBackupComplete = true
            
            // Clear success message after delay
            Task {
                try await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
                if !isBackingUp && !hasError {
                    statusMessage = ""
                }
            }
            
        } catch {
            errorMessage = error.localizedDescription
            statusMessage = ""
            progress = 0.0
        }
    }
    
    func restoreBackup(from fileURL: URL, replaceExisting: Bool = false) async {
        guard canPerformOperations else { return }
        
        isRestoring = true
        progress = 0.0
        errorMessage = nil
        statusMessage = "Starting restore..."
        showingRestoreComplete = false
        
        defer { 
            isRestoring = false 
        }
        
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
            showingRestoreComplete = true
            
            // Clear success message after delay
            Task {
                try await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
                if !isRestoring && !hasError {
                    statusMessage = ""
                }
            }
            
        } catch {
            errorMessage = error.localizedDescription
            statusMessage = ""
            progress = 0.0
        }
    }
    
    func validateBackup(at fileURL: URL) async {
        guard canPerformOperations else { return }
        
        isValidating = true
        errorMessage = nil
        statusMessage = "Validating backup file..."
        lastIntegrityCheck = nil
        
        defer { 
            isValidating = false 
        }
        
        do {
            let result = try await integrityService.validateBackupFile(at: fileURL)
            lastIntegrityCheck = result
            
            if result.isValid {
                statusMessage = "✅ Backup validation passed"
                if result.hasWarnings {
                    statusMessage += " (with \(result.warnings.count) warnings)"
                }
            } else {
                statusMessage = "❌ Backup validation failed"
            }
            
            // Clear status message after delay
            Task {
                try await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds
                if !isValidating && !hasError {
                    statusMessage = ""
                }
            }
            
        } catch {
            errorMessage = error.localizedDescription
            statusMessage = ""
        }
    }
    
    func emergencyRestore(from fileURL: URL, replaceExisting: Bool = false) async {
        let originalSetting = skipChecksumValidation
        skipChecksumValidation = true
        statusMessage = "⚠️ Performing emergency restore (skipping validation)"
        
        defer { 
            skipChecksumValidation = originalSetting 
        }
        
        await restoreBackup(from: fileURL, replaceExisting: replaceExisting)
    }
    
    func clearAllData() async {
        guard canPerformOperations else { return }
        
        errorMessage = nil
        statusMessage = "Clearing all data..."
        
        do {
            try await backupService.clearAllData()
            statusMessage = "All data cleared successfully"
            
            // Clear status message after delay
            Task {
                try await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
                statusMessage = ""
            }
            
        } catch {
            errorMessage = error.localizedDescription
            statusMessage = ""
        }
    }
    
    // MARK: - UI Actions
    
    func clearError() {
        errorMessage = nil
    }
    
    func resetProgress() {
        progress = 0.0
        statusMessage = ""
        showingBackupComplete = false
        showingRestoreComplete = false
    }
    
    func dismissBackupComplete() {
        showingBackupComplete = false
        statusMessage = ""
    }
    
    func dismissRestoreComplete() {
        showingRestoreComplete = false
        statusMessage = ""
    }
    
    func shareBackup() -> URL? {
        return lastCreatedBackupURL
    }
    
    // MARK: - Settings
    
    func updateChecksumValidation(_ enabled: Bool) {
        backupService.checksumValidationEnabled = enabled
    }
    
    var checksumValidationEnabled: Bool {
        get { backupService.checksumValidationEnabled }
        set { backupService.checksumValidationEnabled = newValue }
    }
}

// MARK: - Helper Extensions

extension BackupOperationsViewModel {
    
    var progressText: String {
        let percentage = Int(progress * 100)
        return "\(percentage)%"
    }
    
    var validationSummary: String? {
        guard let result = lastIntegrityCheck else { return nil }
        return result.summary
    }
    
    var validationDetails: [String] {
        guard let result = lastIntegrityCheck else { return [] }
        return result.validationResults + result.warnings
    }
    
    var canShareBackup: Bool {
        lastCreatedBackupURL != nil && !hasError
    }
    
    var shouldShowValidationResults: Bool {
        lastIntegrityCheck != nil
    }
}