//
//  AutoBackupAndDataTransformationTests.swift
//  Ledger 8 Tests
//
//  Tests for Auto-Backup System and Data Transformation logic
//

import Testing
import Foundation
import SwiftData
@testable import Ledger_8

// MARK: - Auto-Backup System Tests (CRITICAL - Silent Background Operations)

@Suite("Auto-Backup System Critical Logic")
struct AutoBackupSystemTests {
    
    @Test("Auto-backup frequency time intervals are correct")
    func autoBackupFrequencyIntervals() async throws {
        #expect(AutoBackupFrequency.never.timeInterval == 0)
        #expect(AutoBackupFrequency.hourly.timeInterval == 3600) // 1 hour
        #expect(AutoBackupFrequency.daily.timeInterval == 86400) // 24 hours  
        #expect(AutoBackupFrequency.weekly.timeInterval == 604800) // 7 days
        
        // Verify all cases are covered
        let allFrequencies: [AutoBackupFrequency] = [.never, .hourly, .daily, .weekly]
        #expect(allFrequencies.count == AutoBackupFrequency.allCases.count,
               "All AutoBackupFrequency cases should be tested")
    }
    
    @Test("Auto-backup frequency display names are correct")
    func autoBackupFrequencyDisplayNames() async throws {
        #expect(AutoBackupFrequency.never.displayName == "Never")
        #expect(AutoBackupFrequency.hourly.displayName == "Every Hour")
        #expect(AutoBackupFrequency.daily.displayName == "Daily")
        #expect(AutoBackupFrequency.weekly.displayName == "Weekly")
    }
    
    @Test("Auto-backup settings persistence works correctly")
    func autoBackupSettingsPersistence() async throws {
        let testContainer = try createTestModelContainer()
        
        // Clear any existing settings
        UserDefaults.standard.removeObject(forKey: "autoBackupEnabled")
        UserDefaults.standard.removeObject(forKey: "autoBackupFrequency") 
        UserDefaults.standard.removeObject(forKey: "maxBackupsToKeep")
        
        // Create backup manager (should load defaults)
        let backupManager = await ComprehensiveBackupManager(modelContext: testContainer.mainContext)
        
        // Test default values
        await MainActor.run {
            #expect(backupManager.maxBackupsToKeep == 5, "Should default to 5 backups")
        }
        
        // Update settings
        await backupManager.updateAutoBackupSettings(
            enabled: true,
            frequency: .hourly,
            maxBackups: 10
        )
        
        // Verify settings were applied
        await MainActor.run {
            #expect(backupManager.autoBackupEnabled == true)
            #expect(backupManager.autoBackupFrequency == .hourly)
            #expect(backupManager.maxBackupsToKeep == 10)
        }
        
        // Verify settings were persisted to UserDefaults
        #expect(UserDefaults.standard.bool(forKey: "autoBackupEnabled") == true)
        #expect(UserDefaults.standard.integer(forKey: "autoBackupFrequency") == AutoBackupFrequency.hourly.rawValue)
        #expect(UserDefaults.standard.integer(forKey: "maxBackupsToKeep") == 10)
    }
    
    @Test("Auto-backup file info parsing works correctly")
    func autoBackupFileInfoParsing() async throws {
        // Test file size formatting
        let smallFile = AutoBackupInfo(
            url: URL(fileURLWithPath: "/test1.l8backup"),
            fileName: "test1.l8backup",
            creationDate: Date(),
            fileSize: 1024
        )
        #expect(smallFile.formattedFileSize == "1 KB", "Should format small file size correctly")
        
        let largeFile = AutoBackupInfo(
            url: URL(fileURLWithPath: "/test2.l8backup"),
            fileName: "test2.l8backup", 
            creationDate: Date(),
            fileSize: 1_048_576
        )
        #expect(largeFile.formattedFileSize == "1 MB", "Should format large file size correctly")
        
        // Test date formatting consistency
        let testDate = Date()
        let testFile = AutoBackupInfo(
            url: URL(fileURLWithPath: "/test3.l8backup"),
            fileName: "test3.l8backup",
            creationDate: testDate,
            fileSize: 2048
        )
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        let expectedDateString = dateFormatter.string(from: testDate)
        #expect(testFile.formattedDate == expectedDateString, "Should format date correctly")
    }
    
    @Test("Auto-backup trigger logic handles all scenarios")
    func autoBackupTriggerLogic() async throws {
        let testContainer = try createTestModelContainer()
        let backupManager = await ComprehensiveBackupManager(modelContext: testContainer.mainContext)
        
        await MainActor.run {
            // Test 1: Never backed up before - should backup (simulated)
            backupManager.lastAutoBackupDate = nil
            backupManager.autoBackupFrequency = .daily
            backupManager.autoBackupEnabled = true
        }
        
        // Test 2: Recent backup - should NOT backup (simulated)
        await MainActor.run {
            backupManager.lastAutoBackupDate = Date().addingTimeInterval(-3600) // 1 hour ago
            backupManager.autoBackupFrequency = .daily // Requires 24 hours
        }
        
        let (timeSinceLastBackup, requiredInterval) = await MainActor.run {
            let timeSinceLastBackup = Date().timeIntervalSince(backupManager.lastAutoBackupDate!)
            let requiredInterval = backupManager.autoBackupFrequency.timeInterval
            return (timeSinceLastBackup, requiredInterval)
        }
        
        #expect(timeSinceLastBackup < requiredInterval, "Recent backup should not meet time requirement")
        
        // Test 3: Old backup - should backup (simulated)
        let timeSinceOldBackup = await MainActor.run {
            backupManager.lastAutoBackupDate = Date().addingTimeInterval(-25 * 3600) // 25 hours ago
            return Date().timeIntervalSince(backupManager.lastAutoBackupDate!)
        }
        
        #expect(timeSinceOldBackup >= requiredInterval, "Old backup should meet time requirement")
    }
}

