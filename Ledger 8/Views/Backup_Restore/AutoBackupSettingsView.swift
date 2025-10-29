//
//  AutoBackupSettingsView.swift
//  Ledger 8
//
//  Created by Backup System
//

import SwiftUI
import SwiftData

struct AutoBackupSettingsView: View {
    @ObservedObject var backupManager: ComprehensiveBackupManager
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: AutoBackupSettingsViewModel
    
    init(backupManager: ComprehensiveBackupManager) {
        self.backupManager = backupManager
        self._viewModel = State(initialValue: AutoBackupSettingsViewModel(backupManager: backupManager))
    }
    
    var body: some View {
        NavigationStack {
            List {
                autoBackupSection
                backupHistorySection
                backupInfoSection
            }
            .navigationTitle("Auto-Backup Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        viewModel.saveSettings()
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $viewModel.showingBackupsList) {
                AutoBackupListView(backupManager: backupManager)
            }
            .sheet(isPresented: $viewModel.showingDiagnostics) {
                AutoBackupDiagnosticsView(backupManager: backupManager)
            }
        }
    }
    
    private var autoBackupSection: some View {
        Section {
            Toggle("Enable Auto-Backup", isOn: $viewModel.autoBackupEnabled)
                .tint(.blue)
            
            if viewModel.shouldShowFrequencyPicker {
                Picker("Frequency", selection: $viewModel.autoBackupFrequency) {
                    ForEach(viewModel.getFrequencyOptions(), id: \.self) { frequency in
                        Text(frequency.displayName).tag(frequency)
                    }
                }
                .pickerStyle(.menu)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(viewModel.maxBackupsDisplayText)
                        .font(.subheadline)
                    
                    Slider(value: $viewModel.maxBackupsToKeep, in: 3...20, step: 1)
                        .tint(.blue)
                }
                .padding(.vertical, 4)
            }
            
            if let lastBackup = viewModel.lastAutoBackupDate {
                HStack {
                    Text("Last Auto-Backup")
                    Spacer()
                    Text(lastBackup, style: .relative)
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            }
        } header: {
            Text("Automatic Backups")
        } footer: {
            if !viewModel.footerText.isEmpty {
                Text(viewModel.footerText)
            }
        }
    }
    
    private var backupHistorySection: some View {
        Section {
            Button(action: { viewModel.showBackupsList() }) {
                HStack {
                    Image(systemName: "clock.arrow.circlepath")
                        .foregroundColor(.blue)
                    Text("View Auto-Backup History")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .foregroundColor(.primary)
            
            Button(action: { viewModel.showDiagnostics() }) {
                HStack {
                    Image(systemName: "stethoscope")
                        .foregroundColor(.orange)
                    Text("System Diagnostics")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .foregroundColor(.primary)
        } header: {
            Text("Backup History")
        }
    }
    
    private var backupInfoSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(.blue)
                    Text("How Auto-Backup Works")
                        .font(.headline)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Label("Automatic backups happen in the background", systemImage: "clock")
                    Label("Triggered when you close the app", systemImage: "app.badge")
                    Label("Also runs on your selected schedule", systemImage: "calendar")
                    Label("Older backups are cleaned up automatically", systemImage: "trash")
                    Label("Manual backups are kept separately", systemImage: "hand.raised")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
        }
    }
}

#Preview {
    let container = try! ModelContainer(for: Project.self, Client.self, Item.self, Invoice.self)
    let backupManager = ComprehensiveBackupManager(modelContext: container.mainContext)
    
    AutoBackupSettingsView(backupManager: backupManager)
}
