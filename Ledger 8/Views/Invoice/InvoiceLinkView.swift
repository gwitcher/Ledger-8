//
//  InvoiceLinkView.swift
//  Ledger 8
//
//  Created by Gabe Witcher on 4/30/25.
//

import SwiftUI
import SwiftData
import PDFKit
import os.log

struct InvoiceLinkView: View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss
    
    var project: Project
    
    @State private var invoiceSheetIsPresented = false
    @State private var showingDeleteConfirmation = false
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    @State private var isDeleting = false
    
    private let logger = Logger(subsystem: "com.ledger8.invoice", category: "InvoiceLink")
    
    var body: some View {
        
        let path = project.invoice?.url?.absoluteString
        
        NavigationStack {
            
            HStack {
                Image(systemName: "doc")
                Text("\(project.invoice?.name ?? "No Invoice")...")
                    .font(.footnote)
                    .minimumScaleFactor(0.5)
                
                if isDeleting {
                    Spacer()
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            .onTapGesture {
                openInvoice()
            }
            .swipeActions {
                Button("Delete", role: .destructive) {
                    showingDeleteConfirmation = true
                }
                .disabled(isDeleting)
            }
            .onAppear {
                validateInvoiceFile()
            }
            .sheet(isPresented: $invoiceSheetIsPresented) {
                invoiceSheet
            }
            .confirmationDialog(
                "Delete Invoice",
                isPresented: $showingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete Invoice", role: .destructive) {
                    Task {
                        await deleteInvoiceWithValidation()
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will permanently delete the invoice PDF file. This action cannot be undone.")
            }
            .alert("Error", isPresented: $showingErrorAlert) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    @ViewBuilder
    private var invoiceSheet: some View {
        if let pdfURL = project.invoice?.url {
            NavigationStack {
                Group {
                    if FileManager.default.fileExists(atPath: pdfURL.path) {
                        VStack{
                            WebkitPdfView(pdfURL: pdfURL, pdfTitle: project.invoice!.name)
                        }
                    } else {
                        ContentUnavailableView(
                            "Invoice File Missing",
                            systemImage: "doc.questionmark",
                            description: Text("The invoice PDF file could not be found. It may have been moved or deleted.")
                        )
                    }
                }
                .navigationTitle(project.invoice?.name ?? "Invoice")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Done") {
                            invoiceSheetIsPresented = false
                        }
                    }
                    
                    if FileManager.default.fileExists(atPath: pdfURL.path) {
                        ToolbarItem(placement: .topBarTrailing) {
                            ShareLink(item: pdfURL)
                        }
                    }
                }
            }
        } else {
            ContentUnavailableView(
                "No Invoice Available",
                systemImage: "doc.badge.plus",
                description: Text("Generate an invoice for this project to view it here.")
            )
        }
    }
    
    // MARK: - Helper Methods
    
    private func openInvoice() {
        guard let invoice = project.invoice else {
            showError("No invoice available for this project")
            return
        }
        
        guard let url = invoice.url else {
            showError("Invoice file location is unknown")
            return
        }
        
        // Check if file exists before opening
        guard FileManager.default.fileExists(atPath: url.path) else {
            showError("Invoice file not found. It may have been moved or deleted.")
            return
        }
        
        logger.info("Opening invoice: \(invoice.name)")
        invoiceSheetIsPresented = true
    }
    
    private func validateInvoiceFile() {
        guard let invoice = project.invoice,
              let url = invoice.url else { return }
        
        // Check if file still exists
        if !FileManager.default.fileExists(atPath: url.path) {
            logger.warning("Invoice file missing: \(url.path)")
        } else {
            logger.info("Invoice file validated: \(invoice.name)")
        }
    }
    
    @MainActor
    private func deleteInvoiceWithValidation() async {
        guard let invoice = project.invoice else {
            showError("No invoice to delete")
            return
        }
        
        isDeleting = true
        defer { isDeleting = false }
        
        do {
            try await performInvoiceDeletion(invoice: invoice)
            project.invoice = nil
            logger.info("Invoice deleted successfully: \(invoice.name)")
        } catch {
            logger.error("Failed to delete invoice: \(error.localizedDescription)")
            showError("Failed to delete invoice: \(error.localizedDescription)")
        }
    }
    
    private func performInvoiceDeletion(invoice: Invoice) async throws {
        // Validate invoice exists
        guard let fileURL = invoice.url else {
            throw InvoiceFileError.invalidURL
        }
        
        // Check if file exists before attempting deletion
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            // File doesn't exist, just remove from database
            logger.info("File not found on disk, removing database entry: \(invoice.name)")
            modelContext.delete(invoice)
            try modelContext.save()
            return
        }
        
        // Validate file size and permissions before deletion
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
            let fileSize = attributes[.size] as? Int64 ?? 0
            logger.info("Deleting invoice file: \(fileURL.lastPathComponent), size: \(fileSize)")
        } catch {
            logger.warning("Could not read file attributes: \(error.localizedDescription)")
        }
        
        // Attempt to delete the file
        do {
            try FileManager.default.removeItem(at: fileURL)
            logger.info("Invoice file deleted: \(fileURL.lastPathComponent)")
        } catch {
            logger.error("File deletion failed: \(error.localizedDescription)")
            throw InvoiceFileError.deletionFailed(error.localizedDescription)
        }
        
        // Remove from database
        modelContext.delete(invoice)
        
        // Save changes with retry logic
        var retryCount = 0
        let maxRetries = 3
        
        while retryCount < maxRetries {
            do {
                try modelContext.save()
                logger.info("Database updated successfully")
                break
            } catch {
                retryCount += 1
                logger.warning("Database save attempt \(retryCount) failed: \(error.localizedDescription)")
                
                if retryCount >= maxRetries {
                    throw InvoiceFileError.databaseSaveFailed(error.localizedDescription)
                }
                
                // Brief delay before retry
                try await Task.sleep(for: .milliseconds(100))
            }
        }
    }
    
    private func showError(_ message: String) {
        errorMessage = message
        showingErrorAlert = true
    }
}

// MARK: - Invoice File Errors

enum InvoiceFileError: LocalizedError {
    case invalidURL
    case fileNotFound
    case deletionFailed(String)
    case databaseSaveFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid invoice file location"
        case .fileNotFound:
            return "Invoice file not found"
        case .deletionFailed(let details):
            return "Failed to delete invoice file: \(details)"
        case .databaseSaveFailed(let details):
            return "Failed to update database: \(details)"
        }
    }
}

//#Preview {
//    InvoiceLinkView(project: Project(), invoiceSheetisPresented:)
//}
