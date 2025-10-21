//
//  CSVImportView.swift
//  Ledger 8
//
//  Created by CSV Import System
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct CSVImportView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var csvImporter: CSVImporter
    @State private var showingFilePicker = false
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    init(modelContext: ModelContext) {
        self._csvImporter = StateObject(wrappedValue: CSVImporter(modelContext: modelContext))
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                headerSection
                
                if csvImporter.isImporting {
                    importProgressSection
                } else {
                    instructionsSection
                    importButtonSection
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Import CSV")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .fileImporter(
                isPresented: $showingFilePicker,
                allowedContentTypes: [.commaSeparatedText, .plainText],
                allowsMultipleSelection: false
            ) { result in
                handleFileImport(result)
            }
            .alert(alertTitle, isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.fill")
                .font(.system(size: 50))
                .foregroundColor(.blue)
            
            Text("CSV Data Import")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Import your data from CSV files to populate the database")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Supported CSV Formats:")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                FormatRow(
                    title: "Ledger Analytics (Your Format)",
                    columns: ["Project", "Artist", "Client", "Date", "Media Type", "Income", "Paid"]
                )
                
                FormatRow(
                    title: "Projects",
                    columns: ["ProjectName", "Artist", "StartDate", "EndDate", "Status", "MediaType", "Notes"]
                )
                
                FormatRow(
                    title: "Items",
                    columns: ["Name", "Fee", "ItemType", "Notes", "Project"]
                )
                
                FormatRow(
                    title: "Clients",
                    columns: ["FirstName", "LastName", "Email", "Phone", "Company", "Address"]
                )
            }
            
            Text("💡 The importer will automatically detect the format based on your column headers")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 8)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var importButtonSection: some View {
        VStack(spacing: 16) {
            Button {
                showingFilePicker = true
            } label: {
                HStack {
                    Image(systemName: "square.and.arrow.down")
                    Text("Select CSV File")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(12)
            }
            
            Text("Select a CSV file from your device to import")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var importProgressSection: some View {
        VStack(spacing: 16) {
            ProgressView(value: csvImporter.importProgress)
                .progressViewStyle(LinearProgressViewStyle())
            
            Text(csvImporter.importStatus)
                .font(.body)
                .foregroundColor(.secondary)
            
            if csvImporter.importProgress < 1.0 {
                Button("Cancel") {
                    // Note: You might want to add cancellation logic to CSVImporter
                }
                .font(.caption)
                .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            
            Task {
                do {
                    try await csvImporter.importFromCSV(fileURL: url)
                    await MainActor.run {
                        alertTitle = "Success"
                        alertMessage = "CSV data imported successfully!"
                        showingAlert = true
                    }
                } catch {
                    await MainActor.run {
                        alertTitle = "Import Error"
                        alertMessage = error.localizedDescription
                        showingAlert = true
                    }
                }
            }
            
        case .failure(let error):
            alertTitle = "File Selection Error"
            alertMessage = error.localizedDescription
            showingAlert = true
        }
    }
}

struct FormatRow: View {
    let title: String
    let columns: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
            
            Text(columns.joined(separator: ", "))
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Preview
struct CSVImportView_Previews: PreviewProvider {
    static var previews: some View {
        // Create a mock model context for preview
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: Project.self, configurations: config)
        
        CSVImportView(modelContext: container.mainContext)
    }
}