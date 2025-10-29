//
//  BackupManagementView.swift
//  Ledger 8
//
//  Created by MVVM Refactoring on 10/29/25.
//

import SwiftUI
import SwiftData

/// Complete backup management view demonstrating the new MVVM architecture
/// This replaces direct usage of ComprehensiveBackupManager
struct BackupManagementView: View {
    @Environment(\.modelContext) private var modelContext
    
    // MARK: - New MVVM Architecture
    @State private var backupCoordinator: BackupCoordinator?
    @State private var backupOperationsVM: BackupOperationsViewModel?
    @State private var autoBackupSettingsVM: AutoBackupSettingsViewModel?
    @State private var backupListVM: BackupListViewModel?
    
    // MARK: - UI State
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Backup Operations Tab
            backupOperationsTab
                .tabItem {
                    Image(systemName: "square.and.arrow.up")
                    Text("Backup")
                }
                .tag(0)
            
            // Auto-Backup Settings Tab
            autoBackupSettingsTab
                .tabItem {
                    Image(systemName: "gear")
                    Text("Auto-Backup")
                }
                .tag(1)
            
            // Backup Files Tab
            backupFilesTab
                .tabItem {
                    Image(systemName: "folder")
                    Text("Files")
                }
                .tag(2)
        }
        .onAppear {
            setupViewModels()
        }
        .onChange(of: modelContext) { _, newContext in
            backupCoordinator?.updateModelContext(newContext)
        }
    }
    
    // MARK: - Tab Views
    
    private var backupOperationsTab: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if let viewModel = backupOperationsVM {
                    BackupOperationsSection(viewModel: viewModel)
                } else {
                    ProgressView("Loading...")
                }
            }
            .navigationTitle("Backup Operations")
            .padding()
        }
    }
    
    private var autoBackupSettingsTab: some View {
        NavigationStack {
            if let viewModel = autoBackupSettingsVM {
                AutoBackupSettingsView(viewModel: viewModel)
            } else {
                ProgressView("Loading...")
            }
        }
    }
    
    private var backupFilesTab: some View {
        NavigationStack {
            if let viewModel = backupListVM {
                BackupFilesListView(viewModel: viewModel)
            } else {
                ProgressView("Loading...")
            }
        }
    }
    
    // MARK: - Setup
    
    private func setupViewModels() {
        if backupCoordinator == nil {
            backupCoordinator = BackupCoordinator(modelContext: modelContext)
            backupOperationsVM = backupCoordinator?.createBackupOperationsViewModel()
            autoBackupSettingsVM = backupCoordinator?.createAutoBackupSettingsViewModel()
            backupListVM = backupCoordinator?.createBackupListViewModel()
        }
    }
}

// MARK: - Backup Operations Section

struct BackupOperationsSection: View {
    @Bindable var viewModel: BackupOperationsViewModel
    
    @State private var showingFilePicker = false
    @State private var showingShareSheet = false
    @State private var replaceExistingData = false
    
