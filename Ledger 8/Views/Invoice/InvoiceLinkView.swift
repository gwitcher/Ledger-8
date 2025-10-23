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
    @State private var pendingDeletion = false // New state to prevent rapid state changes
    
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
                if !isDeleting && !pendingDeletion {
                    openInvoice()
                }
            }
            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                Button {
                    requestDeleteConfirmation()
                } label: {
                    Label("Delete", systemImage: "trash")
                }
                .tint(.red)
                .disabled(isDeleting || pendingDeletion)
            }
            .onAppear {
                validateInvoiceFile()
            }
            .sheet(isPresented: $invoiceSheetIsPresented) {
                invoiceSheet
            }
            .alert(
                "Delete Invoice",
                isPresented: $showingDeleteConfirmation
            ) {
                Button("Delete", role: .destructive) {
                    Task {
                        await deleteInvoiceWithValidation()
                    }
                }
                Button("Cancel", role: .cancel) {
                    resetDeletionState()
                }
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
    
    private func requestDeleteConfirmation() {
        guard !isDeleting && !pendingDeletion else { return }
        
        pendingDeletion = true
        
        // Small delay to ensure swipe action completes before showing alert
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            showingDeleteConfirmation = true
        }
    }
    
    private func resetDeletionState() {
        pendingDeletion = false
        showingDeleteConfirmation = false
    }
    
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
            resetDeletionState()
            return
        }
        
        // Set deleting state
        isDeleting = true
        showingDeleteConfirmation = false // Dismiss alert immediately
        
        defer { 
            isDeleting = false 
            resetDeletionState()
        }
        
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
            logger.error("Invoice has no file URL")
            throw InvoiceFileError.invalidURL
        }
        
        logger.info("Attempting to delete invoice file at: \(fileURL.path)")
        
        // Check if file exists at the original location
        let fileExists = FileManager.default.fileExists(atPath: fileURL.path)
        logger.info("File exists at original path: \(fileExists) - \(fileURL.path)")
        
        var actualFileURL: URL? = nil
        
        if fileExists {
            actualFileURL = fileURL
        } else {
            // Check alternative locations where the file might actually be
            let fileName = fileURL.lastPathComponent
            
            // Check in shared container (Files app visible location)
            let possibleLocations = [
                // Try app group container if it exists
                FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.ledger8")?.appendingPathComponent("Documents/Invoices/\(fileName)"),
                // Try other common locations
                URL.documentsDirectory.appendingPathComponent("Invoices/\(fileName)"),
                FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("Invoices/\(fileName)"),
            ].compactMap { $0 }
            
            for possibleURL in possibleLocations {
                logger.info("Checking alternative location: \(possibleURL.path)")
                if FileManager.default.fileExists(atPath: possibleURL.path) {
                    logger.info("✅ Found file at alternative location: \(possibleURL.path)")
                    actualFileURL = possibleURL
                    break
                }
            }
        }
        
        guard let targetURL = actualFileURL else {
            // File doesn't exist anywhere, just remove from database
            logger.info("File not found in any location, removing database entry: \(invoice.name)")
            modelContext.delete(invoice)
            try modelContext.save()
            return
        }
        
        // Log the actual file path being deleted
        logger.info("Found file to delete at: \(targetURL.path)")
        
        // Check file permissions
        let isReadable = FileManager.default.isReadableFile(atPath: targetURL.path)
        let isWritable = FileManager.default.isWritableFile(atPath: targetURL.path)
        let isDeletable = FileManager.default.isDeletableFile(atPath: targetURL.path)
        
        logger.info("File permissions - Readable: \(isReadable), Writable: \(isWritable), Deletable: \(isDeletable)")
        
        if !isDeletable {
            logger.error("File is not deletable due to permissions")
            throw InvoiceFileError.deletionFailed("Insufficient permissions to delete file")
        }
        
        // Validate file size before deletion
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: targetURL.path)
            let fileSize = attributes[.size] as? Int64 ?? 0
            logger.info("Deleting invoice file: \(targetURL.lastPathComponent), size: \(fileSize) bytes")
        } catch {
            logger.warning("Could not read file attributes: \(error.localizedDescription)")
        }
        
        // Attempt to delete the file
        do {
            try FileManager.default.removeItem(at: targetURL)
            logger.info("✅ Invoice file successfully deleted: \(targetURL.lastPathComponent)")
            
            // Verify deletion was successful
            let stillExists = FileManager.default.fileExists(atPath: targetURL.path)
            if stillExists {
                logger.error("❌ File still exists after deletion attempt!")
                throw InvoiceFileError.deletionFailed("File deletion appeared to succeed but file still exists")
            } else {
                logger.info("✅ Confirmed file no longer exists on disk")
            }
            
        } catch {
            logger.error("❌ File deletion failed: \(error.localizedDescription)")
            logger.error("Error details: \(error)")
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
                logger.info("✅ Database updated successfully - invoice removed")
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
        logger.error("Showing error to user: \(message)")
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
