//
//  BackupListViewModel.swift
//  Ledger 8
//
//  Created by Gabe Witcher on 10/28/25.
//

import Foundation
import SwiftUI

@Observable
@MainActor
class BackupListViewModel {
    // MARK: - UI State
    var autoBackups: [AutoBackupInfo] = []
    var manualBackups: [BackupFileInfo] = []
    var isLoading = false
    var errorMessage: String?
    var selectedBackup: BackupFileInfo?
    var showingDeleteConfirmation = false
    var showingBackupDetails = false
    var searchText = ""
    
    // MARK: - Private Properties
    private let backupFileService: BackupFileServiceProtocol
    private let autoBackupService: AutoBackupServiceProtocol
    
    // MARK: - Initialization
    init(backupFileService: BackupFileServiceProtocol, autoBackupService: AutoBackupServiceProtocol) {
        self.backupFileService = backupFileService
        self.autoBackupService = autoBackupService
        
        Task {
            await loadBackups()
        }
    }
    
    // MARK: - Data Loading
    
    func loadBackups() async {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        do {
            // Load auto backups
            autoBackups = autoBackupService.getAutoBackupFiles()
            
            // Load manual backups
            manualBackups = try await backupFileService.getManualBackupFiles()
            
        } catch {
            errorMessage = "Failed to load backups: \(error.localizedDescription)"
        }
    }
    
    func refreshBackups() async {
        await loadBackups()
    }
    
    // MARK: - Backup Management
    
    func deleteBackup(_ backup: BackupFileInfo) async {
        do {
            try await backupFileService.deleteBackup(at: backup.url)
            await loadBackups() // Refresh the list
            
        } catch {
            errorMessage = "Failed to delete backup: \(error.localizedDescription)"
        }
    }
    
    func deleteAutoBackup(_ backup: AutoBackupInfo) async {
        do {
            try await backupFileService.deleteBackup(at: backup.url)
            await loadBackups() // Refresh the list
            
        } catch {
            errorMessage = "Failed to delete auto backup: \(error.localizedDescription)"
        }
    }
    
    func shareBackup(_ backup: BackupFileInfo) -> URL {
        return backup.url
    }
    
    func getBackupDetails(_ backup: BackupFileInfo) async -> BackupDetailsInfo? {
        do {
            return try await backupFileService.getBackupDetails(at: backup.url)
        } catch {
            errorMessage = "Failed to read backup details: \(error.localizedDescription)"
            return nil
        }
    }
    
    // MARK: - UI Actions
    
    func selectBackup(_ backup: BackupFileInfo) {
        selectedBackup = backup
        showingBackupDetails = true
    }
    
    func showDeleteConfirmation(for backup: BackupFileInfo) {
        selectedBackup = backup
        showingDeleteConfirmation = true
    }
    
    func dismissDeleteConfirmation() {
        showingDeleteConfirmation = false
        selectedBackup = nil
    }
    
    func dismissBackupDetails() {
        showingBackupDetails = false
        selectedBackup = nil
    }
    
    func clearError() {
        errorMessage = nil
    }
    
    // MARK: - Computed Properties
    
    var filteredAutoBackups: [AutoBackupInfo] {
        if searchText.isEmpty {
            return autoBackups
        }
        return autoBackups.filter { backup in
            backup.fileName.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var filteredManualBackups: [BackupFileInfo] {
        if searchText.isEmpty {
            return manualBackups
        }
        return manualBackups.filter { backup in
            backup.fileName.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var hasBackups: Bool {
        !autoBackups.isEmpty || !manualBackups.isEmpty
    }
    
    var totalBackupsCount: Int {
        autoBackups.count + manualBackups.count
    }
    
    var hasError: Bool {
        errorMessage != nil
    }
    
    var autoBackupsSize: String {
        let totalBytes = autoBackups.reduce(0) { $0 + $1.fileSize }
        return ByteCountFormatter.string(fromByteCount: totalBytes, countStyle: .file)
    }
    
    var manualBackupsSize: String {
        let totalBytes = manualBackups.reduce(0) { $0 + $1.fileSize }
        return ByteCountFormatter.string(fromByteCount: totalBytes, countStyle: .file)
    }
    
    // MARK: - Section Headers
    
    var autoBackupsSectionHeader: String {
        let count = filteredAutoBackups.count
        return "Auto Backups (\(count))"
    }
    
    var manualBackupsSectionHeader: String {
        let count = filteredManualBackups.count
        return "Manual Backups (\(count))"
    }
}

// MARK: - Supporting Types

struct BackupFileInfo {
    let url: URL
    let fileName: String
    let creationDate: Date
    let fileSize: Int64
    let isAutoBackup: Bool
    
    var formattedFileSize: String {
        ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: creationDate)
    }
    
    var relativeDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: creationDate, relativeTo: Date())
    }
}

struct BackupDetailsInfo {
    let metadata: CompleteBackupMetadata
    let clientsCount: Int
    let projectsCount: Int
    let itemsCount: Int
    let invoicesCount: Int
    let hasIntegrityData: Bool
    
    var summary: String {
        "\(clientsCount) clients, \(projectsCount) projects, \(itemsCount) items, \(invoicesCount) invoices"
    }
}