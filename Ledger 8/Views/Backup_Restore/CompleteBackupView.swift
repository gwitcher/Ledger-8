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
                allowedContentTypes: [.json],
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
        }
        .onAppear {
            backupManager.updateModelContext(modelContext)
        }
    }
    
    private var backupInfoSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "shield.checkered")
                        .foregroundColor(.blue)
                    Text("Complete App Backup")
                        .font(.headline)
                }
                
                Text("This backup includes:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                VStack(alignment: .leading, spacing: 4) {
                    Label("User settings & company info", systemImage: "person.circle")
                    Label("All clients and contact information", systemImage: "person.2")
                    Label("All projects with locations", systemImage: "folder")
                    Label("All items and fees", systemImage: "list.bullet")
                    Label("Invoice numbers and references", systemImage: "doc.text")
                    Label("App preferences", systemImage: "gear")
                }
                .font(.caption)
                .foregroundColor(.secondary)
                
                Divider()
                    .padding(.vertical, 4)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("📁 File Organization:")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    Text("• Backups saved to: Files > Ledger 8 > Backups")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("• Invoices saved to: Files > Ledger 8 > Invoices")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
    }
    
    private var backupSection: some View {
        Section("Create Complete Backup") {
            VStack(alignment: .leading, spacing: 8) {
                Text("Export ALL your app data to a JSON file")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Button(action: createCompleteBackup) {
                    HStack {
                        Image(systemName: "square.and.arrow.up.fill")
                        Text("Create Complete Backup")
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
        Section("Restore Complete Backup") {
            VStack(alignment: .leading, spacing: 8) {
                Text("Import ALL data from a complete backup file")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Button(action: { showingFilePicker = true }) {
                    HStack {
                        Image(systemName: "square.and.arrow.down.fill")
                        Text("Choose Complete Backup")
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
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("⚠️ When enabled, ALL current data will be deleted:")
                        .font(.caption)
                        .foregroundColor(.orange)
                    
                    Text("• App settings and user info\n• All projects, clients, and items\n• Invoice data and locations\n• All app preferences")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
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



#Preview {
    CompleteBackupView()
}