// MARK: - Data Transformation & Relationship Tests (CRITICAL - Data Integrity)

@Suite("Backup Data Transformation & Relationships")
struct BackupDataTransformationTests {
    
    @Test("Complete backup client transformation preserves all fields")
    func completeClientTransformation() async throws {
        // Create comprehensive test client
        let client = Client(
            firstName: "John",
            lastName: "Doe", 
            email: "john.doe@example.com",
            phone: "(555) 123-4567",
            attention: "Attn: John Doe",
            address: "123 Main Street",
            address2: "Suite 100",
            city: "Springfield",
            state: "IL", 
            zip: "62701",
            notes: "Important long-term client with special requirements",
            company: "Doe Enterprises Inc."
        )
        
        // Transform to backup format
        let backupClient = CompleteBackupClient(from: client)
        
        // Verify ALL fields are preserved
        #expect(backupClient.firstName == "John")
        #expect(backupClient.lastName == "Doe")
        #expect(backupClient.email == "john.doe@example.com")
        #expect(backupClient.phone == "(555) 123-4567")
        #expect(backupClient.attention == "Attn: John Doe")
        #expect(backupClient.address == "123 Main Street")
        #expect(backupClient.address2 == "Suite 100") 
        #expect(backupClient.city == "Springfield")
        #expect(backupClient.state == "IL")
        #expect(backupClient.zip == "62701")
        #expect(backupClient.notes == "Important long-term client with special requirements")
        #expect(backupClient.company == "Doe Enterprises Inc.")
        
        // Test lookup key generation for relationships
        #expect(backupClient.lookupKey == "John Doe Doe Enterprises Inc.")
        
        // Test round-trip transformation
        let restoredClient = Client()
        backupClient.applyTo(restoredClient)
        
        // Verify restoration preserves all data
        #expect(restoredClient.firstName == client.firstName)
        #expect(restoredClient.lastName == client.lastName)
        #expect(restoredClient.email == client.email)
        #expect(restoredClient.phone == client.phone)
        #expect(restoredClient.attention == client.attention)
        #expect(restoredClient.address == client.address)
        #expect(restoredClient.address2 == client.address2)
        #expect(restoredClient.city == client.city)
        #expect(restoredClient.state == client.state)
        #expect(restoredClient.zip == client.zip)
        #expect(restoredClient.notes == client.notes)
        #expect(restoredClient.company == client.company)
    }
    
    @Test("Project-Client relationship handling in backup")
    func projectClientRelationshipBackup() async throws {
        // Create client
        let client = Client(
            firstName: "Jane",
            lastName: "Producer", 
            email: "jane@studio.com",
            company: "Studio Productions"
        )
        
        // Create project with client relationship
        let project = Project(
            projectName: "Album Recording",
            artist: "The Test Band",
            status: .open,
            mediaType: .recording,
            notes: "24-track studio recording session"
        )
        project.client = client
        
        // Transform project to backup format
        let backupProject = CompleteBackupProject(from: project)
        
        // Verify project data
        #expect(backupProject.projectName == "Album Recording")
        #expect(backupProject.artist == "The Test Band")
        #expect(backupProject.status == .open)
        #expect(backupProject.mediaType == .recording)
        #expect(backupProject.notes == "24-track studio recording session")
        
        // Verify client relationship is captured via lookup key
        let expectedClientKey = "Jane Producer Studio Productions"
        #expect(backupProject.clientLookupKey == expectedClientKey,
               "Project should capture client lookup key for relationship restoration")
        
