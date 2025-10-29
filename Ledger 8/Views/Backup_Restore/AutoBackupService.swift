//
//  AutoBackupService.swift
//  Ledger 8
//
//  Created by MVVM Refactoring on 10/28/25.
//

import Foundation
import SwiftData
#if canImport(UIKit)
import UIKit
#endif

/// Pure business service for auto-backup functionality - no UI concerns
@MainActor
class AutoBackupService: AutoBackupServiceProtocol {
    
    // MARK: - Properties
    private var modelContext: ModelContext
    
    // Auto-backup settings
    private(set) var autoBackupEnabled = true
    private(set) var autoBackupFrequency: AutoBackupFrequency = .daily
    private(set) var maxBackupsToKeep = 5
    private(set) var lastAutoBackupDate: Date?
    
    // Data change tracking for auto backup
    private(set) var lastDataChangeDate: Date?
    private var dataChangeDebounceTimer: Timer?
    private let dataChangeDebounceInterval: TimeInterval = 30.0 // 30 seconds
    
    private var autoBackupTimer: Timer?
    
    // MARK: - Initialization
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadSettings()
        setupAutoBackupTimer()
        setupAppLifecycleObservers()
    }
    
    func updateModelContext(_ context: ModelContext) {
        self.modelContext = context
    }
    
    // MARK: - Settings Management
    
    private func loadSettings() {
        // Only override defaults if keys exist in UserDefaults
        if UserDefaults.standard.object(forKey: "autoBackupEnabled") != nil {
            autoBackupEnabled = UserDefaults.standard.bool(forKey: "autoBackupEnabled")
        }
        
        if let frequencyRaw = UserDefaults.standard.object(forKey: "autoBackupFrequency") as? Int,
           let frequency = AutoBackupFrequency(rawValue: frequencyRaw) {
            autoBackupFrequency = frequency
        }
        
        let savedMaxBackups = UserDefaults.standard.integer(forKey: "maxBackupsToKeep")
        if savedMaxBackups > 0 { 
            maxBackupsToKeep = savedMaxBackups 
        }
        
        lastAutoBackupDate = UserDefaults.standard.object(forKey: "lastAutoBackupDate") as? Date
        lastDataChangeDate = UserDefaults.standard.object(forKey: "lastDataChangeDate") as? Date
    }
    
    private func saveSettings() {
        UserDefaults.standard.set(autoBackupEnabled, forKey: "autoBackupEnabled")
        UserDefaults.standard.set(autoBackupFrequency.rawValue, forKey: "autoBackupFrequency")
        UserDefaults.standard.set(maxBackupsToKeep, forKey: "maxBackupsToKeep")
        UserDefaults.standard.set(lastAutoBackupDate, forKey: "lastAutoBackupDate")
        UserDefaults.standard.set(lastDataChangeDate, forKey: "lastDataChangeDate")
    }
    
    func updateSettings(enabled: Bool, frequency: AutoBackupFrequency, maxBackups: Int) {
        autoBackupEnabled = enabled
        autoBackupFrequency = frequency
        maxBackupsToKeep = maxBackups
        saveSettings()
        
        // Restart timer with new settings
        setupAutoBackupTimer()
    }
    
    // MARK: - Auto-Backup Timer Management
    
    private func setupAutoBackupTimer() {
        autoBackupTimer?.invalidate()
        
        guard autoBackupEnabled && autoBackupFrequency != .never else { 
            print("Auto-backup timer disabled: enabled=\(autoBackupEnabled), frequency=\(autoBackupFrequency)")
            return 
        }
        
        let interval = autoBackupFrequency.timeInterval
        print("Setting up auto-backup timer with interval: \(interval) seconds")
        
        autoBackupTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.performBackupIfNeeded(trigger: .timer)
            }
        }
        
        // Add timer to main run loop to ensure it fires even when UI is interacting
        if let timer = autoBackupTimer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }
    
    // MARK: - App Lifecycle Observers
    
    private func setupAppLifecycleObservers() {
        #if canImport(UIKit)
        NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.performBackupIfNeeded(trigger: .appBackground)
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: UIApplication.willTerminateNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.performBackupIfNeeded(trigger: .appTerminating)
            }
        }
        
        // Also listen for significant data changes
        NotificationCenter.default.addObserver(
            forName: .NSManagedObjectContextDidSave,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.handleDataChange()
            }
        }
        #endif
    }
    
    // MARK: - Auto-Backup Execution
    
    func performBackupIfNeeded(trigger: AutoBackupTrigger) async {
        guard autoBackupEnabled else { 
            print("Auto-backup skipped: disabled in settings")
            return 
        }
        
        print("Auto-backup check triggered by: \(trigger)")
        
        // Check if backup is needed based on frequency and last backup date
        if !shouldPerformBackup(for: trigger) {
            return
        }
        
        print("Auto-backup starting...")
        
        do {
            let fileURL = try await createAutoBackup()
            lastAutoBackupDate = Date()
            saveSettings()
            
            // Clean up old backups
            await cleanupOldBackups()
            
            print("Auto-backup completed successfully: \(fileURL.lastPathComponent)")
            
            // Post notification for UI updates
            NotificationCenter.default.post(
                name: .autoBackupCompleted,
                object: self,
                userInfo: ["fileURL": fileURL, "trigger": trigger]
            )
            
        } catch {
            print("Auto-backup failed: \(error.localizedDescription)")
            
            // Post failure notification
            NotificationCenter.default.post(
                name: .autoBackupFailed,
                object: self,
                userInfo: ["error": error, "trigger": trigger]
            )
        }
    }
    
    private func shouldPerformBackup(for trigger: AutoBackupTrigger) -> Bool {
        // Always backup on app termination if enabled
        if trigger == .appTerminating {
            print("Auto-backup triggered: app terminating")
            return true
        }
        
        // Handle data change triggers with debouncing
        if trigger == .dataChange {
            guard let lastDataChange = lastDataChangeDate else {
                print("Auto-backup triggered: first data change")
                return true
            }
            
            let timeSinceDataChange = Date().timeIntervalSince(lastDataChange)
            if timeSinceDataChange < dataChangeDebounceInterval {
                print("Auto-backup skipped: data change too recent (\(Int(timeSinceDataChange))s ago)")
                return false
            }
            
            // Check if we need to backup based on frequency since last actual backup
            guard let lastBackup = lastAutoBackupDate else {
                print("Auto-backup triggered: no previous backup found")
                return true
            }
            
            let timeSinceLastBackup = Date().timeIntervalSince(lastBackup)
            let minimumInterval = min(autoBackupFrequency.timeInterval, 3600) // At least 1 hour for data changes
            let shouldBackup = timeSinceLastBackup >= minimumInterval
            
            print("Auto-backup data change check: \(Int(timeSinceLastBackup))s since last backup, minimum: \(Int(minimumInterval))s, should backup: \(shouldBackup)")
            return shouldBackup
        }
        
        // Handle timer and background triggers
        guard let lastBackup = lastAutoBackupDate else {
            print("Auto-backup triggered: never backed up before")
            return true // Never backed up before
        }
        
        let timeSinceLastBackup = Date().timeIntervalSince(lastBackup)
        let requiredInterval = autoBackupFrequency.timeInterval
        let shouldBackup = timeSinceLastBackup >= requiredInterval
        
        print("Auto-backup \(trigger) check: \(Int(timeSinceLastBackup))s since last backup, required: \(Int(requiredInterval))s, should backup: \(shouldBackup)")
        return shouldBackup
    }
    
    private func createAutoBackup() async throws -> URL {
        let backup = try await createBackupData()
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let fileName = "Ledger8_AutoBackup_\(formatter.string(from: Date())).l8backup"
        
        // Create Auto-Backups subfolder
        let documentsURL = URL.documentsDirectory
        let backupsURL = documentsURL.appendingPathComponent("Backups")
        let autoBackupsURL = backupsURL.appendingPathComponent("Auto")
        
        // Ensure the Auto-Backups directory exists
        try FileManager.default.createDirectory(at: autoBackupsURL, withIntermediateDirectories: true)
        
        let fileURL = autoBackupsURL.appendingPathComponent(fileName)
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        let data = try encoder.encode(backup)
        try data.write(to: fileURL)
        
        return fileURL
    }
    
    private func createBackupData() async throws -> CompleteLedgerBackup {
        var backup = CompleteLedgerBackup()
        
        // Backup AppStorage data
        backup.appSettings = BackupAppSettings.current()
        
        // Backup SwiftData models
        let clients = try modelContext.fetch(FetchDescriptor<Client>())
        backup.clients = clients.map { CompleteBackupClient(from: $0) }
        
        let projects = try modelContext.fetch(FetchDescriptor<Project>())
        backup.projects = projects.map { CompleteBackupProject(from: $0) }
        
        let items = try modelContext.fetch(FetchDescriptor<Item>())
        backup.items = items.map { CompleteBackupItem(from: $0) }
        
        let invoices = try modelContext.fetch(FetchDescriptor<Invoice>())
        backup.invoices = invoices.compactMap { invoice in
            // Find which project owns this invoice
            let owningProject = projects.first { $0.invoice === invoice }
            return CompleteBackupInvoice(from: invoice, project: owningProject)
        }
        
        return backup
    }
    
    // MARK: - Backup Management
    
    private func cleanupOldBackups() async {
        let documentsURL = URL.documentsDirectory
        let autoBackupsURL = documentsURL.appendingPathComponent("Backups/Auto")
        
        do {
            let files = try FileManager.default.contentsOfDirectory(at: autoBackupsURL, includingPropertiesForKeys: [.creationDateKey])
            
            // Sort by creation date, newest first
            let sortedFiles = files.compactMap { url -> (URL, Date)? in
                guard let creationDate = try? url.resourceValues(forKeys: [.creationDateKey]).creationDate else {
                    return nil
                }
                return (url, creationDate)
            }.sorted { $0.1 > $1.1 }
            
            // Remove files beyond the limit
            if sortedFiles.count > maxBackupsToKeep {
                let filesToDelete = Array(sortedFiles.dropFirst(maxBackupsToKeep))
                for (fileURL, _) in filesToDelete {
                    try? FileManager.default.removeItem(at: fileURL)
                    print("Cleaned up old auto-backup: \(fileURL.lastPathComponent)")
                }
            }
        } catch {
            print("Failed to cleanup old backups: \(error.localizedDescription)")
        }
    }
    
    func getAutoBackupFiles() -> [AutoBackupInfo] {
        let documentsURL = URL.documentsDirectory
        let autoBackupsURL = documentsURL.appendingPathComponent("Backups/Auto")
        
        do {
            let files = try FileManager.default.contentsOfDirectory(at: autoBackupsURL, includingPropertiesForKeys: [.creationDateKey, .fileSizeKey])
            
            return files.compactMap { url in
                guard let attributes = try? url.resourceValues(forKeys: [.creationDateKey, .fileSizeKey]),
                      let creationDate = attributes.creationDate,
                      let fileSize = attributes.fileSize else {
                    return nil
                }
                
                return AutoBackupInfo(
                    url: url,
                    fileName: url.lastPathComponent,
                    creationDate: creationDate,
                    fileSize: Int64(fileSize)
                )
            }.sorted { $0.creationDate > $1.creationDate }
        } catch {
            return []
        }
    }
    
    // MARK: - System Validation & Diagnostics
    
    func validateSystem() -> AutoBackupDiagnostics {
        var issues: [String] = []
        var warnings: [String] = []
        var info: [String] = []
        
        // Check basic configuration
        if !autoBackupEnabled {
            info.append("Auto-backup is disabled by user")
        } else {
            info.append("Auto-backup is enabled")
            
            if autoBackupFrequency == .never {
                issues.append("Auto-backup frequency is set to 'never' but auto-backup is enabled")
            } else {
                info.append("Backup frequency: \(autoBackupFrequency.displayName) (\(Int(autoBackupFrequency.timeInterval))s)")
            }
            
            info.append("Max backups to keep: \(maxBackupsToKeep)")
            
            // Check last backup status
            if let lastBackup = lastAutoBackupDate {
                let timeSinceLastBackup = Date().timeIntervalSince(lastBackup)
                let requiredInterval = autoBackupFrequency.timeInterval
                
                info.append("Last auto-backup: \(Int(timeSinceLastBackup))s ago")
                
                if timeSinceLastBackup > requiredInterval * 2 {
                    warnings.append("Last auto-backup was \(Int(timeSinceLastBackup))s ago, expected every \(Int(requiredInterval))s")
                }
            } else {
                warnings.append("No auto-backup has been performed yet")
            }
            
            // Check timer status
            if autoBackupTimer == nil {
                issues.append("Auto-backup timer is not running")
            } else {
                info.append("Auto-backup timer is active")
            }
            
            // Check backup directory
            let backupFiles = getAutoBackupFiles()
            info.append("Found \(backupFiles.count) auto-backup files")
            
            if backupFiles.count == 0 && lastAutoBackupDate != nil {
                warnings.append("Last backup date recorded but no backup files found")
            }
            
            // Check data change tracking
            if let lastDataChange = lastDataChangeDate {
                let timeSinceDataChange = Date().timeIntervalSince(lastDataChange)
                info.append("Last data change: \(Int(timeSinceDataChange))s ago")
            } else {
                info.append("No data changes tracked yet")
            }
        }
        
        let status: AutoBackupSystemStatus
        if !issues.isEmpty {
            status = .error
        } else if !warnings.isEmpty {
            status = .warning
        } else {
            status = .healthy
        }
        
        return AutoBackupDiagnostics(
            status: status,
            issues: issues,
            warnings: warnings,
            info: info,
            lastValidated: Date()
        )
    }
    
    /// Forces an auto-backup restart - useful for fixing stuck timers
    func restartSystem() {
        print("Restarting auto-backup system...")
        
        // Clean up existing timers
        autoBackupTimer?.invalidate()
        dataChangeDebounceTimer?.invalidate()
        
        // Reload settings
        loadSettings()
        
        // Restart system components
        setupAutoBackupTimer()
        
        print("Auto-backup system restarted")
        
        // Post notification
        NotificationCenter.default.post(
            name: .autoBackupSystemRestarted,
            object: self
        )
    }
    
    func triggerDataChangeBackup() {
        guard autoBackupEnabled else { return }
        
        lastDataChangeDate = Date()
        saveSettings()
        
        // Use debounced approach for data changes
        handleDataChange()
    }
    
    private func handleDataChange() {
        // Cancel previous debounce timer
        dataChangeDebounceTimer?.invalidate()
        
        // Set up new debounce timer
        dataChangeDebounceTimer = Timer.scheduledTimer(withTimeInterval: dataChangeDebounceInterval, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.performBackupIfNeeded(trigger: .dataChange)
            }
        }
        
        // Add to run loop
        if let timer = dataChangeDebounceTimer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }
    
    deinit {
        autoBackupTimer?.invalidate()
        dataChangeDebounceTimer?.invalidate()
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - AutoBackupTrigger Extension

enum AutoBackupTrigger {
    case timer
    case appBackground
    case appTerminating
    case dataChange
    case manual
    
    var description: String {
        switch self {
        case .timer: return "scheduled timer"
        case .appBackground: return "app background"
        case .appTerminating: return "app terminating"
        case .dataChange: return "data change"
        case .manual: return "manual trigger"
        }
    }
}