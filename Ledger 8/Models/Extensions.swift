//
//  Extensions.swift
//  Ledger 8
//
//  Created by Gabe Witcher on 4/16/25.
//

import Foundation
import SwiftUI
import os.log

// MARK: - Invoice Generation Errors
enum InvoiceGenerationError: LocalizedError {
    case invalidProjectData
    case pdfCreationFailed
    case fileSystemError(String)
    case insufficientStorage
    case templateRenderingFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidProjectData:
            return "Project data is incomplete or invalid"
        case .pdfCreationFailed:
            return "Failed to generate PDF document"
        case .fileSystemError(let details):
            return "File system error: \(details)"
        case .insufficientStorage:
            return "Insufficient storage space available"
        case .templateRenderingFailed:
            return "Failed to render invoice template"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .invalidProjectData:
            return "Please ensure all required project information is completed"
        case .pdfCreationFailed:
            return "Try generating the invoice again"
        case .fileSystemError:
            return "Check available storage space and try again"
        case .insufficientStorage:
            return "Free up storage space and try again"
        case .templateRenderingFailed:
            return "Check project data and try again"
        }
    }
}

// MARK: - Logging System
private let logger = Logger(subsystem: "com.ledger8.invoice", category: "PDFGeneration")

@MainActor
extension Project {
    
    func calculateFeeTotal(items: [Item] ) -> Double {
        var total = 0.0
        for item in items {
            total += item.fee
        }
        return total
    }
    
    func projectsFeeTotal(projects: [Project]) -> Double {
        var projectTotal = 0.0
        for project in projects {
            projectTotal += project.calculateFeeTotal(items: project.items!)
        }
        return projectTotal
    }
    
    /// Asynchronously renders an invoice PDF with comprehensive error handling
    /// - Parameters:
    ///   - project: The project to generate an invoice for
    ///   - invoiceNumber: The current invoice number
    /// - Returns: The generated Invoice object
    /// - Throws: InvoiceGenerationError for various failure cases
    func renderInvoice(project: Project, invoiceNumber: Int) async throws -> Invoice {
        logger.info("Starting invoice generation for project: \(project.projectName)")
        
        // Validate project data
        try validateProjectData(project)
        
        // Check storage availability
        try checkStorageAvailability()
        
        let invoiceDate = Date.now
        let nextInvoiceNumber = invoiceNumber + 1
        let invoiceName = generateSafeInvoiceName(
            invoiceNumber: nextInvoiceNumber,
            client: project.client,
            date: invoiceDate
        )
        
        logger.info("Generating invoice: \(invoiceName)")
        
        let newInvoice = Invoice(number: nextInvoiceNumber, name: invoiceName)
        project.invoice = newInvoice
        
        do {
            // Prepare directories
            let invoicesURL = try prepareInvoicesDirectory()
            let finalURL = invoicesURL.appendingPathComponent(invoiceName)
            
            // Check for filename conflicts and resolve
            let resolvedURL = try resolveFilenameConflicts(url: finalURL)
            
            // Generate PDF asynchronously
            try await generatePDFAsync(
                project: project,
                outputURL: resolvedURL
            )
            
            // Validate generated file
            try validateGeneratedPDF(at: resolvedURL)
            
            newInvoice.url = resolvedURL
            logger.info("Invoice generation completed successfully: \(invoiceName)")
            
            return newInvoice
            
        } catch {
            logger.error("Invoice generation failed: \(error.localizedDescription)")
            throw InvoiceGenerationError.pdfCreationFailed
        }
    }
    
    // MARK: - Private Helper Methods
    
    /// Validates project data before invoice generation
    private func validateProjectData(_ project: Project) throws {
        // Check if company data is valid for invoice generation
        let userData = UserData() // This should be injected in a real implementation
        guard userData.company.isValidForInvoice else {
            logger.error("Company data invalid for invoice generation")
            throw InvoiceGenerationError.invalidProjectData
        }
        
        // Validate project has items
        guard let items = project.items, !items.isEmpty else {
            logger.error("Project has no items for invoice generation")
            throw InvoiceGenerationError.invalidProjectData
        }
        
        // Validate total amount is reasonable
        let total = calculateFeeTotal(items: items)
        guard total >= 0 else {
            logger.error("Invalid total amount: \(total)")
            throw InvoiceGenerationError.invalidProjectData
        }
    }
    
    /// Checks available storage space
    private func checkStorageAvailability() throws {
        do {
            let documentsURL = URL.documentsDirectory
            let resourceValues = try documentsURL.resourceValues(forKeys: [.volumeAvailableCapacityKey])
            
            if let availableCapacity = resourceValues.volumeAvailableCapacity {
                let minimumRequired: Int64 = 10_000_000 // 10MB minimum
                
                if availableCapacity < minimumRequired {
                    logger.error("Insufficient storage: \(availableCapacity) bytes available")
                    throw InvoiceGenerationError.insufficientStorage
                }
            }
        } catch {
            logger.error("Storage check failed: \(error.localizedDescription)")
            throw InvoiceGenerationError.fileSystemError("Storage check failed")
        }
    }
    
