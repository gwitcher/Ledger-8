//
//  AutoBackupListViewModel.swift
//  Ledger 8
//
//  Created by Gabe Witcher on 10/28/25.
//

import Foundation
import SwiftUI

@Observable
class AutoBackupListViewModel {
    // MARK: - UI State
    var backupFiles: [AutoBackupInfo] = []
    var showingShareSheet = false
    var selectedBackup: AutoBackupInfo?
    var isLoading = false
    
    // MARK: - Private Properties
    private let backupManager: ComprehensiveBackupManager
    
    // MARK: - Computed Properties
    var hasBackupFiles: Bool {
        !backupFiles.isEmpty
    }
    
    var contentUnavailableTitle: String {
        "No Auto-Backups Found"
    }
    
    var contentUnavailableSystemImage: String {
        "clock.arrow.circlepath"
    }
    
    var contentUnavailableDescription: String {
        "Auto-backups will appear here when they are created"
    }
    
    // MARK: - Initialization
    init(backupManager: ComprehensiveBackupManager) {
        self.backupManager = backupManager
    }
    
    // MARK: - Business Logic Methods
    
    func loadBackupFiles() {
        isLoading = true
        
        // Simulate async loading if needed, or make it actually async
        DispatchQueue.main.async { [weak self] in
            self?.backupFiles = self?.backupManager.getAutoBackupFiles() ?? []
            self?.isLoading = false
        }
    }
    
    func refreshBackupFiles() async {
        await MainActor.run {
            isLoading = true
        }
        
        // Perform refresh logic
        let files = backupManager.getAutoBackupFiles()
        
        await MainActor.run {
            self.backupFiles = files
            self.isLoading = false
        }
    }
    
    // MARK: - UI Actions
    
    func shareBackup(_ backup: AutoBackupInfo) {
        selectedBackup = backup
        showingShareSheet = true
    }
    
    func dismissShareSheet() {
        showingShareSheet = false
        selectedBackup = nil
    }
    
    // MARK: - Helper Methods
    
    func getShareItems() -> [Any] {
        guard let backup = selectedBackup else { return [] }
        return [backup.url]
    }
    
    // MARK: - Formatting Methods
    
    func formatBackupTitle(_ backup: AutoBackupInfo) -> String {
        return "Auto-Backup"
    }
    
    func formatBackupDate(_ backup: AutoBackupInfo) -> String {
        return backup.formattedDate
    }
    
    func formatBackupFileSize(_ backup: AutoBackupInfo) -> String {
        return backup.formattedFileSize
    }
}