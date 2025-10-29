//
//  AutoBackupSettingsViewModel.swift
//  Ledger 8
//
//  Created by Gabe Witcher on 10/28/25.
//

import Foundation
import SwiftUI

@Observable
@MainActor
class AutoBackupSettingsViewModel {
    // MARK: - UI State
    var autoBackupEnabled: Bool
    var autoBackupFrequency: AutoBackupFrequency
    var maxBackupsToKeep: Double
    var showingBackupsList = false
    var showingDiagnostics = false
    
    // MARK: - Private Properties
    private let autoBackupService: AutoBackupService
    
    // MARK: - Computed Properties
    var lastAutoBackupDate: Date? {
        autoBackupService.lastAutoBackupDate
    }
    
    var maxBackupsDisplayText: String {
        "Keep \(Int(maxBackupsToKeep)) backups"
    }
    
    // MARK: - Initialization
    init(autoBackupService: AutoBackupService) {
        self.autoBackupService = autoBackupService
        self.autoBackupEnabled = autoBackupService.autoBackupEnabled
        self.autoBackupFrequency = autoBackupService.autoBackupFrequency
        self.maxBackupsToKeep = Double(autoBackupService.maxBackupsToKeep)
    }
    
    // MARK: - Business Logic Methods
    
    func saveSettings() {
        autoBackupService.updateSettings(
            enabled: autoBackupEnabled,
            frequency: autoBackupFrequency,
            maxBackups: Int(maxBackupsToKeep)
        )
    }
    
    // MARK: - UI Actions
    
    func showBackupsList() {
        showingBackupsList = true
    }
    
    func showDiagnostics() {
        showingDiagnostics = true
    }
    
    func toggleAutoBackup() {
        autoBackupEnabled.toggle()
    }
    
    // MARK: - Validation and Helper Methods
    
    func getFrequencyOptions() -> [AutoBackupFrequency] {
        return AutoBackupFrequency.allCases.filter { $0 != .never }
    }
    
    var footerText: String {
        if autoBackupEnabled {
            return "Auto-backups are saved to Files > Ledger 8 > Backups > Auto and are triggered when you close the app or based on the frequency you select."
        } else {
            return ""
        }
    }
    
    var shouldShowFrequencyPicker: Bool {
        return autoBackupEnabled
    }
    
    var shouldShowBackupSlider: Bool {
        return autoBackupEnabled
    }
}