    /// Generates a safe filename for the invoice
    private func generateSafeInvoiceName(invoiceNumber: Int, client: Client?, date: Date) -> String {
        let clientName = client?.fullName ?? "Unknown"
        let safeName = clientName.replacingOccurrences(of: "[^a-zA-Z0-9\\s]", with: "", options: .regularExpression)
            .replacingOccurrences(of: "\\s+", with: "_", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        let dateString = date.formatted(.iso8601.year().month().day().dateSeparator(.dash))
        return "Invoice_\(invoiceNumber)_\(safeName)_\(dateString).pdf"
    }
    
    /// Prepares the invoices directory with proper error handling
    private func prepareInvoicesDirectory() throws -> URL {
        let documentsURL = URL.documentsDirectory
        let invoicesURL = documentsURL.appendingPathComponent("Invoices")
        
        do {
            try FileManager.default.createDirectory(at: invoicesURL, withIntermediateDirectories: true, attributes: nil)
            logger.info("Invoices directory prepared: \(invoicesURL.path)")
            return invoicesURL
        } catch {
            logger.error("Failed to create invoices directory: \(error.localizedDescription)")
            throw InvoiceGenerationError.fileSystemError("Directory creation failed")
        }
    }
    
    /// Resolves filename conflicts by appending a number
    private func resolveFilenameConflicts(url: URL) throws -> URL {
        var finalURL = url
        var counter = 1
        
        while FileManager.default.fileExists(atPath: finalURL.path) {
            let nameWithoutExtension = url.deletingPathExtension().lastPathComponent
            let directory = url.deletingLastPathComponent()
            let newName = "\(nameWithoutExtension)_\(counter).pdf"
            finalURL = directory.appendingPathComponent(newName)
            counter += 1
            
            // Prevent infinite loops
            if counter > 100 {
                logger.error("Too many filename conflicts for: \(url.lastPathComponent)")
                throw InvoiceGenerationError.fileSystemError("Filename conflict resolution failed")
            }
        }
        
        if finalURL != url {
            logger.info("Resolved filename conflict: \(finalURL.lastPathComponent)")
        }
        
        return finalURL
    }
    
    /// Asynchronously generates the PDF using ImageRenderer
    private func generatePDFAsync(project: Project, outputURL: URL) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            Task { @MainActor in
                let renderer = ImageRenderer(content: InvoiceTemplateView(project: project))
                
                // Configure renderer for better quality
                renderer.proposedSize = .init(width: 612, height: 792) // Letter size
                
                // Start the rendering process
                renderer.render { size, context in
                    var box = CGRect(x: 0, y: 0, width: size.width, height: size.height)
                    
                    guard let pdf = CGContext(outputURL as CFURL, mediaBox: &box, nil) else {
                        logger.error("Failed to create PDF context")
                        continuation.resume(throwing: InvoiceGenerationError.pdfCreationFailed)
                        return
                    }
                    
                    pdf.beginPDFPage(nil)
                    context(pdf)
                    pdf.endPDFPage()
                    pdf.closePDF()
                    
                    continuation.resume()
                }
            }
        }
    }
    
    /// Validates the generated PDF file
    private func validateGeneratedPDF(at url: URL) throws {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            
            if let fileSize = attributes[.size] as? Int64 {
                // Check if file is reasonable size (not empty, not too large)
                guard fileSize > 1000 else { // At least 1KB
                    logger.error("Generated PDF is too small: \(fileSize) bytes")
                    throw InvoiceGenerationError.pdfCreationFailed
                }
                
                guard fileSize < 50_000_000 else { // Less than 50MB
                    logger.error("Generated PDF is too large: \(fileSize) bytes")
                    throw InvoiceGenerationError.pdfCreationFailed
                }
                
                logger.info("PDF validation successful: \(fileSize) bytes")
            }
        } catch {
            logger.error("PDF validation failed: \(error.localizedDescription)")
            throw InvoiceGenerationError.pdfCreationFailed
        }
    }
    
    func nextInvoiceNumber(projects: [Project], defaultInvoiceNumber: Int) -> Int{
        var invoiceNumbers: [Int] = []
        for project in projects {
            invoiceNumbers.append(project.invoice?.number ?? defaultInvoiceNumber)
        }
        return invoiceNumbers.max() ?? defaultInvoiceNumber
        
        
    }
}

extension Date {
    func adding(minutes: Int) -> Date {
        Calendar.current.date(byAdding: .minute, value: minutes, to: self)!
    }

    func adding(hours: Int) -> Date {
        Calendar.current.date(byAdding: .hour, value: hours, to: self)!
    }
}

extension View {
    func hideKeyboard() {
        let resign = #selector(UIResponder.resignFirstResponder)
        UIApplication.shared.sendAction(resign, to: nil, from: nil, for: nil)
    }
}
