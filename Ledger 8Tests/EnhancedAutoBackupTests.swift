//
//  EnhancedAutoBackupTests.swift
//  Ledger 8 Tests
//
//  Comprehensive tests for the enhanced auto-backup system
//

import Testing
import Foundation
import SwiftData
@testable import Ledger_8

@Suite("Enhanced Auto-Backup System Tests")
struct EnhancedAutoBackupSystemTests {
    
    init() {
        // Clean up UserDefaults before running tests to ensure clean state
        Self.cleanupTestUserDefaults()
    }
    
    private static func cleanupTestUserDefaults() {
        let keysToClean = [
            "autoBackupEnabled", "autoBackupFrequency", "maxBackupsToKeep", 
            "lastAutoBackupDate", "lastDataChangeDate", "userData", "InitialInvoiceNumber"
        ]
        keysToClean.forEach { UserDefaults.standard.removeObject(forKey: $0) }
    }
    
    @Test("Comprehensive auto-backup trigger logic")
    @MainActor
    func comprehensiveAutoBackupTriggerLogic() async throws {
        // Clean up for test isolation
        Self.cleanupTestUserDefaults()
        
        let testContainer = try createTestModelContainer()
        let backupManager = ComprehensiveBackupManager(modelContext: testContainer.mainContext)
        
        // Test 1: Never backed up before - should backup
        backupManager.lastAutoBackupDate = nil
        backupManager.autoBackupFrequency = .daily
        backupManager.autoBackupEnabled = true
        
        let shouldBackupNew = backupManager.shouldPerformAutoBackup(for: .timer)
        #expect(shouldBackupNew, "Should backup when never backed up before")
        
        // Test 2: Recent backup - should NOT backup
        backupManager.lastAutoBackupDate = Date().addingTimeInterval(-3600) // 1 hour ago
        backupManager.autoBackupFrequency = .daily // Requires 24 hours
        
        let shouldNotBackupRecent = backupManager.shouldPerformAutoBackup(for: .timer)
        #expect(!shouldNotBackupRecent, "Should not backup when recent backup exists")
        
        // Test 3: Old backup - should backup
        backupManager.lastAutoBackupDate = Date().addingTimeInterval(-25 * 3600) // 25 hours ago
        
        let shouldBackupOld = backupManager.shouldPerformAutoBackup(for: .timer)
        #expect(shouldBackupOld, "Should backup when backup is old enough")
        
        // Test 4: App termination - should ALWAYS backup
        backupManager.lastAutoBackupDate = Date().addingTimeInterval(-60) // 1 minute ago
        
        let shouldBackupTermination = backupManager.shouldPerformAutoBackup(for: .appTerminating)
        #expect(shouldBackupTermination, "Should always backup on app termination")
    }
    
    @Test("Data change debouncing")
    @MainActor
    func dataChangeDebouncing() async throws {
        // Clean up for test isolation
        Self.cleanupTestUserDefaults()
        
        let testContainer = try createTestModelContainer()
        let backupManager = ComprehensiveBackupManager(modelContext: testContainer.mainContext)
        
        // Setup
        backupManager.autoBackupEnabled = true
        backupManager.autoBackupFrequency = .hourly
        backupManager.lastAutoBackupDate = Date().addingTimeInterval(-2 * 3600) // 2 hours ago
        
        // Test 1: First data change should be allowed
        backupManager.lastDataChangeDate = nil
        
        let shouldBackupFirst = backupManager.shouldPerformAutoBackup(for: .dataChange)
        #expect(shouldBackupFirst, "First data change should trigger backup")
        
        // Test 2: Recent data change should be debounced
        backupManager.lastDataChangeDate = Date().addingTimeInterval(-10) // 10 seconds ago
        
        let shouldNotBackupRecent = backupManager.shouldPerformAutoBackup(for: .dataChange)
        #expect(!shouldNotBackupRecent, "Recent data change should be debounced")
        
        // Test 3: Old data change should be allowed
        backupManager.lastDataChangeDate = Date().addingTimeInterval(-60) // 1 minute ago
        backupManager.lastAutoBackupDate = Date().addingTimeInterval(-2 * 3600) // 2 hours ago
        
        let shouldBackupOld = backupManager.shouldPerformAutoBackup(for: .dataChange)
        #expect(shouldBackupOld, "Old data change should trigger backup")
    }
    
