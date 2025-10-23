////
////  BackupView.swift
////  Ledger 8
////
////  Created by Backup System
////
//
//import SwiftUI
//import SwiftData
//import UniformTypeIdentifiers
//
//struct BackupView: View {
//    @Environment(\.modelContext) private var modelContext
//    @Environment(\.dismiss) private var dismiss
//    @StateObject private var backupManager: BackupManager
//    @State private var showingFilePicker = false
//    @State private var showingShareSheet = false
//    @State private var showingDeleteConfirmation = false
//    @State private var backupFileURL: URL?
//    @State private var replaceExistingData = false
//    
//    init() {
//        // Initialize with a temporary context - will be updated in onAppear
//        let container = try! ModelContainer(for: Project.self, Client.self, Item.self)
//        self._backupManager = StateObject(wrappedValue: BackupManager(modelContext: container.mainContext))
//    }
//    
//    var body: some View {
//        NavigationStack {
//            List {
//                backupSection
//                restoreSection
//                dangerZone
//            }
//            .navigationTitle("Backup & Restore")
//            .navigationBarTitleDisplayMode(.inline)
//            .toolbar {
//                ToolbarItem(placement: .topBarTrailing) {
//                    Button("Done") {
//                        dismiss()
//                    }
//                }
//            }
//            .alert("Error", isPresented: .constant(backupManager.errorMessage != nil)) {
//                Button("OK") {
//                    backupManager.errorMessage = nil
//                }
//            } message: {
//                Text(backupManager.errorMessage ?? "")
//            }
//            .confirmationDialog("Delete All Data", 
//                              isPresented: $showingDeleteConfirmation,
//                              titleVisibility: .visible) {
//                Button("Delete All Data", role: .destructive) {
//                    Task {
//                        await deleteAllData()
//                    }
//                }
//                Button("Cancel", role: .cancel) { }
//            } message: {
//                Text("This will permanently delete all projects, clients, and items. This action cannot be undone.")
//            }
//            .fileImporter(
//                isPresented: $showingFilePicker,
//                allowedContentTypes: [.json],
//                allowsMultipleSelection: false
//            ) { result in
//                handleFileImport(result)
//            }
//            .sheet(isPresented: $showingShareSheet) {
//                if let url = backupFileURL {
//                    ShareSheet(activityItems: [url])
//                }
//            }
//        }
//        .onAppear {
//            backupManager.updateModelContext(modelContext)
//        }
//    }
//    
//    private var backupSection: some View {
//        Section("Create Backup") {
//            VStack(alignment: .leading, spacing: 8) {
//                Text("Export all your data to a JSON backup file")
//                    .font(.subheadline)
//                    .foregroundColor(.secondary)
//                
//                Button(action: createBackup) {
//                    HStack {
//                        Image(systemName: "square.and.arrow.up")
//                        Text("Create Backup File")
//                        Spacer()
//                        if backupManager.isBackingUp {
//                            ProgressView()
//                                .scaleEffect(0.8)
//                        }
//                    }
//                }
//                .disabled(backupManager.isBackingUp || backupManager.isRestoring)
//                
//                if backupManager.isBackingUp {
//                    ProgressView(value: backupManager.progress)
//                    Text(backupManager.statusMessage)
//                        .font(.caption)
//                        .foregroundColor(.secondary)
//                }
//            }
//            .padding(.vertical, 4)
//        }
//    }
//    
//    private var restoreSection: some View {
//        Section("Restore from Backup") {
//            VStack(alignment: .leading, spacing: 8) {
//                Text("Import data from a JSON backup file")
//                    .font(.subheadline)
//                    .foregroundColor(.secondary)
//                
//                Button(action: { showingFilePicker = true }) {
//                    HStack {
//                        Image(systemName: "square.and.arrow.down")
//                        Text("Choose Backup File")
//                        Spacer()
//                        if backupManager.isRestoring {
//                            ProgressView()
//                                .scaleEffect(0.8)
//                        }
//                    }
//                }
//                .disabled(backupManager.isBackingUp || backupManager.isRestoring)
//                
//                Toggle("Replace existing data", isOn: $replaceExistingData)
//                    .font(.subheadline)
//                
//                Text("When enabled, all current data will be deleted before restoring the backup")
//                    .font(.caption)
//                    .foregroundColor(.secondary)
//                
//                if backupManager.isRestoring {
//                    ProgressView(value: backupManager.progress)
//                    Text(backupManager.statusMessage)
//                        .font(.caption)
//                        .foregroundColor(.secondary)
//                }
//            }
//            .padding(.vertical, 4)
//        }
//    }
//    
//    private var dangerZone: some View {
//        Section("Danger Zone") {
//            Button(action: { showingDeleteConfirmation = true }) {
//                HStack {
//                    Image(systemName: "trash")
//                        .foregroundColor(.red)
//                    Text("Delete All Data")
//                        .foregroundColor(.red)
//                }
//            }
//            .disabled(backupManager.isBackingUp || backupManager.isRestoring)
//        }
//    }
//    
//    // MARK: - Actions
//    
//    private func createBackup() {
//        Task {
//            do {
//                let fileURL = try await backupManager.createBackupFile()
//                await MainActor.run {
//                    backupFileURL = fileURL
//                    showingShareSheet = true
//                }
//            } catch {
//                await MainActor.run {
//                    backupManager.errorMessage = error.localizedDescription
//                }
//            }
//        }
//    }
//    
//    private func handleFileImport(_ result: Result<[URL], Error>) {
//        switch result {
//        case .success(let files):
//            if let file = files.first {
//                restoreFromBackup(fileURL: file)
//            }
//        case .failure(let error):
//            backupManager.errorMessage = error.localizedDescription
//        }
//    }
//    
//    private func restoreFromBackup(fileURL: URL) {
//        Task {
//            do {
//                try await backupManager.restoreFromBackup(
//                    fileURL: fileURL,
//                    replaceExisting: replaceExistingData
//                )
//            } catch {
//                await MainActor.run {
//                    backupManager.errorMessage = error.localizedDescription
//                }
//            }
//        }
//    }
//    
//    private func deleteAllData() async {
//        do {
//            try await backupManager.clearAllData()
//        } catch {
//            await MainActor.run {
//                backupManager.errorMessage = error.localizedDescription
//            }
//        }
//    }
//}
//
//// MARK: - Share Sheet
//
//struct ShareSheet: UIViewControllerRepresentable {
//    let activityItems: [Any]
//    
//    func makeUIViewController(context: Context) -> UIActivityViewController {
//        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
//    }
//    
//    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
//}
//
//#Preview {
//    BackupView()
//}
