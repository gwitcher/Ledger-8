//
//  AutoBackupSettingsView.swift
//  Ledger 8
//
//  Created by MVVM Refactoring on 10/28/25.
//

import SwiftUI

struct AutoBackupSettingsView: View {
    @ObservedObject var viewModel: AutoBackupSettingsViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                autoBackupSection
                frequencySection
                storageSection
                systemHealthSection
                troubleshootingSection
            }
            .navigationTitle("Auto-Backup Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
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
                SystemDiagnosticsView(diagnostics: viewModel.diagnostics)
            }
        }
    }
    
    // MARK: - View Sections
    
    private var autoBackupSection: some View {
        Section {
            Toggle("Auto-Backup", isOn: $viewModel.autoBackupEnabled)
                .onChange(of: viewModel.autoBackupEnabled) { _, newValue in
                    // ViewModel handles the update automatically
                }
            
            if !viewModel.autoBackupEnabled {
                Text("Turn on auto-backup to automatically save your data at regular intervals.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        } header: {
            Text("Automatic Backup")
        } footer: {
            if viewModel.autoBackupEnabled {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Last backup: \(viewModel.formattedLastBackupDate)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if viewModel.shouldShowHealthWarning {
                        Label(viewModel.healthWarningMessage, systemImage: "exclamationmark.triangle")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }
        }
    }
    
    private var frequencySection: some View {
        Section("Backup Frequency") {
            if viewModel.shouldShowFrequencyPicker {
                Picker("Frequency", selection: $viewModel.autoBackupFrequency) {
                    ForEach(viewModel.availableFrequencies, id: \.self) { frequency in
                        Text(frequency.displayName)
                            .tag(frequency)
                    }
                }
                .pickerStyle(WheelPickerStyle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Current: \(viewModel.backupFrequencyDescription)")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    
                    Text("Auto-backups are saved to: Files > Ledger 8 > Backups > Auto")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else {
                Text("Enable auto-backup to configure frequency")
                    .foregroundColor(.secondary)
            }
        }
        .opacity(viewModel.shouldShowFrequencyPicker ? 1.0 : 0.6)
    }
    
    private var storageSection: some View {
        Section("Storage Management") {
            HStack {
                Text("Keep recent backups")
                Spacer()
                Stepper(
                    "\(viewModel.maxBackupsToKeep)",
                    value: $viewModel.maxBackupsToKeep,
                    in: viewModel.maxBackupsRange
                )
            }
            
            if viewModel.canTriggerManualBackup {
                Button("Create Backup Now") {
                    Task {
                        await viewModel.performManualBackup()
                    }
                }
                .disabled(!viewModel.canPerformOperations)
                
                if viewModel.isPerformingManualBackup {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text(viewModel.statusMessage)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                }
            }
        }
    }
    
    private var systemHealthSection: some View {
        Section("System Status") {
            HStack {
                Image(systemName: viewModel.systemStatusIcon)
                    .foregroundColor(viewModel.systemStatusColor)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Auto-Backup System")
                        .font(.subheadline)
                    
                    Text(viewModel.systemHealthSummary)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("Details") {
                    viewModel.showDiagnostics()
                }
                .font(.caption)
                .buttonStyle(.bordered)
                .buttonBorderShape(.capsule)
                .controlSize(.mini)
            }
            
            if !viewModel.statusMessage.isEmpty {
                Text(viewModel.statusMessage)
                    .font(.caption)
                    .foregroundColor(.blue)
            }
        }
    }
    
    private var troubleshootingSection: some View {
        Section("Troubleshooting") {
            Button("Restart System") {
                viewModel.restartSystem()
            }
            .disabled(!viewModel.canPerformOperations)
            
            if viewModel.isRestartingSystem {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Restarting system...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
            
            Button("Reset to Defaults") {
                viewModel.resetToDefaults()
            }
            .disabled(!viewModel.canPerformOperations)
            
            Text("Use these options if auto-backup isn't working properly. Restart system will refresh timers and connections.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - System Diagnostics View

struct SystemDiagnosticsView: View {
    let diagnostics: AutoBackupDiagnostics?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                if let diagnostics = diagnostics {
                    Section("System Status") {
                        HStack {
                            Image(systemName: diagnostics.status.icon)
                                .foregroundColor(diagnostics.status.color)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(diagnostics.status.displayName)
                                    .font(.headline)
                                
                                Text("Last checked: \(diagnostics.lastValidated, style: .time)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                    }
                    
                    if !diagnostics.issues.isEmpty {
                        Section("Issues") {
                            ForEach(diagnostics.issues, id: \.self) { issue in
                                Label(issue, systemImage: "xmark.circle")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    
                    if !diagnostics.warnings.isEmpty {
                        Section("Warnings") {
                            ForEach(diagnostics.warnings, id: \.self) { warning in
                                Label(warning, systemImage: "exclamationmark.triangle")
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                    
                    if !diagnostics.info.isEmpty {
                        Section("Information") {
                            ForEach(diagnostics.info, id: \.self) { info in
                                Label(info, systemImage: "info.circle")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                } else {
                    Section {
                        Text("No diagnostics available")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("System Diagnostics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

// MARK: - Extensions

extension AutoBackupSystemStatus {
    var icon: String {
        switch self {
        case .healthy: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .error: return "xmark.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .healthy: return .green
        case .warning: return .orange
        case .error: return .red
        }
    }
    
    var displayName: String {
        switch self {
        case .healthy: return "Healthy"
        case .warning: return "Warning"
        case .error: return "Error"
        }
    }
}

#Preview {
    AutoBackupSettingsView(viewModel: AutoBackupSettingsViewModel(
        autoBackupService: AutoBackupService(modelContext: ModelContext(.preview))
    ))
}