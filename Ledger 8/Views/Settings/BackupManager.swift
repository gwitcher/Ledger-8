//
//  BackupManager.swift
//  Ledger 8
//
//  Created by Backup System
//

import Foundation
import SwiftData
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Magic Header Constants

fileprivate struct BackupFileHeader {
    /// Magic number/header for Ledger 8 backup files: "L8BACKUP\0"
    static let magicHeader = Data([0x4C, 0x38, 0x42, 0x41, 0x43, 0x4B, 0x55, 0x50, 0x00])
    static let headerLength = 9 // 8 bytes + null terminator
    
    /// Validates if data starts with the Ledger 8 backup header
    static func isValidBackupFile(_ data: Data) -> Bool {
        guard data.count >= headerLength else { return false }
        let headerData = data.prefix(headerLength)
        return headerData == magicHeader
    }
    
    /// Extracts JSON data from a backup file (removes header if present)
    static func extractJSONData(from data: Data) -> (hasHeader: Bool, jsonData: Data) {
        if isValidBackupFile(data) {
            let jsonData = data.dropFirst(headerLength)
            return (hasHeader: true, jsonData: Data(jsonData))
        } else {
            // Legacy backup without header
            return (hasHeader: false, jsonData: data)
        }
    }
    
    /// Creates backup file data with magic header + JSON
    static func createBackupFileData(jsonData: Data) -> Data {
        var fileData = Data()
        fileData.append(magicHeader)
        fileData.append(jsonData)
        return fileData
    }
}

@MainActor
class BackupManager: ObservableObject {
    @Published var isBackingUp = false
    @Published var isRestoring = false
    @Published var progress: Double = 0.0
    @Published var statusMessage = ""
    @Published var errorMessage: String?
    
    private var modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func updateModelContext(_ context: ModelContext) {
        self.modelContext = context
    }
    
    // MARK: - Backup Creation
    
    func createBackupFile() async throws -> URL {
        isBackingUp = true
        progress = 0.0
        errorMessage = nil
        statusMessage = "Creating backup..."
        
        defer { isBackingUp = false }
        
        do {
            var backup = LedgerBackup()
            
            // Export Clients
            statusMessage = "Backing up clients..."
            let clients = try modelContext.fetch(FetchDescriptor<Client>())
            backup.clients = clients.map { BackupClient(from: $0) }
            progress = 0.33
            
            // Export Projects with client relationships
            statusMessage = "Backing up projects..."
            let projects = try modelContext.fetch(FetchDescriptor<Project>())
            backup.projects = projects.map { BackupProject(from: $0) }
            progress = 0.66
            
            // Export Items with project relationships
            statusMessage = "Backing up items..."
            let items = try modelContext.fetch(FetchDescriptor<Item>())
            backup.items = items.map { BackupItem(from: $0) }
            progress = 0.9
            
            // Create backup file
            statusMessage = "Creating backup file..."
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            
            let jsonData = try encoder.encode(backup)
            
            // Create backup file with magic header
            let backupFileData = BackupFileHeader.createBackupFileData(jsonData: jsonData)
            
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
            let fileName = "Ledger8_Backup_\(formatter.string(from: Date())).json"
            
            // Create Backups folder in Documents directory
            let documentsURL = URL.documentsDirectory
            let backupsURL = documentsURL.appendingPathComponent("Backups")
            
            // Ensure the Backups directory exists
            try FileManager.default.createDirectory(at: backupsURL, withIntermediateDirectories: true)
            
            let fileURL = backupsURL.appendingPathComponent(fileName)
            try backupFileData.write(to: fileURL)
            
            progress = 1.0
            statusMessage = "Backup created successfully!"
            
            return fileURL
            
        } catch {
            errorMessage = "Failed to create backup: \(error.localizedDescription)"
            throw error
        }
    }
    
    // MARK: - Backup Restoration
    
