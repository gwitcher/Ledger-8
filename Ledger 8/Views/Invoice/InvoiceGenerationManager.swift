//
//  InvoiceGenerationManager.swift
//  Ledger 8
//
//  Created by Enterprise Enhancement System
//

import Foundation
import SwiftUI
import SwiftData

/// Manages invoice generation with progress tracking and error handling
@MainActor
@Observable
final class InvoiceGenerationManager {
    
    // MARK: - Published State
    
    var isGenerating = false
    var progress: Double = 0.0
    var currentStep = ""
    var errorMessage: String?
    var showingError = false
    
    // MARK: - Private Properties
    
    private var modelContext: ModelContext?
    
    // MARK: - Initialization
    
    init(modelContext: ModelContext? = nil) {
        self.modelContext = modelContext
    }
    
    func updateModelContext(_ context: ModelContext) {
        self.modelContext = context
    }
    
    // MARK: - Invoice Generation
    
    /// Generates an invoice with progress tracking and comprehensive error handling
    /// - Parameters:
    ///   - project: The project to generate an invoice for
    ///   - invoiceNumber: The current invoice number
    /// - Returns: The generated Invoice object or nil if failed
    func generateInvoice(for project: Project, invoiceNumber: Int) async -> Invoice? {
        // Atomic check and set to prevent race conditions
        guard !isGenerating else {
            InvoiceLogger.pdfGeneration.notice("⚠️ Invoice generation already in progress")
            return nil
        }
        
        isGenerating = true
        progress = 0.0
        errorMessage = nil
        currentStep = "Initializing..."
        
        // Give UI time to update the isGenerating flag for concurrent calls
        try? await Task.sleep(for: .milliseconds(1))
        
        defer {
            isGenerating = false
            currentStep = ""
        }
        
        do {
            let invoice = try await InvoiceLogger.measureTimeAsync(operation: "Full Invoice Generation") {
                try await generateInvoiceInternal(project: project, invoiceNumber: invoiceNumber)
            }
            
            progress = 1.0
            currentStep = "Complete"
            InvoiceLogger.pdfGeneration.info("✅ Invoice generated successfully: \(invoice.name)")
            return invoice
            
        } catch {
            progress = 0.0
            handleError(error)
            error.logInvoiceError(category: InvoiceLogger.pdfGeneration, context: "Invoice generation failed for project: \(project.projectName)")
            return nil
        }
    }
    
    // MARK: - Private Implementation
    
    private func generateInvoiceInternal(project: Project, invoiceNumber: Int) async throws -> Invoice {
        
        // Step 1: Validate project data (20%)
        currentStep = "Validating project data..."
        progress = 0.1
        
        try await Task.sleep(for: .milliseconds(100)) // Allow UI update
        try validateProjectForInvoiceGeneration(project)
        progress = 0.2
        
        // Step 2: Check system resources (40%)
        currentStep = "Checking system resources..."
        try checkSystemResources()
        progress = 0.4
        
        // Step 3: Prepare invoice data (60%)
        currentStep = "Preparing invoice data..."
        let invoiceData = try prepareInvoiceData(project: project, invoiceNumber: invoiceNumber)
        progress = 0.6
        
        // Step 4: Generate PDF (90%)
        currentStep = "Generating PDF..."
        try await generatePDFFile(project: project, invoiceData: invoiceData)
        progress = 0.9
        
        // Step 5: Finalize and save (100%)
        currentStep = "Finalizing invoice..."
        let finalInvoice = try finalizeInvoice(project: project, invoiceData: invoiceData)
        progress = 1.0
        
        return finalInvoice
    }
    
    private func validateProjectForInvoiceGeneration(_ project: Project) throws {
        InvoiceLogger.logDataValidation(.info, "Validating project: \(project.projectName)")
        
        // Load user data from UserDefaults (same way @AppStorage does it)
        let userData: UserData
        if let userDataString = UserDefaults.standard.string(forKey: "userData"),
           let loadedUserData = UserData(rawValue: userDataString) {
            userData = loadedUserData
        } else {
            userData = UserData() // Use default empty data if nothing saved
        }
        
        guard userData.company.isValidForInvoice else {
            throw InvoiceGenerationError.invalidProjectData
        }
        
        // Validate project has items
        guard let items = project.items, !items.isEmpty else {
            throw InvoiceGenerationError.invalidProjectData
        }
        
        // Validate total amount
        let total = project.calculateFeeTotal(items: items)
        guard total >= 0 else {
            throw InvoiceGenerationError.invalidProjectData
        }
        
        InvoiceLogger.logDataValidation(.info, "Project validation passed: \(items.count) items, total: $\(String(format: "%.2f", total))")
    }
    
    private func checkSystemResources() throws {
        InvoiceLogger.logPerformance(.info, "Checking system resources")
        
        // Check available memory
        var memoryInfo = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &memoryInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            let usedMemory = memoryInfo.resident_size
            InvoiceLogger.logPerformance(.info, "Current memory usage: \(usedMemory / 1024 / 1024) MB")
        }
        
        // Check storage space
        let documentsURL = URL.documentsDirectory
        let resourceValues = try documentsURL.resourceValues(forKeys: [.volumeAvailableCapacityKey])
        
