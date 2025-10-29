//
//  AutoBackupSettingsViewModel.swift
//  Ledger 8
//
//  Created by Refactoring Assistant
//

import Foundation
import SwiftUI
import Combine
@testable import Ledger_8

@Observable
@MainActor
class AutoBackupSettingsViewModel {
    // MARK: - Published Properties
    var autoBackupEnabled: Bool = false
    var autoBackupFrequency: AutoBackupFrequency = .daily
    var maxBackupsToKeep: Double = 10.0
    var showingBackupsList: Bool = false
    var showingDiagnostics: Bool = false
    
    // MARK: - Computed Properties
    var shouldShowFrequencyPicker: Bool {
        autoBackupEnabled
    }
    
    var maxBackupsDisplayText: String {
        "Keep \(Int(maxBackupsToKeep)) auto-backups"
    }
    
    var lastAutoBackupDate: Date? {
        backupManager.lastAutoBackupDate
    }
    
    var footerText: String {
        if autoBackupEnabled {
            return "Auto-backups will be created \(autoBackupFrequency.displayName.lowercased()) when you close the app."
        } else {
            return "Auto-backup is disabled. You can still create manual backups."
        }
    }
    
    // MARK: - Private Properties
    private let backupManager: ComprehensiveBackupManager
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init(backupManager: ComprehensiveBackupManager) {
        self.backupManager = backupManager
        loadSettings()
    }
    
    // MARK: - Public Methods
    func getFrequencyOptions() -> [AutoBackupFrequency] {
        return AutoBackupFrequency.allCases
    }
    
    func saveSettings() {
        backupManager.updateAutoBackupSettings(
            enabled: autoBackupEnabled, 
            frequency: autoBackupFrequency, 
            maxBackups: Int(maxBackupsToKeep)
        )
    }
    
    func showBackupsList() {
        showingBackupsList = true
    }
    
    func showDiagnostics() {
        showingDiagnostics = true
    }
    
    // MARK: - Private Methods
    private func loadSettings() {
        autoBackupEnabled = backupManager.autoBackupEnabled
        autoBackupFrequency = backupManager.autoBackupFrequency
        maxBackupsToKeep = Double(backupManager.maxBackupsToKeep)
    }
}