    func restoreFromBackup(fileURL: URL, replaceExisting: Bool = false) async throws {
        isRestoring = true
        progress = 0.0
        errorMessage = nil
        statusMessage = "Reading backup file..."
        
        defer { isRestoring = false }
        
        do {
            guard fileURL.startAccessingSecurityScopedResource() else {
                throw BackupManagerError.fileAccessDenied
            }
            defer { fileURL.stopAccessingSecurityScopedResource() }
            
            let rawData = try Data(contentsOf: fileURL)
            
            // Validate and extract data using magic header
            let headerValidation = BackupFileHeader.extractJSONData(from: rawData)
            
            // Enhanced status message based on header presence
            if headerValidation.hasHeader {
                statusMessage = "Validating Ledger 8 backup file..."
            } else {
                statusMessage = "Reading legacy backup file..."
            }
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            let backup: LedgerBackup
            do {
                backup = try decoder.decode(LedgerBackup.self, from: headerValidation.jsonData)
            } catch {
                // Enhanced error handling based on header presence
                if headerValidation.hasHeader {
                    throw BackupManagerError.corruptedBackup
                } else {
                    throw BackupManagerError.corruptedBackup
                }
            }
            
            // Validate backup
            guard backup.metadata.appVersion.hasPrefix("Ledger 8") else {
                throw BackupManagerError.incompatibleVersion
            }
            
            if replaceExisting {
                try await clearAllData()
            }
            progress = 0.1
            
            // Track created objects for relationships
            var clientMap: [String: Client] = [:]
            var projectMap: [String: Project] = [:]
            
            // Restore clients first
            statusMessage = "Restoring clients..."
            for backupClient in backup.clients {
                let client = Client()
                backupClient.applyTo(client)
                modelContext.insert(client)
                clientMap[backupClient.lookupKey] = client
            }
            progress = 0.4
            
            // Restore projects with client relationships
            statusMessage = "Restoring projects..."
            for backupProject in backup.projects {
                let project = Project()
                backupProject.applyTo(project)
                
                // Link to client if found
                if let clientKey = backupProject.clientLookupKey,
                   let client = clientMap[clientKey] {
                    project.client = client
                }
                
                modelContext.insert(project)
                projectMap[backupProject.lookupKey] = project
            }
            progress = 0.7
            
            // Restore items with project relationships
            statusMessage = "Restoring items..."
            for backupItem in backup.items {
                let item = Item()
                backupItem.applyTo(item)
                
                // Link to project if found
                if let projectKey = backupItem.projectLookupKey,
                   let project = projectMap[projectKey] {
                    item.project = project
                }
                
                modelContext.insert(item)
            }
            progress = 0.9
            
            statusMessage = "Saving restored data..."
            try modelContext.save()
            
            progress = 1.0
            statusMessage = "Backup restored successfully!"
            
        } catch {
            errorMessage = "Failed to restore backup: \(error.localizedDescription)"
            throw error
        }
    }
    
    // MARK: - Clear Data
    
