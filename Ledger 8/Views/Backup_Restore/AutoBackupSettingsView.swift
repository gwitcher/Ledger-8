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
    
    @State private var autoBackupEnabled: Bool
    @State private var autoBackupFrequency: AutoBackupFrequency
    @State private var maxBackupsToKeep: Double
    @State private var showingBackupsList = false
    @State private var showingDiagnostics = false
    
    init(backupManager: ComprehensiveBackupManager) {
        self.backupManager = backupManager
        self._autoBackupEnabled = State(initialValue: backupManager.autoBackupEnabled)
        self._autoBackupFrequency = State(initialValue: backupManager.autoBackupFrequency)
        self._maxBackupsToKeep = State(initialValue: Double(backupManager.maxBackupsToKeep))
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
                        saveSettings()
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingBackupsList) {
                AutoBackupListView(backupManager: backupManager)
            }
            .sheet(isPresented: $showingDiagnostics) {
                AutoBackupDiagnosticsView(backupManager: backupManager)
            }
        }
    }
    
    private var autoBackupSection: some View {
        Section {
            Toggle("Enable Auto-Backup", isOn: $autoBackupEnabled)
                .tint(.blue)
            
            if autoBackupEnabled {
                Picker("Frequency", selection: $autoBackupFrequency) {
                    ForEach(AutoBackupFrequency.allCases, id: \.self) { frequency in
                        if frequency != .never {
                            Text(frequency.displayName).tag(frequency)
                        }
                    }
                }
                .pickerStyle(.menu)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Keep \(Int(maxBackupsToKeep)) backups")
                        .font(.subheadline)
                    
                    Slider(value: $maxBackupsToKeep, in: 3...20, step: 1)
                        .tint(.blue)
                }
                .padding(.vertical, 4)
            }
            
            if let lastBackup = backupManager.lastAutoBackupDate {
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
            if autoBackupEnabled {
                Text("Auto-backups are saved to Files > Ledger 8 > Backups > Auto and are triggered when you close the app or based on the frequency you select.")
            }
        }
    }
    
    private var backupHistorySection: some View {
        Section {
            Button(action: { showingBackupsList = true }) {
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
            
            Button(action: { showingDiagnostics = true }) {
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
    
    private func saveSettings() {
        backupManager.updateAutoBackupSettings(
            enabled: autoBackupEnabled,
            frequency: autoBackupFrequency,
            maxBackups: Int(maxBackupsToKeep)
        )
    }
}

#Preview {
    let container = try! ModelContainer(for: Project.self, Client.self, Item.self, Invoice.self)
    let backupManager = ComprehensiveBackupManager(modelContext: container.mainContext)
    
    AutoBackupSettingsView(backupManager: backupManager)
}
