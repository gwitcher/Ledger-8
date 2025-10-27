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
        
        let _ = project.invoice?.url?.absoluteString
        
        NavigationStack {
            
            VStack(alignment: .leading) {
                HStack {
                    Image(systemName: "doc")
                        .foregroundColor(project.invoiceNeedsUpdate ? .red : .primary)
                    Text("\(project.invoice?.name ?? "No Invoice")...")
                        .font(.footnote)
                        .minimumScaleFactor(0.5)
                        .foregroundColor(project.invoiceNeedsUpdate ? .red : .primary)
                    
                    if isDeleting {
                        Spacer()
                        ProgressView()
                            .scaleEffect(0.8)
                    }
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
        if let invoice = project.invoice,
           let originalURL = invoice.url,
           let resolvedURL = resolveInvoiceFileLocation(originalURL: originalURL, fileName: invoice.name) {
            
            NavigationStack {
                VStack{
                    WebkitPdfView(pdfURL: resolvedURL, pdfTitle: invoice.name)
                }
                .navigationTitle(invoice.name)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Done") {
                            invoiceSheetIsPresented = false
                        }
                    }
                    
                    ToolbarItem(placement: .topBarTrailing) {
                        ShareLink(item: resolvedURL)
                    }
                }
                .onAppear {
                    // Update stored URL if we found it in a different location
                    if resolvedURL != originalURL {
                        logger.info("Invoice file found at new location in sheet, updating stored URL")
                        invoice.url = resolvedURL
                        try? modelContext.save()
                    }
                }
            }
        } else {
            ContentUnavailableView(
                "Invoice File Missing",
                systemImage: "doc.questionmark",
                description: Text("The invoice PDF file could not be found. It may have been moved or deleted.")
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
        
        guard let originalURL = invoice.url else {
            showError("Invoice file location is unknown")
            return
        }
        
        // Try to resolve the file location with enhanced logic
        guard let resolvedURL = resolveInvoiceFileLocation(originalURL: originalURL, fileName: invoice.name) else {
            showError("Invoice file not found. It may have been moved or deleted.")
            return
        }
        
        // Update the stored URL if we found it in a different location
        if resolvedURL != originalURL {
            logger.info("Invoice file found at new location, updating stored URL")
            invoice.url = resolvedURL
            try? modelContext.save()
        }
        
        logger.info("Opening invoice: \(invoice.name)")
        invoiceSheetIsPresented = true
    }
    
    private func validateInvoiceFile() {
        guard let invoice = project.invoice,
              let originalURL = invoice.url else { return }
        
        // Try to resolve the file location
        if let resolvedURL = resolveInvoiceFileLocation(originalURL: originalURL, fileName: invoice.name) {
            // Update stored URL if we found it in a different location
            if resolvedURL != originalURL {
                logger.info("Invoice file found at new location during validation, updating stored URL")
                invoice.url = resolvedURL
                try? modelContext.save()
            }
            logger.info("Invoice file validated: \(invoice.name)")
        } else {
            logger.warning("Invoice file missing: \(originalURL.path)")
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
            
            // Reset the invoice update flag when invoice is deleted
            project.clearInvoiceUpdateFlag()
            
            logger.info("Invoice deleted successfully: \(invoice.name)")
        } catch {
            logger.error("Failed to delete invoice: \(error.localizedDescription)")
            showError("Failed to delete invoice: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Enhanced URL Resolution Logic
    
    /// Attempts to locate an invoice file using multiple search strategies
    /// - Parameters:
    ///   - originalURL: The original stored file URL
    ///   - fileName: The invoice file name for fallback searching
    /// - Returns: The resolved file URL if found, nil otherwise
    private func resolveInvoiceFileLocation(originalURL: URL, fileName: String) -> URL? {
        // Strategy 1: Try the original URL first
        if FileManager.default.fileExists(atPath: originalURL.path) {
            logger.info("Invoice file found at original location: \(originalURL.path)")
            return originalURL
        }
        
        logger.info("Original URL invalid, searching for file: \(fileName)")
        
        // Strategy 2: Search in common invoice storage locations
        let searchLocations = generateSearchLocations(fileName: fileName)
        
        for candidateURL in searchLocations {
            if FileManager.default.fileExists(atPath: candidateURL.path) {
                logger.info("✅ Invoice file found at: \(candidateURL.path)")
                return candidateURL
            } else {
                logger.debug("Checked location (not found): \(candidateURL.path)")
            }
        }
        
        // Strategy 3: Recursive search in Documents directory
        if let foundURL = recursiveFileSearch(fileName: fileName, in: URL.documentsDirectory) {
            logger.info("✅ Invoice file found via recursive search: \(foundURL.path)")
            return foundURL
        }
        
        // Strategy 4: Search by partial filename matching (in case of minor name changes)
        if let foundURL = searchByPartialName(fileName: fileName) {
            logger.info("✅ Invoice file found via partial name match: \(foundURL.path)")
            return foundURL
        }
        
        logger.warning("❌ Invoice file not found in any location: \(fileName)")
        return nil
    }
    
    /// Generates a comprehensive list of potential file locations
    private func generateSearchLocations(fileName: String) -> [URL] {
        var locations: [URL] = []
        
        // Current app's Documents/Invoices directory
        locations.append(URL.documentsDirectory.appendingPathComponent("Invoices/\(fileName)"))
        
        // App Group container (if available)
        if let groupContainer = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.ledger8") {
            locations.append(groupContainer.appendingPathComponent("Documents/Invoices/\(fileName)"))
            locations.append(groupContainer.appendingPathComponent("Invoices/\(fileName)"))
        }
        
        // Standard Documents directory variations
        if let standardDocsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            locations.append(standardDocsDir.appendingPathComponent("Invoices/\(fileName)"))
            locations.append(standardDocsDir.appendingPathComponent(fileName))
        }
        
        // Direct in Documents root
        locations.append(URL.documentsDirectory.appendingPathComponent(fileName))
        
        // iCloud Drive locations (if available)
        if let iCloudContainer = FileManager.default.url(forUbiquityContainerIdentifier: nil) {
            locations.append(iCloudContainer.appendingPathComponent("Documents/Invoices/\(fileName)"))
            locations.append(iCloudContainer.appendingPathComponent("Documents/\(fileName)"))
        }
        
        // Additional fallback locations within the app sandbox
        if let tempDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first {
            locations.append(tempDir.appendingPathComponent("Invoices/\(fileName)"))
        }
        
        return locations
    }
    
    /// Performs a recursive search for the file in a directory tree
    private func recursiveFileSearch(fileName: String, in directory: URL) -> URL? {
        let fileManager = FileManager.default
        
        guard let enumerator = fileManager.enumerator(
            at: directory,
            includingPropertiesForKeys: [.isDirectoryKey, .nameKey],
            options: [.skipsHiddenFiles]
        ) else {
            return nil
        }
        
        for case let url as URL in enumerator {
            do {
                let resourceValues = try url.resourceValues(forKeys: [.isDirectoryKey, .nameKey])
                
                // Skip directories
                if resourceValues.isDirectory == true {
                    continue
                }
                
                // Check for exact filename match
                if resourceValues.name == fileName {
                    return url
                }
            } catch {
                logger.warning("Error reading resource values for \(url.path): \(error)")
            }
        }
        
        return nil
    }
    
    /// Searches for files with similar names (handles minor variations)
    private func searchByPartialName(fileName: String) -> URL? {
        let baseFileName = fileName.replacingOccurrences(of: ".pdf", with: "")
        let searchDirectory = URL.documentsDirectory.appendingPathComponent("Invoices")
        
        guard let enumerator = FileManager.default.enumerator(
            at: searchDirectory,
            includingPropertiesForKeys: [.nameKey],
            options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants]
        ) else {
            return nil
        }
        
        for case let url as URL in enumerator {
            let candidateName = url.lastPathComponent
            
            // Look for files that contain the base name and are PDFs
            if candidateName.contains(baseFileName) && candidateName.hasSuffix(".pdf") {
                logger.info("Found potential match via partial name: \(candidateName)")
                return url
            }
        }
        
        return nil
    }

    private func performInvoiceDeletion(invoice: Invoice) async throws {
        // Validate invoice exists
        guard let originalURL = invoice.url else {
            logger.error("Invoice has no file URL")
            throw InvoiceFileError.invalidURL
        }
        
        logger.info("Attempting to delete invoice: \(invoice.name)")
        
        // Use enhanced resolution to find the actual file location
        guard let actualFileURL = resolveInvoiceFileLocation(originalURL: originalURL, fileName: invoice.name) else {
            // File doesn't exist anywhere, just remove from database
            logger.info("File not found in any location, removing database entry: \(invoice.name)")
            modelContext.delete(invoice)
            try modelContext.save()
            return
        }
        
        // Log the actual file path being deleted
        logger.info("Found file to delete at: \(actualFileURL.path)")
        
        // Check file permissions
        let isReadable = FileManager.default.isReadableFile(atPath: actualFileURL.path)
        let isWritable = FileManager.default.isWritableFile(atPath: actualFileURL.path)
        let isDeletable = FileManager.default.isDeletableFile(atPath: actualFileURL.path)
        
        logger.info("File permissions - Readable: \(isReadable), Writable: \(isWritable), Deletable: \(isDeletable)")
        
        if !isDeletable {
            logger.error("File is not deletable due to permissions")
            throw InvoiceFileError.deletionFailed("Insufficient permissions to delete file")
        }
        
        // Validate file size before deletion
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: actualFileURL.path)
            let fileSize = attributes[.size] as? Int64 ?? 0
            logger.info("Deleting invoice file: \(actualFileURL.lastPathComponent), size: \(fileSize) bytes")
        } catch {
            logger.warning("Could not read file attributes: \(error.localizedDescription)")
        }
        
        // Attempt to delete the file
        do {
            try FileManager.default.removeItem(at: actualFileURL)
            logger.info("✅ Invoice file successfully deleted: \(actualFileURL.lastPathComponent)")
            
            // Verify deletion was successful
            let stillExists = FileManager.default.fileExists(atPath: actualFileURL.path)
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
