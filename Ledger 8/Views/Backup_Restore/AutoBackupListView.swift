//
//  AutoBackupListView.swift
//  Ledger 8
//
//  View for displaying the list of auto-backup files
//

import SwiftUI
import SwiftData
import Foundation

struct AutoBackupListView: View {
    @ObservedObject var backupManager: ComprehensiveBackupManager
    @Environment(\.dismiss) private var dismiss
    @State private var backupFiles: [AutoBackupInfo] = []
    @State private var showingShareSheet = false
    @State private var selectedBackup: AutoBackupInfo?
    
    var body: some View {
        NavigationStack {
            List {
                if backupFiles.isEmpty {
                    ContentUnavailableView(
                        "No Auto-Backups Found",
                        systemImage: "clock.arrow.circlepath",
                        description: Text("Auto-backups will appear here when they are created")
                    )
                } else {
                    ForEach(backupFiles, id: \.fileName) { backup in
                        backupRow(backup)
                    }
                }
            }
            .navigationTitle("Auto-Backup History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .refreshable {
                loadBackupFiles()
            }
            .sheet(isPresented: $showingShareSheet) {
                if let backup = selectedBackup {
                    ShareSheet(activityItems: [backup.url])
                }
            }
        }
        .onAppear {
            loadBackupFiles()
        }
    }
    
    private func backupRow(_ backup: AutoBackupInfo) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Auto-Backup")
                        .font(.headline)
                    Text(backup.formattedDate)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(backup.formattedFileSize)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Button(action: {
                        selectedBackup = backup
                        showingShareSheet = true
                    }) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.caption)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func loadBackupFiles() {
        backupFiles = backupManager.getAutoBackupFiles()
    }
}

#Preview {
    let container = try! ModelContainer(for: Project.self, Client.self, Item.self, Invoice.self)
    let backupManager = ComprehensiveBackupManager(modelContext: container.mainContext)
    
    AutoBackupListView(backupManager: backupManager)
}