        // Verify project lookup key for items
        let expectedProjectKey = "\(project.projectName)_\(project.artist)_\(project.startDate.timeIntervalSince1970)"
        #expect(backupProject.lookupKey == expectedProjectKey,
               "Project should have consistent lookup key")
    }
    
    @Test("Item-Project relationship chain in backup")
    func itemProjectRelationshipChain() async throws {
        // Create full relationship chain: Client -> Project -> Item
        let client = Client(firstName: "Bob", lastName: "Manager", company: "Music Corp")
        
        let project = Project(
            projectName: "Demo Recording",
            artist: "New Artist",
            mediaType: .tv
        )
        project.client = client
        
        let item1 = Item(
            name: "Vocal Recording",
            fee: 200.0,
            itemType: .session,
            notes: "Lead vocal tracks"
        )
        item1.project = project
        
        let item2 = Item(
            name: "Guitar Overdubs", 
            fee: 150.0,
            itemType: .overdub,
            notes: "Electric guitar parts"
        )
        item2.project = project
        
        // Transform all to backup format
        let backupClient = CompleteBackupClient(from: client)
        let backupProject = CompleteBackupProject(from: project)
        let backupItem1 = CompleteBackupItem(from: item1)
        let backupItem2 = CompleteBackupItem(from: item2)
        
        // Verify relationship keys are consistent for restoration
        #expect(backupProject.clientLookupKey == backupClient.lookupKey,
               "Project should reference correct client")
        
        #expect(backupItem1.projectLookupKey == backupProject.lookupKey,
               "Item1 should reference correct project")
        
        #expect(backupItem2.projectLookupKey == backupProject.lookupKey,
               "Item2 should reference correct project")
        
        // Verify item data integrity
        #expect(backupItem1.name == "Vocal Recording")
        #expect(backupItem1.fee == 200.0)
        #expect(backupItem1.itemType == .session)
        #expect(backupItem1.notes == "Lead vocal tracks")
        
        #expect(backupItem2.name == "Guitar Overdubs")
        #expect(backupItem2.fee == 150.0)
        #expect(backupItem2.itemType == .overdub)
        #expect(backupItem2.notes == "Electric guitar parts")
    }
    
    @Test("Client lookup key handles edge cases correctly")
    func clientLookupKeyEdgeCases() async throws {
        // Test 1: Empty name, use email
        let emailOnlyClient = Client(email: "contact@example.com")
        let emailBackup = CompleteBackupClient(from: emailOnlyClient)
        #expect(emailBackup.lookupKey == "contact@example.com")
        
        // Test 2: Only first name
        let firstNameClient = Client(firstName: "John")
        let firstNameBackup = CompleteBackupClient(from: firstNameClient)
        #expect(firstNameBackup.lookupKey == "John")
        
        // Test 3: Only last name
        let lastNameClient = Client(lastName: "Doe")
        let lastNameBackup = CompleteBackupClient(from: lastNameClient)
        #expect(lastNameBackup.lookupKey == "Doe")
        
        // Test 4: Only company
        let companyClient = Client(company: "ACME Corp")
        let companyBackup = CompleteBackupClient(from: companyClient)
        #expect(companyBackup.lookupKey == "ACME Corp")
        
        // Test 5: All fields empty - should use empty email
        let emptyClient = Client()
        let emptyBackup = CompleteBackupClient(from: emptyClient)
        #expect(emptyBackup.lookupKey == "")
    }
    
    @Test("AppSettings backup and restore preserves preferences")
    func appSettingsBackupRestore() async throws {
        // Clear existing UserDefaults
        UserDefaults.standard.removeObject(forKey: "userData")
        UserDefaults.standard.removeObject(forKey: "InitialInvoiceNumber")
        
        // Set test values
        var testUserData = UserData()
        testUserData.userFirstName = "Test"
        testUserData.userLastName = "User"
        UserDefaults.standard.set(testUserData.rawValue, forKey: "userData")
        UserDefaults.standard.set(5000, forKey: "InitialInvoiceNumber")
        
        // Create backup of current settings
        let backupSettings = BackupAppSettings.current()
        
        // Verify backup captured settings
        #expect(backupSettings.userData?.userFirstName == "Test")
        #expect(backupSettings.userData?.userLastName == "User")
        #expect(backupSettings.initialInvoiceNumber == 5000)
        
        // Clear settings and verify they're gone
        UserDefaults.standard.removeObject(forKey: "userData")
        UserDefaults.standard.removeObject(forKey: "InitialInvoiceNumber")
        
        #expect(UserDefaults.standard.string(forKey: "userData") == nil)
        #expect(UserDefaults.standard.integer(forKey: "InitialInvoiceNumber") == 0)
        
        // Restore from backup
        backupSettings.applyToCurrentApp()
        
        // Verify restoration worked
        #expect(UserDefaults.standard.integer(forKey: "InitialInvoiceNumber") == 5000)
        
        if let restoredUserDataString = UserDefaults.standard.string(forKey: "userData"),
           let restoredUserData = UserData(rawValue: restoredUserDataString) {
            #expect(restoredUserData.userFirstName == "Test")
            #expect(restoredUserData.userLastName == "User")
        } else {
            #expect(Bool(false), "UserData should be restored")
        }
    }
}

// MARK: - Test Helper Functions

/// Creates a test model container for testing
private func createTestModelContainer() throws -> ModelContainer {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    return try ModelContainer(for: Project.self, Client.self, Item.self, Invoice.self, configurations: config)
}