    @Test("Auto-backup diagnostics")
    @MainActor
    func autoBackupDiagnostics() async throws {
        // Clean up for test isolation
        Self.cleanupTestUserDefaults()
        
        let testContainer = try createTestModelContainer()
        let backupManager = ComprehensiveBackupManager(modelContext: testContainer.mainContext)
        
        // Test 1: Healthy system
        backupManager.autoBackupEnabled = true
        backupManager.autoBackupFrequency = .daily
        backupManager.lastAutoBackupDate = Date().addingTimeInterval(-3600) // 1 hour ago
        
        let healthyDiagnostics = backupManager.validateAutoBackupSystem()
        
        #expect(healthyDiagnostics.status == .healthy || healthyDiagnostics.status == .warning, 
               "System should be healthy or have minor warnings")
        #expect(!healthyDiagnostics.info.isEmpty, "Should provide system information")
        
        // Test 2: Configuration error - enabled but frequency is never
        backupManager.autoBackupEnabled = true
        backupManager.autoBackupFrequency = .never
        
        let errorDiagnostics = backupManager.validateAutoBackupSystem()
        
        #expect(errorDiagnostics.status == .error, "Should detect configuration error")
        #expect(!errorDiagnostics.issues.isEmpty, "Should report configuration issues")
        #expect(errorDiagnostics.issues.contains { $0.contains("never") }, 
               "Should specifically report the 'never' frequency issue")
        
        // Test 3: Warning - no backup performed yet but system is healthy
        backupManager.autoBackupEnabled = true
        backupManager.autoBackupFrequency = .daily
        backupManager.lastAutoBackupDate = nil
        
        let warningDiagnostics = backupManager.validateAutoBackupSystem()
        
        // This should be a warning, not an error (no backup yet is expected for new systems)
        #expect(warningDiagnostics.status == .warning || warningDiagnostics.status == .healthy, 
               "Should be warning or healthy when no backup exists yet")
        
        // Should have some form of feedback about the backup status
        let hasBackupInfo = !warningDiagnostics.warnings.isEmpty || !warningDiagnostics.info.isEmpty
        #expect(hasBackupInfo, "Should have warnings or info about backup status")
    }
    
    @Test("Auto-backup frequency time intervals")
    func autoBackupFrequencyTimeIntervals() async throws {
        #expect(AutoBackupFrequency.never.timeInterval == 0)
        #expect(AutoBackupFrequency.hourly.timeInterval == 3600)
        #expect(AutoBackupFrequency.daily.timeInterval == 86400)
        #expect(AutoBackupFrequency.weekly.timeInterval == 604800)
        
        // Test display names
        #expect(AutoBackupFrequency.never.displayName == "Never")
        #expect(AutoBackupFrequency.hourly.displayName == "Every Hour")
        #expect(AutoBackupFrequency.daily.displayName == "Daily")
        #expect(AutoBackupFrequency.weekly.displayName == "Weekly")
    }
    
    @Test("Auto-backup settings persistence")
    @MainActor
    func autoBackupSettingsPersistence() async throws {
        let testContainer = try createTestModelContainer()
        
        // Clear existing settings completely
        ["autoBackupEnabled", "autoBackupFrequency", "maxBackupsToKeep", "lastAutoBackupDate", "lastDataChangeDate"].forEach {
            UserDefaults.standard.removeObject(forKey: $0)
        }
        
        // Create backup manager (should load defaults)
        let backupManager = ComprehensiveBackupManager(modelContext: testContainer.mainContext)
        
        // Test default values after clearing UserDefaults
        #expect(backupManager.maxBackupsToKeep == 5, "Should default to 5 backups")
        #expect(backupManager.lastAutoBackupDate == nil, "Should start with no backup date")
        #expect(backupManager.lastDataChangeDate == nil, "Should start with no data change date")
        
        // Update settings
        let testDate = Date()
        backupManager.updateAutoBackupSettings(
            enabled: true,
            frequency: .hourly,
            maxBackups: 10
        )
        
        backupManager.lastDataChangeDate = testDate
        backupManager.saveAutoBackupSettings()
        
        // Verify settings were persisted
        #expect(UserDefaults.standard.bool(forKey: "autoBackupEnabled"))
        #expect(UserDefaults.standard.integer(forKey: "autoBackupFrequency") == AutoBackupFrequency.hourly.rawValue)
        #expect(UserDefaults.standard.integer(forKey: "maxBackupsToKeep") == 10)
        
        let savedDataChangeDate = UserDefaults.standard.object(forKey: "lastDataChangeDate") as? Date
        #expect(savedDataChangeDate != nil, "Data change date should be persisted")
        
        // Test loading in new instance
        let newBackupManager = ComprehensiveBackupManager(modelContext: testContainer.mainContext)
        
        #expect(newBackupManager.autoBackupEnabled)
        #expect(newBackupManager.autoBackupFrequency == .hourly)
        #expect(newBackupManager.maxBackupsToKeep == 10)
        #expect(newBackupManager.lastDataChangeDate != nil)
        
        // Clean up for other tests
        ["autoBackupEnabled", "autoBackupFrequency", "maxBackupsToKeep", "lastAutoBackupDate", "lastDataChangeDate"].forEach {
            UserDefaults.standard.removeObject(forKey: $0)
        }
    }
    
    @Test("Auto-backup system restart")
    @MainActor
    func autoBackupSystemRestart() async throws {
        let testContainer = try createTestModelContainer()
        let backupManager = ComprehensiveBackupManager(modelContext: testContainer.mainContext)
        
        // Clear existing settings to ensure clean test
        ["autoBackupEnabled", "autoBackupFrequency", "maxBackupsToKeep"].forEach {
            UserDefaults.standard.removeObject(forKey: $0)
        }
        
        // Setup system
        backupManager.autoBackupEnabled = true
        backupManager.autoBackupFrequency = .daily
        backupManager.saveAutoBackupSettings()  // Ensure settings are saved
        
        // Restart system (this reloads settings from UserDefaults)
        backupManager.restartAutoBackupSystem()
        
        // Verify system is still configured correctly after restart
        // Note: restartAutoBackupSystem() calls loadAutoBackupSettings() which reloads from UserDefaults
        #expect(backupManager.autoBackupEnabled)
        #expect(backupManager.autoBackupFrequency == .daily)
        
        // Clean up
        ["autoBackupEnabled", "autoBackupFrequency", "maxBackupsToKeep"].forEach {
            UserDefaults.standard.removeObject(forKey: $0)
        }
        
        // The restart should have posted a notification
        // Note: In a real test, we would set up a notification observer to verify this
    }
    
    @Test("Auto-backup trigger descriptions")
    func autoBackupTriggerDescriptions() async throws {
        #expect(AutoBackupTrigger.timer.description == "scheduled timer")
        #expect(AutoBackupTrigger.appBackground.description == "app background") 
        #expect(AutoBackupTrigger.appTerminating.description == "app terminating")
        #expect(AutoBackupTrigger.dataChange.description == "data change")
    }
    
    @Test("Auto-backup system status properties")
    func autoBackupSystemStatusProperties() async throws {
        #expect(AutoBackupSystemStatus.healthy.displayName == "Healthy")
        #expect(AutoBackupSystemStatus.warning.displayName == "Warning")
        #expect(AutoBackupSystemStatus.error.displayName == "Error")
        
        #expect(AutoBackupSystemStatus.healthy.icon == "checkmark.circle.fill")
        #expect(AutoBackupSystemStatus.warning.icon == "exclamationmark.triangle.fill")
        #expect(AutoBackupSystemStatus.error.icon == "xmark.circle.fill")
        
        // Color properties exist (can't easily test Color values but verify they exist)
        let _ = AutoBackupSystemStatus.healthy.color
        let _ = AutoBackupSystemStatus.warning.color
        let _ = AutoBackupSystemStatus.error.color
    }
}

// MARK: - Test Helper Functions

/// Creates a test model container for testing
private func createTestModelContainer() throws -> ModelContainer {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    return try ModelContainer(for: Project.self, Client.self, Item.self, Invoice.self, configurations: config)
}
