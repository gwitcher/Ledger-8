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
    @State private var backupCoordinator: BackupCoordinator?
    @State private var backupViewModel: BackupViewModel?
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
            .alert("Error", isPresented: .constant(backupViewModel?.errorMessage != nil)) {
                Button("OK") {
                    backupViewModel?.clearError()
                }
            } message: {
                Text(backupViewModel?.errorMessage ?? "")
            }
            .alert("Success", isPresented: $showingSuccessAlert) {
                
                Button("OK") {
                    // Only show share sheet for backup creation, not for restore or delete
                    if backupFileURL != nil && successMessage.contains("backup created") {
                        showingShareSheet = true
                    }
                }
                
                Button("Dismiss") {
                    dismiss()
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
                if let viewModel = backupViewModel {
                    AutoBackupSettingsView(backupViewModel: viewModel)
                }
            }
            .sheet(isPresented: $showingBackupInfo) {
                if let viewModel = backupViewModel {
                    BackupInfoSheet(backupViewModel: viewModel)
                }
            }
            .sheet(isPresented: $showingRestoreInfo) {
                RestoreInfoSheet()
            }
        }
        .onAppear {
            if backupCoordinator == nil {
                backupCoordinator = BackupCoordinator(modelContext: modelContext)
                backupViewModel = backupCoordinator?.createBackupOperationsViewModel()
            } else {
                backupCoordinator?.updateModelContext(modelContext)
            }
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
                    
                    Text(backupViewModel?.autoBackupEnabled == true ? "Enabled" : "Disabled")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(backupViewModel?.autoBackupEnabled == true ? .green : .orange)
                    
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
                        if backupViewModel?.isBackingUp == true {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                    }
                }
                .disabled(backupViewModel?.isBackingUp == true || backupViewModel?.isRestoring == true)
                
                if backupFileURL != nil && backupViewModel?.isBackingUp != true {
                    Button(action: { showingShareSheet = true }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share Last Backup")
                            Spacer()
                        }
                    }
                    .foregroundColor(.blue)
                }
                
                if backupViewModel?.isBackingUp == true {
                    VStack(spacing: 8) {
                        ProgressView(value: backupViewModel?.progress) {
                            Text("Creating backup...")
                        }
                        .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                        
                        Text(backupViewModel?.statusMessage ?? "")
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
                        if backupViewModel?.isRestoring == true {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                    }
                }
                .disabled(backupViewModel?.isBackingUp == true || backupViewModel?.isRestoring == true)
                
                Toggle("Replace ALL existing data", isOn: $replaceExistingData)
                    .font(.subheadline)
                
                if backupViewModel?.isRestoring == true {
                    VStack(spacing: 8) {
                        ProgressView(value: backupViewModel?.progress) {
                            Text(replaceExistingData ? "Replacing all data..." : "Importing data...")
                        }
                        .progressViewStyle(LinearProgressViewStyle(tint: .green))
                        
                        Text(backupViewModel?.statusMessage ?? "")
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
            .disabled(backupViewModel?.isBackingUp == true || backupViewModel?.isRestoring == true)
            
            Text("This will delete everything including settings, making the app like a fresh install.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Actions
    
    private func createCompleteBackup() {
        guard let viewModel = backupViewModel else { return }
        
        Task {
            await viewModel.createCompleteBackup()
            
            // Handle success/error at completion
            await MainActor.run {
                if let error = viewModel.errorMessage {
                    print("Backup creation error: \(error)")
                } else {
                    let fileExists = backupFileURL != nil
                    print("Backup completed successfully")
                    
                    if fileExists {
                        self.successMessage = """
                        Complete backup created successfully!
                        
                        Saved to: Files > Browse > Ledger 8 > Backups
                        Your invoices are in: Files > Browse > Ledger 8 > Invoices
                        
                        Tap OK to share the backup file.
                        """
                    } else {
                        self.successMessage = "Complete backup created successfully!\n\nTap OK to share the backup file."
                    }
                    
                    self.showingSuccessAlert = true
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
        guard let viewModel = backupViewModel else { return }
        
        Task {
            await viewModel.restoreCompleteBackup(fileURL: fileURL, replaceExisting: replaceExistingData)
            
            await MainActor.run {
                if let error = viewModel.errorMessage {
                    // Error is already set in viewModel, UI will show it
                    print("Restore error: \(error)")
                } else {
                    successMessage = replaceExistingData ?
                        "Complete restore successful! All data has been replaced." :
                        "Complete restore successful! Data has been imported."
                    showingSuccessAlert = true
                }
            }
        }
    }
    
    private func deleteAllData() async {
        guard let backupService = backupCoordinator?.backupService else { return }
        
        do {
            try await backupService.clearAllData()
            await MainActor.run {
                successMessage = "All app data has been successfully deleted."
                showingSuccessAlert = true
            }
        } catch {
            await MainActor.run {
                backupViewModel?.errorMessage = error.localizedDescription
            }
        }
    }
}

// MARK: - Info Sheets

struct BackupInfoSheet: View {
    let backupViewModel: BackupViewModel
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
                                Text(backupViewModel.autoBackupEnabled ? "Enabled" : "Disabled")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(backupViewModel.autoBackupEnabled ? .green : .orange)
                            }
                            
                            if backupViewModel.autoBackupEnabled {
                                HStack {
                                    Text("Frequency:")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text(backupViewModel.autoBackupFrequency.displayName)
                                        .font(.subheadline)
                                        .foregroundColor(.primary)
                                }
                                
                                HStack {
                                    Text("Last backup:")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    if let lastBackup = backupViewModel.lastAutoBackupDate {
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

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}


#Preview {
    CompleteBackupView()
}