        if let availableCapacity = resourceValues.volumeAvailableCapacity {
            let minimumRequired: Int64 = 10_000_000 // 10MB
            guard availableCapacity > minimumRequired else {
                throw InvoiceGenerationError.insufficientStorage
            }
            InvoiceLogger.logPerformance(.info, "Available storage: \(availableCapacity / 1024 / 1024) MB")
        }
    }
    
    private func prepareInvoiceData(project: Project, invoiceNumber: Int) throws -> InvoiceData {
        InvoiceLogger.logPDFGeneration(.info, "Preparing invoice data")
        
        let invoiceDate = Date.now
        let nextInvoiceNumber = invoiceNumber + 1
        
        // Generate safe filename
        let clientName = project.client?.fullName ?? "Unknown"
        let safeName = clientName
            .replacingOccurrences(of: "[^a-zA-Z0-9\\s]", with: "", options: .regularExpression)
            .replacingOccurrences(of: "\\s+", with: "_", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        let dateString = invoiceDate.formatted(.iso8601.year().month().day().dateSeparator(.dash))
        let invoiceName = "Invoice_\(nextInvoiceNumber)_\(safeName)_\(dateString).pdf"
        
        // Prepare directory
        let documentsURL = URL.documentsDirectory
        let invoicesURL = documentsURL.appendingPathComponent("Invoices")
        try FileManager.default.createDirectory(at: invoicesURL, withIntermediateDirectories: true)
        
        let finalURL = resolveFilenameConflicts(baseURL: invoicesURL.appendingPathComponent(invoiceName))
        
        return InvoiceData(
            number: nextInvoiceNumber,
            name: finalURL.lastPathComponent,
            date: invoiceDate,
            url: finalURL,
            project: project
        )
    }
    
    private func generatePDFFile(project: Project, invoiceData: InvoiceData) async throws {
        InvoiceLogger.logPDFGeneration(.info, "Starting PDF generation: \(invoiceData.name)")
        
        return try await withCheckedThrowingContinuation { continuation in
            Task { @MainActor in
                do {
                    let renderer = ImageRenderer(content: InvoiceTemplateView(project: project))
                    renderer.proposedSize = .init(width: 612, height: 792) // Letter size
                    
                    renderer.render { size, context in
                        var box = CGRect(x: 0, y: 0, width: size.width, height: size.height)
                        
                        guard let pdf = CGContext(invoiceData.url as CFURL, mediaBox: &box, nil) else {
                            InvoiceLogger.logPDFGeneration(.error, "Failed to create PDF context")
                            continuation.resume(throwing: InvoiceGenerationError.pdfCreationFailed)
                            return
                        }
                        
                        pdf.beginPDFPage(nil)
                        context(pdf)
                        pdf.endPDFPage()
                        pdf.closePDF()
                        
                        InvoiceLogger.logPDFGeneration(.info, "PDF file created: \(invoiceData.url.lastPathComponent)")
                        continuation.resume()
                    }
                } catch {
                    InvoiceLogger.logPDFGeneration(.error, "PDF rendering failed: \(error.localizedDescription)")
                    continuation.resume(throwing: InvoiceGenerationError.templateRenderingFailed)
                }
            }
        }
    }
    
    private func finalizeInvoice(project: Project, invoiceData: InvoiceData) throws -> Invoice {
        InvoiceLogger.logPDFGeneration(.info, "Finalizing invoice")
        
        // Validate generated file
        try validateGeneratedPDF(at: invoiceData.url)
        
        // Create invoice object
        let invoice = Invoice(number: invoiceData.number, name: invoiceData.name)
        invoice.url = invoiceData.url
        
        // Update project
        project.invoice = invoice
        
        // Save to model context if available
        if let modelContext = modelContext {
            do {
                try modelContext.save()
                InvoiceLogger.logFileOperation(.info, "Invoice saved to database: \(invoice.name)")
            } catch {
                InvoiceLogger.logFileOperation(.error, "Failed to save invoice to database: \(error.localizedDescription)")
                throw InvoiceGenerationError.fileSystemError("Database save failed")
            }
        }
        
        return invoice
    }
    
    private func validateGeneratedPDF(at url: URL) throws {
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        
        guard let fileSize = attributes[.size] as? Int64 else {
            throw InvoiceGenerationError.pdfCreationFailed
        }
        
        guard fileSize > 1000 else {
            InvoiceLogger.logPDFGeneration(.error, "Generated PDF is too small: \(fileSize) bytes")
            throw InvoiceGenerationError.pdfCreationFailed
        }
        
        guard fileSize < 50_000_000 else {
            InvoiceLogger.logPDFGeneration(.error, "Generated PDF is too large: \(fileSize) bytes")
            throw InvoiceGenerationError.pdfCreationFailed
        }
        
        InvoiceLogger.logPDFGeneration(.info, "PDF validation successful: \(fileSize) bytes")
    }
    
    private func resolveFilenameConflicts(baseURL: URL) -> URL {
        var finalURL = baseURL
        var counter = 1
        
        while FileManager.default.fileExists(atPath: finalURL.path) {
            let nameWithoutExtension = baseURL.deletingPathExtension().lastPathComponent
            let directory = baseURL.deletingLastPathComponent()
            let newName = "\(nameWithoutExtension)_\(counter).pdf"
            finalURL = directory.appendingPathComponent(newName)
            counter += 1
            
            if counter > 100 {
                InvoiceLogger.logFileOperation(.error, "Too many filename conflicts")
                break
            }
        }
        
        if finalURL != baseURL {
            InvoiceLogger.logFileOperation(.info, "Resolved filename conflict: \(finalURL.lastPathComponent)")
        }
        
        return finalURL
    }
    
    private func handleError(_ error: Error) {
        if let invoiceError = error as? InvoiceGenerationError {
            errorMessage = invoiceError.localizedDescription
        } else {
            errorMessage = "An unexpected error occurred: \(error.localizedDescription)"
        }
        showingError = true
    }
}

// MARK: - Supporting Types

private struct InvoiceData {
    let number: Int
    let name: String
    let date: Date
    let url: URL
    let project: Project
}
