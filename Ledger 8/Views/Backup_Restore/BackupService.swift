//
//  BackupService.swift
//  Ledger 8
//
//  Created by MVVM Refactoring on 10/28/25.
//

import Foundation
import SwiftData
import CryptoKit

/// Pure business service for backup operations - no UI concerns
@MainActor
class BackupService {
    
    // MARK: - Properties
    private var modelContext: ModelContext
    var checksumValidationEnabled = true
    
    // MARK: - Initialization
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func updateModelContext(_ context: ModelContext) {
        self.modelContext = context
    }
    
    // MARK: - Backup Operations
    
    /// Creates a complete backup with progress reporting
    func createCompleteBackup(progressHandler: @escaping (Double, String) -> Void) async throws -> URL {
        
        progressHandler(0.0, "Creating comprehensive backup...")
        
        var backup = CompleteLedgerBackup()
        
        // Backup AppStorage data
        progressHandler(0.1, "Backing up app settings...")
        backup.appSettings = BackupAppSettings.current()
        
        // Backup Clients
        progressHandler(0.25, "Backing up clients...")
        let clients = try modelContext.fetch(FetchDescriptor<Client>())
        backup.clients = clients.map { CompleteBackupClient(from: $0) }
        
        // Backup Projects with locations
        progressHandler(0.4, "Backing up projects...")
        let projects = try modelContext.fetch(FetchDescriptor<Project>())
        backup.projects = projects.map { CompleteBackupProject(from: $0) }
        
        // Backup Items
        progressHandler(0.55, "Backing up items...")
        let items = try modelContext.fetch(FetchDescriptor<Item>())
        backup.items = items.map { CompleteBackupItem(from: $0) }
        
        // Backup Invoices
        progressHandler(0.7, "Backing up invoices...")
        let invoices = try modelContext.fetch(FetchDescriptor<Invoice>())
        backup.invoices = invoices.compactMap { invoice in
            // Find which project owns this invoice
            let owningProject = projects.first { $0.invoice === invoice }
            return CompleteBackupInvoice(from: invoice, project: owningProject)
        }
        
        // Create backup file with checksum validation
        progressHandler(0.75, "Creating backup file with integrity validation...")
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        // First encode without checksum/fileSize to calculate them
        let preliminaryData = try encoder.encode(backup)
        
        // Calculate file size first (header + JSON data)
        let preliminaryFileData = BackupFileHeader.createBackupFileData(jsonData: preliminaryData)
        backup.metadata.fileSize = preliminaryFileData.count
        
        // Re-encode with fileSize included
        let dataWithFileSize = try encoder.encode(backup)
        
        // Calculate and add checksum to metadata (based on JSON that includes fileSize)
        if checksumValidationEnabled {
            progressHandler(0.85, "Calculating backup integrity checksum...")
            BackupChecksumValidator.addChecksumToBackup(&backup, jsonData: dataWithFileSize)
        }
        
        // Final encode with both checksum and fileSize included
        let finalJsonData = try encoder.encode(backup)
        let backupFileData = BackupFileHeader.createBackupFileData(jsonData: finalJsonData)
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let fileName = "Ledger8_CompleteBackup_\(formatter.string(from: Date())).l8backup"
        
        // Create Backups folder in Documents directory
        let documentsURL = URL.documentsDirectory
        let backupsURL = documentsURL.appendingPathComponent("Backups")
        
        // Ensure the Backups directory exists
        try FileManager.default.createDirectory(at: backupsURL, withIntermediateDirectories: true)
        
        let fileURL = backupsURL.appendingPathComponent(fileName)
        try backupFileData.write(to: fileURL)
        
        progressHandler(1.0, "Complete backup created successfully!")
        
        return fileURL
    }
    
