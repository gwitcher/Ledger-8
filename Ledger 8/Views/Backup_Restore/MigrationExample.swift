//
//  MigrationExample.swift
//  Ledger 8
//
//  Created by MVVM Migration on 10/29/25.
//

import SwiftUI
import SwiftData

/// Example showing how to replace ComprehensiveBackupManager usage
/// with the new MVVM BackupCoordinator architecture
struct MigrationExample: View {
    @Environment(\.modelContext) private var modelContext
    
    // MARK: - OLD APPROACH (DO NOT USE)
    /*
    // ❌ OLD: Direct manager usage - DEPRECATED
    @StateObject private var backupManager = ComprehensiveBackupManager(modelContext: modelContext)
    */
    
    // MARK: - ✅ NEW MVVM APPROACH - USE THIS INSTEAD
    @State private var backupCoordinator: BackupCoordinator?
    @State private var backupOperationsVM: BackupOperationsViewModel?
    @State private var autoBackupSettingsVM: AutoBackupSettingsViewModel?
    @State private var backupListVM: BackupListViewModel?
    
    var body: some View {
        NavigationStack {
            List {
                backupOperationsSection
                autoBackupSettingsSection
                backupFilesSection
            }
            .navigationTitle("Backup & Restore")
            .onAppear {
                setupMVVMArchitecture()
            }
            .onChange(of: modelContext) { _, newContext in
                // Update model context across all services when it changes
                backupCoordinator?.updateModelContext(newContext)
            }
        }
    }
    
    // MARK: - ✅ NEW MVVM Setup
    private func setupMVVMArchitecture() {
        if backupCoordinator == nil {
            // Create coordinator - this replaces ComprehensiveBackupManager
            backupCoordinator = BackupCoordinator(modelContext: modelContext)
            
            // Create ViewModels through the coordinator
            backupOperationsVM = backupCoordinator?.createBackupOperationsViewModel()
            autoBackupSettingsVM = backupCoordinator?.createAutoBackupSettingsViewModel()
            backupListVM = backupCoordinator?.createBackupListViewModel()
        }
    }
    
    // MARK: - UI Sections Using New Architecture
    
    private var backupOperationsSection: some View {
        Section("Backup Operations") {
            if let viewModel = backupOperationsVM {
                VStack(alignment: .leading, spacing: 8) {
                    // ✅ NEW: Clean ViewModel binding
                    Button("Create Backup") {
                        Task {
                            await viewModel.createBackup()
                        }
                    }
                    .disabled(!viewModel.canPerformOperations)
                    
                    // ✅ NEW: Contextual progress display
                    if viewModel.shouldShowProgress {
                        ProgressView(value: viewModel.progress)
                        Text(viewModel.statusMessage)
                            .font(.caption)
                            .foregroundStyle(viewModel.statusColor)
                    }
                    
                    // ✅ NEW: Contextual error handling
                    if viewModel.hasError {
                        Text(viewModel.errorMessage ?? "")
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }
            } else {
                Text("Loading...")
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    private var autoBackupSettingsSection: some View {
        Section("Auto-Backup Settings") {
            if let viewModel = autoBackupSettingsVM {
                VStack(alignment: .leading, spacing: 8) {
                    // ✅ NEW: Reactive settings binding
                    Toggle("Auto-Backup Enabled", isOn: .constant(viewModel.autoBackupEnabled))
                        .disabled(true) // Read-only for demo
                    
                    HStack {
                        Text("Frequency:")
                        Spacer()
                        Text(viewModel.backupFrequencyDescription)
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("Last Backup:")
                        Spacer()
                        Text(viewModel.formattedLastBackupDate)
                            .foregroundStyle(.secondary)
                    }
                    
                    // ✅ NEW: System health indicator
                    HStack {
                        Image(systemName: viewModel.systemStatusIcon)
                            .foregroundStyle(viewModel.systemStatusColor)
                        Text(viewModel.systemHealthSummary)
                            .font(.caption)
                    }
                }
            } else {
                Text("Loading...")
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    private var backupFilesSection: some View {
        Section("Backup Files") {
            if let viewModel = backupListVM {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Auto Backups:")
                        Spacer()
                        Text("\(viewModel.filteredAutoBackups.count)")
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("Manual Backups:")
                        Spacer()
                        Text("\(viewModel.filteredManualBackups.count)")
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("Total Files:")
                        Spacer()
                        Text("\(viewModel.totalBackupsCount)")
                            .fontWeight(.medium)
                    }
                    
                    if viewModel.isLoading {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Loading backup files...")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            } else {
                Text("Loading...")
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Migration Comparison Comments

/*
 
 MIGRATION SUMMARY - ComprehensiveBackupManager → BackupCoordinator
 
 ✅ BEFORE (Old Monolithic Approach):
 
 @StateObject private var backupManager = ComprehensiveBackupManager(modelContext: modelContext)
 
 Button("Create Backup") {
     Task {
         try await backupManager.createCompleteBackup()
     }
 }
 .disabled(backupManager.isBackingUp)
 
 Toggle("Auto Backup", isOn: $backupManager.autoBackupEnabled)
 
 if let error = backupManager.errorMessage {
     Text(error).foregroundStyle(.red)
 }
 
 ---
 
 ✅ AFTER (New MVVM Approach):
 
 @State private var backupCoordinator = BackupCoordinator(modelContext: modelContext)
 @State private var backupOperationsVM: BackupOperationsViewModel?
 @State private var autoBackupSettingsVM: AutoBackupSettingsViewModel?
 
 // In onAppear:
 backupOperationsVM = backupCoordinator.createBackupOperationsViewModel()
 autoBackupSettingsVM = backupCoordinator.createAutoBackupSettingsViewModel()
 
 Button("Create Backup") {
     Task {
         await backupOperationsVM.createBackup()
     }
 }
 .disabled(!backupOperationsVM.canPerformOperations)
 
 Toggle("Auto Backup", isOn: $autoBackupSettingsVM.autoBackupEnabled)
 
 if backupOperationsVM.hasError {
     Text(backupOperationsVM.errorMessage ?? "")
         .foregroundStyle(backupOperationsVM.statusColor)
 }
 
 ---
 
 🎉 BENEFITS ACHIEVED:
 
 ✅ Separation of Concerns: UI logic separated from business logic
 ✅ Better Testability: Protocol-based services can be easily mocked
 ✅ Modern Swift: Uses @Observable instead of @Published/@StateObject
 ✅ Contextual State: Each ViewModel manages its own UI state
 ✅ Error Handling: Contextual, type-safe error management
 ✅ Scalability: Easy to add new features without modifying existing code
 ✅ Maintainability: Clear dependency graph and single responsibility
 
 */

#Preview {
    MigrationExample()
}