    func clearAllData() async throws {
        // Delete in reverse dependency order
        let items = try modelContext.fetch(FetchDescriptor<Item>())
        for item in items {
            modelContext.delete(item)
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
}

// MARK: - Backup Data Structures

struct LedgerBackup: Codable {
    var metadata = BackupMetadata()
    var clients: [BackupClient] = []
    var projects: [BackupProject] = []
    var items: [BackupItem] = []
}

struct BackupMetadata: Codable {
    var appVersion = "Ledger 8"
    var backupVersion = "1.0"
    var createdDate = Date()
    
    #if canImport(UIKit)
    var deviceName = UIDevice.current.name
    #else
    let deviceName = ProcessInfo.processInfo.hostName
    #endif
}

struct BackupClient: Codable {
    let firstName: String
    let lastName: String
    let email: String
    let phone: String
    let attention: String
    let address: String
    let address2: String
    let city: String
    let state: String
    let zip: String
    let notes: String
    let company: String
    
    // Unique lookup key for relationships
    var lookupKey: String {
        let name = [firstName, lastName, company].filter { !$0.isEmpty }.joined(separator: " ")
        return name.isEmpty ? email : name
    }
    
    init(from client: Client) {
        self.firstName = client.firstName
        self.lastName = client.lastName
        self.email = client.email
        self.phone = client.phone
        self.attention = client.attention
        self.address = client.address
        self.address2 = client.address2
        self.city = client.city
        self.state = client.state
        self.zip = client.zip
        self.notes = client.notes
        self.company = client.company
    }
    
    func applyTo(_ client: Client) {
        client.firstName = firstName
        client.lastName = lastName
        client.email = email
        client.phone = phone
        client.attention = attention
        client.address = address
        client.address2 = address2
        client.city = city
        client.state = state
        client.zip = zip
        client.notes = notes
        client.company = company
    }
}

struct BackupProject: Codable {
    let projectName: String
    let artist: String
    let startDate: Date
    let endDate: Date
    let status: Status
    let mediaType: MediaType
    let notes: String
    let delivered: Bool
    let paid: Bool
    let dateOpened: Date
    let dateDelivered: Date
    let dateClosed: Date
    let endDateSelected: Bool
    let clientLookupKey: String?
    
    // Unique lookup key
    var lookupKey: String {
        "\(projectName)_\(artist)_\(startDate.timeIntervalSince1970)"
    }
    
    init(from project: Project) {
        self.projectName = project.projectName
        self.artist = project.artist
        self.startDate = project.startDate
        self.endDate = project.endDate
        self.status = project.status
        self.mediaType = project.mediaType
        self.notes = project.notes
        self.delivered = project.delivered
        self.paid = project.paid
        self.dateOpened = project.dateOpened
        self.dateDelivered = project.dateDelivered
        self.dateClosed = project.dateClosed
        self.endDateSelected = project.endDateSelected
        
        // Create client lookup key
        if let client = project.client {
            let backupClient = BackupClient(from: client)
            self.clientLookupKey = backupClient.lookupKey
        } else {
            self.clientLookupKey = nil
        }
    }
    
    func applyTo(_ project: Project) {
        project.projectName = projectName
        project.artist = artist
        project.startDate = startDate
        project.endDate = endDate
        project.status = status
        project.mediaType = mediaType
        project.notes = notes
        project.delivered = delivered
        project.paid = paid
        project.dateOpened = dateOpened
        project.dateDelivered = dateDelivered
        project.dateClosed = dateClosed
        project.endDateSelected = endDateSelected
    }
}

struct BackupItem: Codable {
    let name: String
    let fee: Double
    let itemType: ItemType
    let notes: String
    let projectLookupKey: String?
    
    init(from item: Item) {
        self.name = item.name
        self.fee = item.fee
        self.itemType = item.itemType
        self.notes = item.notes
        
        // Create project lookup key
        if let project = item.project {
            let backupProject = BackupProject(from: project)
            self.projectLookupKey = backupProject.lookupKey
        } else {
            self.projectLookupKey = nil
        }
    }
    
    func applyTo(_ item: Item) {
        item.name = name
        item.fee = fee
        item.itemType = itemType
        item.notes = notes
    }
}

// MARK: - Error Types

enum BackupManagerError: LocalizedError {
    case fileAccessDenied
    case incompatibleVersion
    case corruptedBackup
    case exportFailed(String)
    case importFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .fileAccessDenied:
            return "Unable to access the backup file"
        case .incompatibleVersion:
            return "This backup was created with an incompatible version of the app"
        case .corruptedBackup:
            return "The backup file appears to be corrupted"
        case .exportFailed(let details):
            return "Failed to create backup: \(details)"
        case .importFailed(let details):
            return "Failed to restore backup: \(details)"
        }
    }
}
