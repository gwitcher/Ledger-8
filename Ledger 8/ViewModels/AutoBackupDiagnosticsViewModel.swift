//
//  AutoBackupDiagnosticsViewModel.swift
//  Ledger 8
//
//  Created by Gabe Witcher on 10/28/25.
//

import Foundation
import SwiftUI

@Observable
@MainActor
class AutoBackupDiagnosticsViewModel {
    
    // MARK: - UI State
    var diagnostics: AutoBackupDiagnostics?
    var isRefreshing = false
    var showingRestartConfirmation = false
    
    // MARK: - Private Properties
    private let backupManager: ComprehensiveBackupManager
    
    // MARK: - Computed Properties
    var isLoaded: Bool {
        diagnostics != nil
    }
    
    var hasIssues: Bool {
        diagnostics?.issues.isEmpty == false
    }
    
    var hasWarnings: Bool {
        diagnostics?.warnings.isEmpty == false
    }
    
    var canTriggerBackup: Bool {
        backupManager.autoBackupEnabled && !isRefreshing
    }
    
    var statusInfo: (icon: String, color: Color, displayName: String, summary: String, lastValidated: Date)? {
        guard let diagnostics = diagnostics else { return nil }
        return (
            icon: diagnostics.status.icon,
            color: diagnostics.status.color,
            displayName: diagnostics.status.displayName,
            summary: diagnostics.summary,
            lastValidated: diagnostics.lastValidated
        )
    }
    
    var issues: [String] {
        diagnostics?.issues ?? []
    }
    
    var warnings: [String] {
        diagnostics?.warnings ?? []
    }
    
    var systemInfo: [String] {
        diagnostics?.info ?? []
    }
    
    // MARK: - Initialization
    init(backupManager: ComprehensiveBackupManager) {
        self.backupManager = backupManager
    }
    
    // MARK: - Business Logic Methods
    
    func loadDiagnostics() {
        refreshDiagnostics()
    }
    
    func refreshDiagnostics() {
        isRefreshing = true
        
        // Add small delay to show refresh indicator and ensure UI updates properly
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            
            self.diagnostics = backupManager.validateAutoBackupSystem()
            self.isRefreshing = false
        }
    }
    
    // MARK: - UI Actions
    
    func showRestartConfirmation() {
        showingRestartConfirmation = true
    }
    
    func hideRestartConfirmation() {
        showingRestartConfirmation = false
    }
    
    func restartBackupSystem() {
        Task { @MainActor in
            backupManager.restartAutoBackupSystem()
            refreshDiagnostics()
        }
        hideRestartConfirmation()
    }
    
    func triggerManualBackup() {
        guard canTriggerBackup else { return }
        
        Task { @MainActor in
            await backupManager.performAutoBackupIfNeeded(trigger: .dataChange)
            refreshDiagnostics()
        }
    }
    
    // MARK: - Helper Methods
    
    func getIssueIcon() -> String {
        "xmark.circle.fill"
    }
    
    func getWarningIcon() -> String {
        "exclamationmark.triangle.fill"
    }
    
    func getInfoIcon() -> String {
        "info.circle"
    }
    
    func getRestartActionIcon() -> String {
        "arrow.clockwise"
    }
    
    func getTriggerBackupActionIcon() -> String {
        "play.circle"
    }
    
    func getViewHistoryActionIcon() -> String {
        "doc.on.doc"
    }
    
    var restartConfirmationTitle: String {
        "Restart Auto-Backup System"
    }
    
    var restartConfirmationMessage: String {
        "This will restart the auto-backup system and may resolve timer or configuration issues."
    }
    
    var diagnosticActionsFooter: String {
        "Use these actions to troubleshoot and test the auto-backup system. Restart the system if timers appear stuck."
    }
    
    // MARK: - Section Display Logic
    
    func shouldShowIssuesSection() -> Bool {
        hasIssues
    }
    
    func shouldShowWarningsSection() -> Bool {
        hasWarnings
    }
    
    func shouldShowSystemInfoSection() -> Bool {
        !systemInfo.isEmpty
    }
    
    // MARK: - Formatted Display Text
    
    func lastCheckedText() -> String {
        guard let diagnostics = diagnostics else { return "Not checked" }
        return "Last checked: \(diagnostics.lastValidated.formatted(date: .omitted, time: .shortened))"
    }
    
    func systemStatusText() -> String {
        guard let status = statusInfo else { return "Unknown" }
        return "System Status: \(status.displayName)"
    }
}

// MARK: - Extensions for UI Color and Icon Mapping
private extension AutoBackupDiagnosticsViewModel {
    
    // Helper methods for consistent styling across the app
    var issueColor: Color { .red }
    var warningColor: Color { .orange }
    var infoColor: Color { .blue }
    var restartActionColor: Color { .blue }
    var triggerBackupActionColor: Color { .green }
    var viewHistoryActionColor: Color { .purple }
}

// MARK: - Public Computed Properties for Colors
extension AutoBackupDiagnosticsViewModel {
    
    var issuesHeaderColor: Color { issueColor }
    var warningsHeaderColor: Color { warningColor }
    var restartButtonColor: Color { restartActionColor }
    var triggerBackupButtonColor: Color { triggerBackupActionColor }
    var viewHistoryButtonColor: Color { viewHistoryActionColor }
}