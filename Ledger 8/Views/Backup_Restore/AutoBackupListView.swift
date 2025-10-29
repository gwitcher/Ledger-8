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
    @State private var viewModel: AutoBackupListViewModel
    
    init(backupManager: ComprehensiveBackupManager) {
        self.backupManager = backupManager
        self._viewModel = State(initialValue: AutoBackupListViewModel(backupManager: backupManager))
    }
    
    var body: some View {
        NavigationStack {
            List {
                if !viewModel.hasBackupFiles {
                    ContentUnavailableView(
                        viewModel.contentUnavailableTitle,
                        systemImage: viewModel.contentUnavailableSystemImage,
                        description: Text(viewModel.contentUnavailableDescription)
                    )
                } else {
                    ForEach(viewModel.backupFiles, id: \.fileName) { backup in
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
                await viewModel.refreshBackupFiles()
            }
            .sheet(isPresented: $viewModel.showingShareSheet) {
                ShareSheet(activityItems: viewModel.getShareItems())
            }
        }
        .onAppear {
            viewModel.loadBackupFiles()
        }
    }
    
    private func backupRow(_ backup: AutoBackupInfo) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(viewModel.formatBackupTitle(backup))
                        .font(.headline)
                    Text(viewModel.formatBackupDate(backup))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(viewModel.formatBackupFileSize(backup))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Button(action: {
                        viewModel.shareBackup(backup)
                    }) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.caption)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    let container = try! ModelContainer(for: Project.self, Client.self, Item.self, Invoice.self)
    let backupManager = ComprehensiveBackupManager(modelContext: container.mainContext)
    
    AutoBackupListView(backupManager: backupManager)
}