    var body: some View {
        VStack(spacing: 24) {
            // Status Section
            statusSection
            
            // Create Backup Section
            createBackupSection
            
            // Restore Backup Section  
            restoreBackupSection
            
            // Validation Section
            validationSection
        }
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.json, .data],
            allowsMultipleSelection: false
        ) { result in
            handleFileImport(result)
        }
        .sheet(isPresented: $showingShareSheet) {
            if let url = viewModel.shareBackup() {
                ShareSheet(activityItems: [url])
            }
        }
        .alert("Error", isPresented: .constant(viewModel.hasError)) {
            Button("OK") {
                viewModel.clearError()
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
    
    private var statusSection: some View {
        VStack(spacing: 12) {
            if viewModel.shouldShowProgress {
                VStack(spacing: 8) {
                    Text(viewModel.operationInProgress ?? "Processing...")
                        .font(.headline)
                        .foregroundColor(viewModel.statusColor)
                    
                    ProgressView(value: viewModel.progress)
                        .progressViewStyle(LinearProgressViewStyle(tint: viewModel.statusColor))
                    
                    Text(viewModel.statusMessage)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            } else if !viewModel.statusMessage.isEmpty {
                Text(viewModel.statusMessage)
                    .font(.subheadline)
                    .foregroundColor(viewModel.statusColor)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(minHeight: 60)
    }
    
    private var createBackupSection: some View {
        GroupBox("Create Backup") {
            VStack(spacing: 12) {
                Button("Create Complete Backup") {
                    Task {
                        await viewModel.createBackup()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(!viewModel.canPerformOperations)
                
                if viewModel.canShareBackup {
                    Button("Share Last Backup") {
                        showingShareSheet = true
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
    }
    
    private var restoreBackupSection: some View {
        GroupBox("Restore Backup") {
            VStack(spacing: 12) {
                Toggle("Replace Existing Data", isOn: $replaceExistingData)
                    .toggleStyle(SwitchToggleStyle())
                
                Button("Choose Backup File") {
                    showingFilePicker = true
                }
                .buttonStyle(.bordered)
                .disabled(!viewModel.canPerformOperations)
                
                if replaceExistingData {
                    Text("⚠️ This will delete all existing data")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
        }
    }
    
    private var validationSection: some View {
        GroupBox("Validation") {
            VStack(spacing: 12) {
                Toggle("Skip Checksum Validation", isOn: $viewModel.skipChecksumValidation)
                    .toggleStyle(SwitchToggleStyle())
                
                if viewModel.shouldShowValidationResults {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Last Validation:")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text(viewModel.validationSummary ?? "No results")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        ForEach(viewModel.validationDetails, id: \.self) { detail in
                            Text(detail)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }
    
    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let files):
            if let file = files.first {
                Task {
                    await viewModel.restoreBackup(from: file, replaceExisting: replaceExistingData)
                }
            }
        case .failure(let error):
            viewModel.errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Backup Files List View

struct BackupFilesListView: View {
    @Bindable var viewModel: BackupListViewModel
    
    var body: some View {
        List {
            // Auto Backups Section
            if !viewModel.filteredAutoBackups.isEmpty {
                Section(viewModel.autoBackupsSectionHeader) {
                    ForEach(viewModel.filteredAutoBackups, id: \.fileName) { backup in
                        AutoBackupRow(backup: backup) {
                            Task {
                                await viewModel.deleteAutoBackup(backup)
                            }
                        }
                    }
                }
            }
            
            // Manual Backups Section
            if !viewModel.filteredManualBackups.isEmpty {
                Section(viewModel.manualBackupsSectionHeader) {
                    ForEach(viewModel.filteredManualBackups, id: \.fileName) { backup in
                        BackupFileRow(backup: backup) {
                            viewModel.selectBackup(backup)
                        } onDelete: {
                            Task {
                                await viewModel.deleteBackup(backup)
                            }
                        }
                    }
                }
            }
            
            // Empty State
            if !viewModel.hasBackups {
                Section {
                    Text("No backups found")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
        .searchable(text: $viewModel.searchText)
        .refreshable {
            await viewModel.refreshBackups()
        }
        .navigationTitle("Backup Files")
        .alert("Error", isPresented: .constant(viewModel.hasError)) {
            Button("OK") {
                viewModel.clearError()
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .confirmationDialog(
            "Delete Backup",
            isPresented: $viewModel.showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let backup = viewModel.selectedBackup {
                    Task {
                        await viewModel.deleteBackup(backup)
                    }
                }
            }
            Button("Cancel", role: .cancel) {
                viewModel.dismissDeleteConfirmation()
            }
        } message: {
            Text("Are you sure you want to delete this backup? This action cannot be undone.")
        }
        .sheet(isPresented: $viewModel.showingBackupDetails) {
            if let backup = viewModel.selectedBackup {
                BackupDetailsView(backup: backup, viewModel: viewModel)
            }
        }
    }
}

// MARK: - Backup Row Views

struct AutoBackupRow: View {
    let backup: AutoBackupInfo
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(backup.fileName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Button("Delete") {
                    onDelete()
                }
                .font(.caption)
                .foregroundColor(.red)
            }
            
            HStack {
                Text(backup.formattedFileSize)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(backup.relativeDate)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct BackupFileRow: View {
    let backup: BackupFileInfo
    let onTap: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(backup.fileName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    if backup.isAutoBackup {
                        Text("Auto")
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.2))
                            .foregroundColor(.blue)
                            .clipShape(Capsule())
                    }
                }
                
                HStack {
                    Text(backup.formattedFileSize)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(backup.relativeDate)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button("Delete", role: .destructive) {
                onDelete()
            }
        }
    }
}

// MARK: - Backup Details View

struct BackupDetailsView: View {
    let backup: BackupFileInfo
    let viewModel: BackupListViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var details: BackupDetailsInfo?
    @State private var isLoading = true
    
    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Loading backup details...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let details = details {
                    List {
                        Section("File Information") {
                            DetailRow(label: "Name", value: backup.fileName)
                            DetailRow(label: "Size", value: backup.formattedFileSize)
                            DetailRow(label: "Created", value: backup.formattedDate)
                            DetailRow(label: "Type", value: backup.isAutoBackup ? "Automatic" : "Manual")
                        }
                        
                        Section("Backup Contents") {
                            DetailRow(label: "Clients", value: "\(details.clientsCount)")
                            DetailRow(label: "Projects", value: "\(details.projectsCount)")
                            DetailRow(label: "Items", value: "\(details.itemsCount)")
                            DetailRow(label: "Invoices", value: "\(details.invoicesCount)")
                        }
                        
                        Section("Metadata") {
                            DetailRow(label: "App Version", value: details.metadata.appVersion)
                            DetailRow(label: "Backup Version", value: details.metadata.backupVersion)
                            DetailRow(label: "Has Integrity Data", value: details.hasIntegrityData ? "Yes" : "No")
                        }
                    }
                } else {
                    Text("Failed to load backup details")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle("Backup Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .task {
            details = await viewModel.getBackupDetails(backup)
            isLoading = false
        }
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .fontWeight(.medium)
        }
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
    BackupManagementView()
}