    /// Restores a complete backup with progress reporting
    func restoreCompleteBackup(
        fileURL: URL, 
        replaceExisting: Bool = false, 
        skipChecksumValidation: Bool = false,
        progressHandler: @escaping (Double, String) -> Void
    ) async throws {
        
        progressHandler(0.0, "Reading backup file...")
        
        guard fileURL.startAccessingSecurityScopedResource() else {
            throw ComprehensiveBackupError.fileAccessDenied
        }
        defer { fileURL.stopAccessingSecurityScopedResource() }
        
        let rawData = try Data(contentsOf: fileURL)
        
        // Validate and extract data using magic header
        let headerValidation = BackupFileHeader.extractJSONData(from: rawData)
        
        // Enhanced status message based on header presence
        if headerValidation.hasHeader {
            progressHandler(0.05, "Validating Ledger 8 backup file...")
        } else {
            progressHandler(0.05, "Reading legacy backup file...")
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        // First try to decode and validate the backup
        let backup: CompleteLedgerBackup
        do {
            backup = try decoder.decode(CompleteLedgerBackup.self, from: headerValidation.jsonData)
        } catch {
            // Enhanced error handling based on header presence
            if headerValidation.hasHeader {
                throw ComprehensiveBackupError.corruptedBackup("Valid Ledger 8 backup file header found, but JSON data is corrupted: \(error.localizedDescription)")
            } else {
                throw ComprehensiveBackupError.invalidBackupFile("File does not appear to be a valid Ledger 8 backup")
            }
        }
        
        // Perform comprehensive integrity validation
        if checksumValidationEnabled && !skipChecksumValidation {
            progressHandler(0.08, "Performing backup integrity validation...")
            let integrityResult = BackupChecksumValidator.validateBackupIntegrity(
                fileData: rawData,
                extractedJSON: headerValidation.jsonData,
                backup: backup
            )
            
            // Handle validation results
            if !integrityResult.isValid {
                let details = integrityResult.validationResults.joined(separator: "\n")
                throw ComprehensiveBackupError.checksumValidationFailed(details)
            }
            
            if integrityResult.hasWarnings {
                progressHandler(0.09, "Backup validation passed with warnings...")
                // Continue with restoration but log warnings
                print("Backup warnings: \(integrityResult.warnings.joined(separator: ", "))")
            } else {
                progressHandler(0.09, "Backup integrity validation passed ✅")
            }
        } else if skipChecksumValidation {
            progressHandler(0.09, "Skipping integrity validation (emergency restore)...")
        } else {
            progressHandler(0.09, "Proceeding without integrity validation...")
        }
        
        // Validate backup metadata
        guard backup.metadata.appVersion.hasPrefix("Ledger 8") else {
            throw ComprehensiveBackupError.incompatibleVersion
        }
        
        // Check backup version compatibility
        guard backup.metadata.backupVersion == "2.0" else {
            throw ComprehensiveBackupError.unsupportedBackupVersion(backup.metadata.backupVersion)
        }
        
        if replaceExisting {
            try await clearAllData()
        }
        progressHandler(0.1, "Backup validated successfully")
        
        // Restore AppStorage settings
        progressHandler(0.15, "Restoring app settings...")
        backup.appSettings.applyToCurrentApp()
        
        // Track created objects for relationships
        var clientMap: [String: Client] = [:]
        var projectMap: [String: Project] = [:]
        
        // Restore clients
        progressHandler(0.25, "Restoring clients...")
        for backupClient in backup.clients {
            let client = Client()
            backupClient.applyTo(client)
            modelContext.insert(client)
            clientMap[backupClient.lookupKey] = client
        }
        
        // Restore projects with relationships and locations
        progressHandler(0.45, "Restoring projects...")
        for backupProject in backup.projects {
            let project = Project()
            backupProject.applyTo(project)
            
            // Initialize empty items array if needed
            if project.items == nil {
                project.items = []
            }
            
            // Link to client if found
            if let clientKey = backupProject.clientLookupKey,
               let client = clientMap[clientKey] {
                project.client = client
            }
            
            modelContext.insert(project)
            projectMap[backupProject.lookupKey] = project
        }
        
        // Restore items with project relationships
        progressHandler(0.65, "Restoring items...")
        for backupItem in backup.items {
            let item = Item()
            backupItem.applyTo(item)
            
            modelContext.insert(item)
            
            // Link to project if found - let SwiftData handle the inverse relationship
            if let projectKey = backupItem.projectLookupKey,
               let project = projectMap[projectKey] {
                item.project = project
            }
        }
        
        // Save items and their relationships
        try modelContext.save()
        
        // Restore invoices with project relationships
        progressHandler(0.85, "Restoring invoices...")
        for backupInvoice in backup.invoices {
            let invoice = Invoice(number: backupInvoice.number, name: backupInvoice.name)
            if let urlString = backupInvoice.urlString, let url = URL(string: urlString) {
                invoice.url = url
            }
            
            // Link to project if found
            if let projectKey = backupInvoice.projectLookupKey,
               let project = projectMap[projectKey] {
                project.invoice = invoice
            }
            
            modelContext.insert(invoice)
        }
        
        progressHandler(0.95, "Saving restored data...")
        try modelContext.save()
        
        progressHandler(1.0, "Complete backup restored successfully!")
    }
    
    /// Clear all data from the model context
    func clearAllData() async throws {
        // Clear AppStorage data
        UserDefaults.standard.removeObject(forKey: "userData")
        UserDefaults.standard.removeObject(forKey: "InitialInvoiceNumber")
        
        // Delete SwiftData objects in reverse dependency order
        let items = try modelContext.fetch(FetchDescriptor<Item>())
        for item in items {
            modelContext.delete(item)
        }
        
        let invoices = try modelContext.fetch(FetchDescriptor<Invoice>())
        for invoice in invoices {
            modelContext.delete(invoice)
        }
        
        let projects = try modelContext.fetch(FetchDescriptor<Project>())
        for project in projects {
            modelContext.delete(project)
        }
        
        let clients = try modelContext.fetch(FetchDescriptor<Client>())
        for client in clients {
            modelContext.delete(client)
        }
        
        try modelContext.save()
    }
    
    /// Validates an existing backup file without restoring it
    func validateBackupFile(at fileURL: URL) async throws -> BackupIntegrityResult {
        
        guard fileURL.startAccessingSecurityScopedResource() else {
            throw ComprehensiveBackupError.fileAccessDenied
        }
        defer { fileURL.stopAccessingSecurityScopedResource() }
        
        let rawData = try Data(contentsOf: fileURL)
        let headerValidation = BackupFileHeader.extractJSONData(from: rawData)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let backup = try decoder.decode(CompleteLedgerBackup.self, from: headerValidation.jsonData)
        
        let integrityResult = BackupChecksumValidator.validateBackupIntegrity(
            fileData: rawData,
            extractedJSON: headerValidation.jsonData,
            backup: backup
        )
        
        return integrityResult
    }
    
    /// Recalculates checksum for a backup file (useful for repair operations)
    func recalculateBackupChecksum(at fileURL: URL) async throws -> String {
        guard fileURL.startAccessingSecurityScopedResource() else {
            throw ComprehensiveBackupError.fileAccessDenied
        }
        defer { fileURL.stopAccessingSecurityScopedResource() }
        
        let rawData = try Data(contentsOf: fileURL)
        let headerValidation = BackupFileHeader.extractJSONData(from: rawData)
        
        return BackupChecksumValidator.calculateChecksum(for: headerValidation.jsonData)
    }
}