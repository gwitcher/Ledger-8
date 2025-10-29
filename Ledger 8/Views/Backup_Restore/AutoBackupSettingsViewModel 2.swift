//
//
//  ✅ KEEP THIS FILE - AutoBackupSettingsViewModel 2.swift (MAIN VERSION)
//  ✅ COMPLETE IMPLEMENTATION: Full implementation with 321 lines
//  ❌ DELETE INSTEAD: AutoBackupSettingsViewModel.swift (incomplete 86 line version)
//
//  AutoBackupSettingsViewModel 2.swift (KEEP THIS ONE - RENAME TO MAIN)
//  Ledger 8
//
//  Created by MVVM Refactoring on 10/28/25.
//

import Foundation
import SwiftUI

@Observable
@MainActor
class AutoBackupSettingsViewModel {
    
    // MARK: - UI State
    var isPerformingManualBackup = false
    var isRestartingSystem = false
    var errorMessage: String?
    var statusMessage = ""
    var showingDiagnostics = false
    
    // MARK: - Settings State
    var diagnostics: AutoBackupDiagnostics?
    
    // MARK: - Private Properties
    private let autoBackupService: AutoBackupServiceProtocol
    
    // MARK: - Computed Properties from Service
    var autoBackupEnabled: Bool {
        get { autoBackupService.autoBackupEnabled }
        set { 
            updateSettings(
                enabled: newValue,
                frequency: autoBackupFrequency,
                maxBackups: maxBackupsToKeep
            )
        }
    }
    
    var autoBackupFrequency: AutoBackupFrequency {
        get { autoBackupService.autoBackupFrequency }
        set {
            updateSettings(
                enabled: autoBackupEnabled,
                frequency: newValue,
                maxBackups: maxBackupsToKeep
            )
        }
    }
    
    var maxBackupsToKeep: Int {
        get { autoBackupService.maxBackupsToKeep }
        set {
            updateSettings(
                enabled: autoBackupEnabled,
                frequency: autoBackupFrequency,
                maxBackups: newValue
            )
        }
    }
    
    var lastAutoBackupDate: Date? {
        autoBackupService.lastAutoBackupDate
    }
    
    // MARK: - UI State Computed Properties
    var canPerformOperations: Bool {
        !isPerformingManualBackup && !isRestartingSystem
    }
    
    var shouldShowProgress: Bool {
        isPerformingManualBackup || isRestartingSystem
    }
    
    var hasError: Bool {
        errorMessage != nil
    }
    
    var shouldShowFrequencyPicker: Bool {
        autoBackupEnabled && autoBackupFrequency != .never
    }
    
    var isAutoBackupHealthy: Bool {
        diagnostics?.status == .healthy
    }
    
    var systemStatusIcon: String {
        diagnostics?.status.icon ?? "gear"
    }
    
    var systemStatusColor: Color {
        diagnostics?.status.color ?? .primary
    }
    
    // MARK: - Initialization
    init(autoBackupService: AutoBackupServiceProtocol) {
        self.autoBackupService = autoBackupService
        
        // Load initial diagnostics
        Task {
            await refreshDiagnostics()
        }
        
        setupObservers()
    }
    
    // MARK: - Settings Management
    
    func updateSettings(enabled: Bool, frequency: AutoBackupFrequency, maxBackups: Int) {
        autoBackupService.updateSettings(
            enabled: enabled,
            frequency: frequency,
            maxBackups: maxBackups
        )
        
        // Refresh diagnostics after settings change
        Task {
            await refreshDiagnostics()
        }
    }
    
    func resetToDefaults() {
        updateSettings(enabled: true, frequency: .daily, maxBackups: 5)
        statusMessage = "Settings reset to defaults"
        
        // Clear status message after delay
        Task {
            try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            if statusMessage == "Settings reset to defaults" {
                statusMessage = ""
            }
        }
    }
    
    // MARK: - Manual Operations
    
    func performManualBackup() async {
        guard canPerformOperations else { return }
        
        isPerformingManualBackup = true
        errorMessage = nil
        statusMessage = "Performing manual backup..."
        
        defer { 
            isPerformingManualBackup = false 
        }
        
        await autoBackupService.performBackupIfNeeded(trigger: .manual)
        
        // Refresh diagnostics to get updated status
        await refreshDiagnostics()
        
        statusMessage = "Manual backup completed"
        
        // Clear status message after delay
        Task {
            try await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
            if statusMessage == "Manual backup completed" {
                statusMessage = ""
            }
        }
    }
    
    func restartSystem() {
        guard canPerformOperations else { return }
        
        isRestartingSystem = true
        errorMessage = nil
        statusMessage = "Restarting auto-backup system..."
        
        autoBackupService.restartSystem()
        
        // Refresh diagnostics after restart
        Task {
            await refreshDiagnostics()
            
            statusMessage = "Auto-backup system restarted"
            isRestartingSystem = false
            
            // Clear status message after delay
            Task {
                try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                if statusMessage == "Auto-backup system restarted" {
                    statusMessage = ""
                }
            }
        }
    }
    
    // MARK: - Diagnostics
    
    func refreshDiagnostics() async {
        diagnostics = autoBackupService.validateSystem()
    }
    
    func showDiagnostics() {
        Task {
            await refreshDiagnostics()
            showingDiagnostics = true
        }
    }
    
    func dismissDiagnostics() {
        showingDiagnostics = false
    }
    
    // MARK: - UI Actions
    
    func clearError() {
        errorMessage = nil
    }
    
    func clearStatus() {
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
            Task { @MainActor in
                await self?.refreshDiagnostics()
                self?.statusMessage = "Auto-backup completed"
                
                // Clear message after delay
                Task {
                    try await Task.sleep(nanoseconds: 3_000_000_000)
                    if self?.statusMessage == "Auto-backup completed" {
                        self?.statusMessage = ""
                    }
                }
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: .autoBackupFailed,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            Task { @MainActor in
                await self?.refreshDiagnostics()
                
                if let error = notification.userInfo?["error"] as? Error {
                    self?.errorMessage = "Auto-backup failed: \(error.localizedDescription)"
                } else {
                    self?.errorMessage = "Auto-backup failed with unknown error"
                }
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: .autoBackupSystemRestarted,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                await self?.refreshDiagnostics()
            }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Helper Extensions

extension AutoBackupSettingsViewModel {
    
    var formattedLastBackupDate: String {
        guard let date = lastAutoBackupDate else { return "Never" }
        
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    var backupFrequencyDescription: String {
        if !autoBackupEnabled { return "Disabled" }
        if autoBackupFrequency == .never { return "Never" }
        return autoBackupFrequency.displayName
    }
    
    var systemHealthSummary: String {
        diagnostics?.summary ?? "Status unknown"
    }
    
    var shouldShowHealthWarning: Bool {
        diagnostics?.status == .warning || diagnostics?.status == .error
    }
    
    var healthWarningMessage: String {
        guard let diagnostics = diagnostics else { return "" }
        
        if diagnostics.status == .error {
            return diagnostics.issues.first ?? "System has errors"
        } else if diagnostics.status == .warning {
            return diagnostics.warnings.first ?? "System has warnings"
        }
        
        return ""
    }
    
    var canTriggerManualBackup: Bool {
        autoBackupEnabled && canPerformOperations
    }
    
    var maxBackupsRange: ClosedRange<Int> {
        1...50
    }
    
    var availableFrequencies: [AutoBackupFrequency] {
        AutoBackupFrequency.allCases
    }
}