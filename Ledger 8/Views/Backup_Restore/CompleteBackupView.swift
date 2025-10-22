//
//  CompleteBackupView.swift
//  Ledger 8
//
//  Created by Backup System
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct CompleteBackupView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @StateObject private var backupManager: ComprehensiveBackupManager
    @State private var showingFilePicker = false
    @State private var showingShareSheet = false
    @State private var showingDeleteConfirmation = false
    @State private var showingSuccessAlert = false
    @State private var successMessage = ""
    @State private var backupFileURL: URL?
    @State private var replaceExistingData = false
    @State private var showingAutoBackupSettings = false
    @State private var showingBackupInfo = false
    @State private var showingRestoreInfo = false
    
    init() {
        // Initialize with a temporary context - will be updated in onAppear
        let container = try! ModelContainer(for: Project.self, Client.self, Item.self, Invoice.self)
        self._backupManager = StateObject(wrappedValue: ComprehensiveBackupManager(modelContext: container.mainContext))
    }
    
    var body: some View {
        NavigationStack {
            List {
                backupInfoSection
                backupSection
                restoreSection
                dangerZone
            }
            .navigationTitle("Complete Backup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { showingAutoBackupSettings = true }) {
                        Image(systemName: "gear")
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: .constant(backupManager.errorMessage != nil)) {
                Button("OK") {
                    backupManager.errorMessage = nil
                }
            } message: {
                Text(backupManager.errorMessage ?? "")
            }
            .alert("Success", isPresented: $showingSuccessAlert) {
                Button("OK") {
                    // Only show share sheet for backup creation, not for restore or delete
                    if backupFileURL != nil && successMessage.contains("backup created") {
                        showingShareSheet = true
                    }
                }
            } message: {
                Text(successMessage)
            }
            .confirmationDialog("Delete All Data", 
                              isPresented: $showingDeleteConfirmation,
                              titleVisibility: .visible) {
                Button("Delete All Data", role: .destructive) {
                    Task {
                        await deleteAllData()
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will permanently delete ALL data including settings, projects, clients, items, invoices, and locations. This action cannot be undone.")
            }
            .fileImporter(
                isPresented: $showingFilePicker,
                allowedContentTypes: [.json, .data], // Accept JSON and any data files
                allowsMultipleSelection: false
            ) { result in
                handleFileImport(result)
            }
            .sheet(isPresented: $showingShareSheet) {
                if let url = backupFileURL {
                    ShareSheet(activityItems: [url])
                        .onAppear {
                            print("Share sheet appearing with URL: \(url.path)")
                            print("File exists at share time: \(FileManager.default.fileExists(atPath: url.path))")
                        }
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.orange)
                        
                        Text("No backup file available")
                            .font(.headline)
                        
                        Text("Please create a backup first")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Button("Close") {
                            showingShareSheet = false
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                    .presentationDetents([.medium])
                }
            }
            .sheet(isPresented: $showingAutoBackupSettings) {
                AutoBackupSettingsView(backupManager: backupManager)
            }
            .sheet(isPresented: $showingBackupInfo) {
                BackupInfoSheet(backupManager: backupManager)
            }
            .sheet(isPresented: $showingRestoreInfo) {
                RestoreInfoSheet()
            }
        }
        .onAppear {
            backupManager.updateModelContext(modelContext)
        }
    }
    
    private var backupInfoSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "shield.checkered")
                        .foregroundColor(.blue)
                    Text("Complete App Backup")
                        .font(.headline)
                    
                    Spacer()
                    
                    Button(action: { showingBackupInfo = true }) {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(.plain)
                    .contentShape(Circle())
                }
                
                Text("Back up and restore all your app data")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack {
                    Text("Auto-Backup:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(backupManager.autoBackupEnabled ? "Enabled" : "Disabled")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(backupManager.autoBackupEnabled ? .green : .orange)
                    
                    Button("Configure") {
                        showingAutoBackupSettings = true
                    }
                    .font(.caption)
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.capsule)
                    .controlSize(.mini)
                }
            }
            .padding(.vertical, 4)
        }
    }
    
    private var backupSection: some View {
        Section("Create Backup") {
            VStack(alignment: .leading, spacing: 8) {
                Button(action: createCompleteBackup) {
                    HStack {
                        Image(systemName: "square.and.arrow.up.fill")
                        Text("Create Backup")
                        Spacer()
                        if backupManager.isBackingUp {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                    }
                }
                .disabled(backupManager.isBackingUp || backupManager.isRestoring)
                
                if backupFileURL != nil && !backupManager.isBackingUp {
                    Button(action: { showingShareSheet = true }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share Last Backup")
                            Spacer()
                        }
                    }
                    .foregroundColor(.blue)
                }
                
                if backupManager.isBackingUp {
                    VStack(spacing: 8) {
                        ProgressView(value: backupManager.progress) {
                            Text("Creating backup...")
                        }
                        .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                        
                        Text(backupManager.statusMessage)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }
    
    private var restoreSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(replaceExistingData ? "Restore Backup (Replace)" : "Restore Backup (Merge)")
                        .font(.headline)
                    
                    Spacer()
                    
                    Button(action: { showingRestoreInfo = true }) {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(.plain)
                    .contentShape(Circle())
                }
                
                Button(action: { showingFilePicker = true }) {
                    HStack {
                        Image(systemName: "square.and.arrow.down.fill")
                        Text("Choose Backup File")
                        Spacer()
                        if backupManager.isRestoring {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                    }
                }
                .disabled(backupManager.isBackingUp || backupManager.isRestoring)
                
                Toggle("Replace ALL existing data", isOn: $replaceExistingData)
                    .font(.subheadline)
                
                if backupManager.isRestoring {
                    VStack(spacing: 8) {
                        ProgressView(value: backupManager.progress) {
                            Text(replaceExistingData ? "Replacing all data..." : "Importing data...")
                        }
                        .progressViewStyle(LinearProgressViewStyle(tint: .green))
                        
                        Text(backupManager.statusMessage)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }
    
    private var dangerZone: some View {
        Section("Danger Zone") {
            Button(action: { showingDeleteConfirmation = true }) {
                HStack {
                    Image(systemName: "trash.fill")
                        .foregroundColor(.red)
                    Text("Delete All App Data")
                        .foregroundColor(.red)
                }
            }
            .disabled(backupManager.isBackingUp || backupManager.isRestoring)
            
            Text("This will delete everything including settings, making the app like a fresh install.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Actions
    
    private func createCompleteBackup() {
        Task {
            do {
                let fileURL = try await backupManager.createCompleteBackup()
                
                // Verify the file exists and get its size
                await MainActor.run {
                    self.backupFileURL = fileURL
                    
                    let fileExists = FileManager.default.fileExists(atPath: fileURL.path)
                    print("Backup file created at: \(fileURL.path)")
                    print("File exists: \(fileExists)")
                    
                    if fileExists {
                        do {
                            let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
                            let fileSize = attributes[.size] as? Int64 ?? 0
                            print("File size: \(fileSize) bytes")
                            
                            self.successMessage = """
                            Complete backup created successfully!
                            File size: \(ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file))
                            
                            Saved to: Files > Browse > Ledger 8 > Backups
                            Your invoices are in: Files > Browse > Ledger 8 > Invoices
                            
                            Tap OK to share the backup file.
                            """
                        } catch {
                            print("Error getting file attributes: \(error)")
                            self.successMessage = "Complete backup created successfully!\n\nTap OK to share the backup file."
                        }
                    } else {
                        self.successMessage = "Backup created but file verification failed. Please try again."
                    }
                    
                    self.showingSuccessAlert = true
                }
            } catch {
                await MainActor.run {
                    print("Backup creation error: \(error)")
                    backupManager.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let files):
            if let file = files.first {
                // Ensure we can access the file before proceeding
                guard file.startAccessingSecurityScopedResource() else {
                    backupManager.errorMessage = "Unable to access the selected file"
                    return
                }
                
                // Defer stopping access to ensure it happens even if restoration fails
                defer {
                    file.stopAccessingSecurityScopedResource()
                }
                
                restoreCompleteBackup(fileURL: file)
            }
        case .failure(let error):
            backupManager.errorMessage = error.localizedDescription
        }
    }
    
    private func restoreCompleteBackup(fileURL: URL) {
        Task {
            do {
                try await backupManager.restoreCompleteBackup(
                    fileURL: fileURL,
                    replaceExisting: replaceExistingData
                )
                await MainActor.run {
                    successMessage = replaceExistingData ? 
                        "Complete restore successful! All data has been replaced." : 
                        "Complete restore successful! Data has been imported."
                    showingSuccessAlert = true
                }
            } catch {
                await MainActor.run {
                    backupManager.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func deleteAllData() async {
        do {
            try await backupManager.clearAllData()
            await MainActor.run {
                successMessage = "All app data has been successfully deleted."
                showingSuccessAlert = true
            }
        } catch {
            await MainActor.run {
                backupManager.errorMessage = error.localizedDescription
            }
        }
    }
}

// MARK: - Info Sheets

struct BackupInfoSheet: View {
    let backupManager: ComprehensiveBackupManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("What's Included")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Label("User settings & company info", systemImage: "person.circle")
                            Label("All clients and contact information", systemImage: "person.2")
                            Label("All projects with locations", systemImage: "folder")
                            Label("All items and fees", systemImage: "list.bullet")
                            Label("Invoice numbers and references", systemImage: "doc.text")
                            Label("App preferences", systemImage: "gear")
                        }
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    }
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("📁 File Organization")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("• Backups saved to: Files > Ledger 8 > Backups")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text("• Invoices saved to: Files > Ledger 8 > Invoices")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("🤖 Auto-Backup Status")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Status:")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(backupManager.autoBackupEnabled ? "Enabled" : "Disabled")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(backupManager.autoBackupEnabled ? .green : .orange)
                            }
                            
                            if backupManager.autoBackupEnabled {
                                HStack {
                                    Text("Frequency:")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text(backupManager.autoBackupFrequency.displayName)
                                        .font(.subheadline)
                                        .foregroundColor(.primary)
                                }
                                
                                HStack {
                                    Text("Last backup:")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    if let lastBackup = backupManager.lastAutoBackupDate {
                                        Text(lastBackup, style: .relative)
                                            .font(.subheadline)
                                            .foregroundColor(.primary)
                                    } else {
                                        Text("Never")
                                            .font(.subheadline)
                                            .foregroundColor(.orange)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Backup Information")
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

struct RestoreInfoSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("How Restore Works")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("Import data from a complete backup file created by this app.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("⚠️ Replace Existing Data")
                            .font(.headline)
                            .foregroundColor(.orange)
                        
                        Text("When enabled, ALL current data will be permanently deleted and replaced with data from the backup file:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("• App settings and user info")
                            Text("• All projects, clients, and items")
                            Text("• Invoice data and locations")
                            Text("• All app preferences")
                        }
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.leading, 8)
                    }
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("💡 Merge Mode")
                            .font(.headline)
                            .foregroundColor(.blue)
                        
                        Text("When disabled, the backup data will be merged with your existing data. This may result in duplicates if the same items exist in both places.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("📋 Recommendation")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("Create a backup of your current data before restoring, especially when using Replace mode.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
            }
            .navigationTitle("Restore Information")
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


#Preview {
    CompleteBackupView()
}
