//
//  AutoBackupDiagnosticsViewModelTests.swift
//  Ledger 8 Tests
//
//  Created by Gabe Witcher on 10/28/25.
//

import Testing
import SwiftData
@testable import Ledger_8

@Suite("AutoBackupDiagnosticsViewModel Tests")
struct AutoBackupDiagnosticsViewModelTests {
    
    @Test("ViewModel initializes correctly")
    @MainActor
    func testInitialization() async throws {
        // Arrange
        let schema = Schema([Project.self, Client.self, Item.self, Invoice.self])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
        let backupManager = ComprehensiveBackupManager(modelContext: container.mainContext)
        
        // Act
        let viewModel = AutoBackupDiagnosticsViewModel(backupManager: backupManager)
        
        // Assert
        #expect(!viewModel.isLoaded, "ViewModel should not be loaded initially")
        #expect(!viewModel.isRefreshing, "ViewModel should not be refreshing initially")
        #expect(!viewModel.showingRestartConfirmation, "Restart confirmation should not be showing initially")
        #expect(viewModel.issues.isEmpty, "Issues should be empty initially")
        #expect(viewModel.warnings.isEmpty, "Warnings should be empty initially")
        #expect(viewModel.systemInfo.isEmpty, "System info should be empty initially")
    }
    
    @Test("ViewModel loads diagnostics")
    @MainActor
    func testLoadDiagnostics() async throws {
        // Arrange
        let schema = Schema([Project.self, Client.self, Item.self, Invoice.self])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
        let backupManager = ComprehensiveBackupManager(modelContext: container.mainContext)
        let viewModel = AutoBackupDiagnosticsViewModel(backupManager: backupManager)
        
        // Act
        viewModel.loadDiagnostics()
        
        // Wait a bit for the async operation to complete
        try await Task.sleep(nanoseconds: 600_000_000) // 0.6 seconds
        
        // Assert
        #expect(viewModel.isLoaded, "ViewModel should be loaded after calling loadDiagnostics")
        #expect(!viewModel.isRefreshing, "ViewModel should not be refreshing after completion")
    }
    
    @Test("ViewModel provides correct computed properties")
    @MainActor
    func testComputedProperties() async throws {
        // Arrange
        let schema = Schema([Project.self, Client.self, Item.self, Invoice.self])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
        let backupManager = ComprehensiveBackupManager(modelContext: container.mainContext)
        let viewModel = AutoBackupDiagnosticsViewModel(backupManager: backupManager)
        
        // Act
        viewModel.loadDiagnostics()
        try await Task.sleep(nanoseconds: 600_000_000) // 0.6 seconds
        
        // Assert
        #expect(viewModel.getIssueIcon() == "xmark.circle.fill", "Issue icon should be correct")
        #expect(viewModel.getWarningIcon() == "exclamationmark.triangle.fill", "Warning icon should be correct")
        #expect(viewModel.getInfoIcon() == "info.circle", "Info icon should be correct")
        #expect(!viewModel.restartConfirmationTitle.isEmpty, "Restart confirmation title should not be empty")
        #expect(!viewModel.restartConfirmationMessage.isEmpty, "Restart confirmation message should not be empty")
    }
    
    @Test("ViewModel handles restart confirmation correctly")
    @MainActor
    func testRestartConfirmation() async throws {
        // Arrange
        let schema = Schema([Project.self, Client.self, Item.self, Invoice.self])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
        let backupManager = ComprehensiveBackupManager(modelContext: container.mainContext)
        let viewModel = AutoBackupDiagnosticsViewModel(backupManager: backupManager)
        
        // Act & Assert
        #expect(!viewModel.showingRestartConfirmation, "Should not show restart confirmation initially")
        
        viewModel.showRestartConfirmation()
        #expect(viewModel.showingRestartConfirmation, "Should show restart confirmation after calling showRestartConfirmation")
        
        viewModel.hideRestartConfirmation()
        #expect(!viewModel.showingRestartConfirmation, "Should hide restart confirmation after calling hideRestartConfirmation")
    }
    
    @Test("ViewModel section visibility logic")
    @MainActor
    func testSectionVisibility() async throws {
        // Arrange
        let schema = Schema([Project.self, Client.self, Item.self, Invoice.self])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
        let backupManager = ComprehensiveBackupManager(modelContext: container.mainContext)
        let viewModel = AutoBackupDiagnosticsViewModel(backupManager: backupManager)
        
        // Act
        viewModel.loadDiagnostics()
        try await Task.sleep(nanoseconds: 600_000_000) // 0.6 seconds
        
        // Assert - These will depend on the actual diagnostic results
        // The logic should work correctly regardless of the specific results
        let shouldShowIssues = viewModel.shouldShowIssuesSection()
        let shouldShowWarnings = viewModel.shouldShowWarningsSection()
        let shouldShowSystemInfo = viewModel.shouldShowSystemInfoSection()
        
        #expect(shouldShowIssues == viewModel.hasIssues, "Issue section visibility should match hasIssues")
        #expect(shouldShowWarnings == viewModel.hasWarnings, "Warning section visibility should match hasWarnings")
        #expect(shouldShowSystemInfo == !viewModel.systemInfo.isEmpty, "System info section visibility should match info availability")
    }
}
