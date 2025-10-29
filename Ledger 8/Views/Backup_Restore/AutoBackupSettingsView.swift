//
//
//  ✅ KEEP THIS FILE - AutoBackupSettingsView 4.swift (NEW MVVM ARCHITECTURE)
//  ✅ MODERN IMPLEMENTATION: Uses new MVVM BackupCoordinator approach
//  ✅ UP-TO-DATE: Uses @Observable and @Bindable patterns
//  ❌ DELETE INSTEAD: AutoBackupSettingsView.swift (old ComprehensiveBackupManager version)
//  📝 RENAME TO: AutoBackupSettingsView.swift (after deleting the old one)
//
//  AutoBackupSettingsView 4.swift (KEEP & RENAME THIS ONE)
//  Ledger 8
//
//  Created by MVVM Refactoring on 10/28/25.
//

import SwiftUI
import SwiftData

struct AutoBackupSettingsView: View {
    @State var viewModel: AutoBackupSettingsViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                mainSettingsSection
                statusSection
                actionsSection
                diagnosticsSection
            }
            .navigationTitle("Auto-Backup Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Reset") {
                        viewModel.resetToDefaults()
                    }
                    .disabled(!viewModel.canPerformOperations)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: .constant(viewModel.hasError)) {
                Button("OK") {
                    viewModel.clearError()
                }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .sheet(isPresented: $viewModel.showingDiagnostics) {
                AutoBackupDiagnosticsView(diagnostics: viewModel.diagnostics ?? AutoBackupDiagnostics(
                    status: .healthy,
                    issues: [],
                    warnings: [],
                    info: [],
                    lastValidated: Date()
                ))
            }
        }
    }
    
    private var mainSettingsSection: some View {
        Section("Auto-Backup Configuration") {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Toggle("Enable Auto-Backup", isOn: $viewModel.autoBackupEnabled)
                        .disabled(!viewModel.canPerformOperations)
                    
                    if !viewModel.autoBackupEnabled {
                        Text("Automatic backups are disabled")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            if viewModel.shouldShowFrequencyPicker {
                Picker("Backup Frequency", selection: $viewModel.autoBackupFrequency) {
                    ForEach(viewModel.availableFrequencies, id: \.self) { frequency in
                        Text(frequency.displayName).tag(frequency)
                    }
                }
                .disabled(!viewModel.canPerformOperations)
            }
            
            HStack {
                Text("Keep Maximum Backups")
                Spacer()
                Stepper(value: $viewModel.maxBackupsToKeep, in: viewModel.maxBackupsRange) {
                    Text("\(viewModel.maxBackupsToKeep)")
                        .font(.headline)
                }
                .disabled(!viewModel.canPerformOperations)
            }
        }
    }
    
    private var statusSection: some View {
        Section("Status") {
            HStack {
                Image(systemName: viewModel.systemStatusIcon)
                    .foregroundColor(viewModel.systemStatusColor)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("System Status")
                        .font(.subheadline)
                    Text(viewModel.systemHealthSummary)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if viewModel.shouldShowHealthWarning {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(.orange)
                }
            }
            
            HStack {
                Text("Last Auto-Backup")
                    .font(.subheadline)
                Spacer()
                Text(viewModel.formattedLastBackupDate)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            if let statusMessage = viewModel.statusMessage, !statusMessage.isEmpty {
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(.blue)
                    Text(statusMessage)
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
        }
    }
    
    private var actionsSection: some View {
        Section("Actions") {
            Button(action: {
                Task {
                    await viewModel.performManualBackup()
                }
            }) {
                HStack {
                    Image(systemName: viewModel.isPerformingManualBackup ? "arrow.clockwise" : "play.fill")
                    Text(viewModel.isPerformingManualBackup ? "Performing Backup..." : "Perform Backup Now")
                    
                    if viewModel.isPerformingManualBackup {
                        Spacer()
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
            }
            .disabled(!viewModel.canTriggerManualBackup)
            
            Button(action: {
                viewModel.restartSystem()
            }) {
                HStack {
                    Image(systemName: viewModel.isRestartingSystem ? "arrow.clockwise" : "arrow.counterclockwise")
                    Text(viewModel.isRestartingSystem ? "Restarting..." : "Restart Auto-Backup System")
                    
                    if viewModel.isRestartingSystem {
                        Spacer()
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
            }
            .disabled(!viewModel.canPerformOperations)
        }
    }
    
    private var diagnosticsSection: some View {
        Section("Diagnostics") {
            Button(action: {
                viewModel.showDiagnostics()
            }) {
                HStack {
                    Image(systemName: "stethoscope")
                    Text("View System Diagnostics")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if viewModel.shouldShowHealthWarning {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("System Warning")
                            .font(.subheadline)
                            .foregroundColor(.orange)
                        
                        Text(viewModel.healthWarningMessage)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
            }
        }
    }
}

// Extension for preview support
extension ModelContext {
    static var preview: ModelContext {
        let container = try! ModelContainer(for: Client.self, Project.self, Item.self, Invoice.self)
        return container.mainContext
    }
}