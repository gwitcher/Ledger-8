//
//  CSVImporter.swift
//  Ledger 8
//
//  Created by CSV Import System
//

import Foundation
import SwiftData
import UniformTypeIdentifiers

@MainActor
class CSVImporter: ObservableObject {
    @Published var importProgress: Double = 0
    @Published var isImporting: Bool = false
    @Published var importStatus: String = ""
    @Published var importError: String?
    
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Main Import Function
    func importFromCSV(fileURL: URL) async throws {
        isImporting = true
        importProgress = 0
        importError = nil
        importStatus = "Reading CSV file..."
        
        defer {
            isImporting = false
        }
        
        // Read CSV file
        guard fileURL.startAccessingSecurityScopedResource() else {
            throw CSVImportError.fileAccessDenied
        }
        
        defer {
            fileURL.stopAccessingSecurityScopedResource()
        }
        
        let csvData = try String(contentsOf: fileURL, encoding: .utf8)
        let lines = csvData.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        guard !lines.isEmpty else {
            throw CSVImportError.emptyFile
        }
        
        // Parse header to determine CSV type
        let header = lines[0]
        let csvType = determineCSVType(from: header)
        
        importStatus = "Detected \(csvType.displayName) format"
        
        // Import based on type
        switch csvType {
        case .projects:
            try await importProjects(from: lines)
        case .items:
            try await importItems(from: lines)
        case .clients:
            try await importClients(from: lines)
        case .ledgerAnalytics:
            try await importLedgerAnalytics(from: lines)
        case .unknown:
            throw CSVImportError.unknownFormat
        }
        
        // Save context
        importStatus = "Saving to database..."
        try modelContext.save()
        
        importProgress = 1.0
        importStatus = "Import completed successfully!"
    }
    
    // MARK: - CSV Type Detection
    private func determineCSVType(from header: String) -> CSVType {
        let columns = parseCSVLine(header).map { $0.lowercased() }
        
        // Check for your specific CSV format (Project, Artist, Client, Date, Media Type, Income, Paid)
        if columns.contains("project") && columns.contains("income") && columns.contains("media type") {
            return .ledgerAnalytics
        }
        
        // Check for standard project headers
        if columns.contains("projectname") || columns.contains("project_name") {
            return .projects
        }
        
        // Check for item headers
        if columns.contains("itemname") || columns.contains("item_name") || (columns.contains("name") && columns.contains("fee")) {
            return .items
        }
        
        // Check for client headers
        if columns.contains("firstname") || columns.contains("first_name") {
            return .clients
        }
        
        return .unknown
    }
    
    // MARK: - Project Import
    private func importProjects(from lines: [String]) async throws {
        guard lines.count > 1 else { return }
        
        let header = parseCSVLine(lines[0]).map { $0.lowercased().replacingOccurrences(of: " ", with: "") }
        let dataLines = Array(lines[1...])
        
        for (index, line) in dataLines.enumerated() {
            let values = parseCSVLine(line)
            
            guard values.count >= header.count else {
                continue // Skip malformed lines
            }
            
            let project = Project()
            
            for (columnIndex, columnName) in header.enumerated() {
                let value = values[columnIndex].trimmingCharacters(in: .whitespacesAndNewlines)
                
                switch columnName {
                case "projectname", "project_name", "project":
                    project.projectName = value
                case "artist":
                    project.artist = value
                case "startdate", "start_date", "start":
                    project.startDate = parseDate(value) ?? Date()
                case "enddate", "end_date", "end":
                    project.endDate = parseDate(value) ?? Date()
                case "status":
                    project.status = Status(rawValue: value) ?? .open
                case "mediatype", "media_type", "media":
                    project.mediaType = MediaType(rawValue: value) ?? .recording
                case "notes":
                    project.notes = value
                case "delivered":
                    project.delivered = parseBool(value)
                case "paid":
                    project.paid = parseBool(value)
                default:
                    break
                }
            }
            
            modelContext.insert(project)
            
            importProgress = Double(index + 1) / Double(dataLines.count) * 0.8
            importStatus = "Importing project \(index + 1) of \(dataLines.count)"
        }
    }
    
    // MARK: - Item Import
    private func importItems(from lines: [String]) async throws {
        guard lines.count > 1 else { return }
        
        let header = parseCSVLine(lines[0]).map { $0.lowercased().replacingOccurrences(of: " ", with: "") }
        let dataLines = Array(lines[1...])
        
        // Get existing projects for linking
        let existingProjects = try modelContext.fetch(FetchDescriptor<Project>())
        let projectDict = Dictionary(uniqueKeysWithValues: existingProjects.map { ($0.projectName, $0) })
        
        for (index, line) in dataLines.enumerated() {
            let values = parseCSVLine(line)
            
            guard values.count >= header.count else {
                continue
            }
            
            let item = Item()
            var projectName: String?
            
            for (columnIndex, columnName) in header.enumerated() {
                let value = values[columnIndex].trimmingCharacters(in: .whitespacesAndNewlines)
                
                switch columnName {
                case "name", "itemname", "item_name":
                    item.name = value
                case "fee", "amount", "price":
                    item.fee = Double(value) ?? 0.0
                case "itemtype", "item_type", "type":
                    item.itemType = ItemType(rawValue: value) ?? .other
                case "notes":
                    item.notes = value
                case "project", "projectname", "project_name":
                    projectName = value
                default:
                    break
                }
            }
            
            // Link to project if found
            if let projectName = projectName, let project = projectDict[projectName] {
                item.project = project
            }
            
            modelContext.insert(item)
            
            importProgress = Double(index + 1) / Double(dataLines.count) * 0.8
            importStatus = "Importing item \(index + 1) of \(dataLines.count)"
        }
    }
    
    // MARK: - Client Import
    private func importClients(from lines: [String]) async throws {
        guard lines.count > 1 else { return }
        
        let header = parseCSVLine(lines[0]).map { $0.lowercased().replacingOccurrences(of: " ", with: "") }
        let dataLines = Array(lines[1...])
        
        for (index, line) in dataLines.enumerated() {
            let values = parseCSVLine(line)
            
            guard values.count >= header.count else {
                continue
            }
            
            let client = Client()
            
            for (columnIndex, columnName) in header.enumerated() {
                let value = values[columnIndex].trimmingCharacters(in: .whitespacesAndNewlines)
                
                switch columnName {
                case "firstname", "first_name":
                    client.firstName = value
                case "lastname", "last_name":
                    client.lastName = value
                case "email":
                    client.email = value
                case "phone":
                    client.phone = value
                case "attention", "attn":
                    client.attention = value
                case "address":
                    client.address = value
                case "address2":
                    client.address2 = value
                case "city":
                    client.city = value
                case "state":
                    client.state = value
                case "zip", "zipcode":
                    client.zip = value
                case "notes":
                    client.notes = value
                case "company":
                    client.company = value
                default:
                    break
                }
            }
            
            modelContext.insert(client)
            
            importProgress = Double(index + 1) / Double(dataLines.count) * 0.8
            importStatus = "Importing client \(index + 1) of \(dataLines.count)"
        }
    }
    
    // MARK: - Ledger Analytics Import
    private func importLedgerAnalytics(from lines: [String]) async throws {
        guard lines.count > 1 else { return }
        
        let header = parseCSVLine(lines[0]).map { $0.lowercased().replacingOccurrences(of: " ", with: "") }
        let dataLines = Array(lines[1...])
        
        // Filter out summary lines
        let projectLines = dataLines.filter { line in
            !line.lowercased().contains("summary") && 
            !line.lowercased().contains("total projects") &&
            !line.lowercased().contains("total income") &&
            !line.lowercased().contains("paid income") &&
            !line.lowercased().contains("unpaid income")
        }
        
        // Track clients and projects to avoid duplicates
        var clientDict: [String: Client] = [:]
        var projectDict: [String: Project] = [:]
        
        // Get existing data to avoid duplicates
        let existingProjects = try modelContext.fetch(FetchDescriptor<Project>())
        let existingClients = try modelContext.fetch(FetchDescriptor<Client>())
        
        for project in existingProjects {
            projectDict[project.projectName] = project
        }
        
        for client in existingClients {
            let key = client.company.isEmpty ? client.fullName : client.company
            clientDict[key] = client
        }
        
        for (index, line) in projectLines.enumerated() {
            let values = parseCSVLine(line)
            
            guard values.count >= header.count else {
                continue
            }
            
            var projectName = ""
            var artistName = ""
            var clientName = ""
            var date: Date = Date()
            var mediaType = MediaType.recording
            var income: Double = 0.0
            var isPaid = false
            
            // Parse CSV values
            for (columnIndex, columnName) in header.enumerated() {
                let value = values[columnIndex].trimmingCharacters(in: .whitespacesAndNewlines)
                
                switch columnName {
                case "project":
                    projectName = value
                case "artist":
                    artistName = value
                case "client":
                    clientName = value
                case "date":
                    date = parseDate(value) ?? Date()
                case "mediatype":
                    mediaType = mapToMediaType(value)
                case "income":
                    income = Double(value) ?? 0.0
                case "paid":
                    isPaid = parseBool(value)
                default:
                    break
                }
            }
            
            // Create or get client
            var client: Client?
            if !clientName.isEmpty && clientDict[clientName] == nil {
                let newClient = Client()
                if clientName.contains(" ") {
                    let nameParts = clientName.components(separatedBy: " ")
                    newClient.firstName = nameParts.first ?? ""
                    newClient.lastName = nameParts.dropFirst().joined(separator: " ")
                } else {
                    newClient.company = clientName
                }
                modelContext.insert(newClient)
                clientDict[clientName] = newClient
                client = newClient
            } else if !clientName.isEmpty {
                client = clientDict[clientName]
            }
            
            // Create or get project
            var project: Project
            let projectKey = "\(projectName)_\(artistName)".trimmingCharacters(in: .whitespacesAndNewlines)
            
            if let existingProject = projectDict[projectKey] {
                project = existingProject
            } else {
                project = Project()
                project.projectName = projectName
                project.artist = artistName
                project.startDate = date
                project.endDate = date
                project.mediaType = mediaType
                project.status = isPaid ? .closed : .open
                project.paid = isPaid
                project.client = client
                
                modelContext.insert(project)
                projectDict[projectKey] = project
            }
            
            // Create item for this income entry
            let item = Item()
            item.name = projectName.isEmpty ? "Service" : projectName
            item.fee = income
            item.itemType = mapToItemType(mediaType)
            item.project = project
            
            modelContext.insert(item)
            
            importProgress = Double(index + 1) / Double(projectLines.count) * 0.8
            importStatus = "Importing entry \(index + 1) of \(projectLines.count)"
        }
    }
    
    // Helper functions for mapping your CSV data
    private func mapToMediaType(_ value: String) -> MediaType {
        switch value.lowercased() {
        case "film": return .film
        case "tv": return .tv
        case "recording": return .recording
        case "video game", "game": return .game
        case "concert": return .concert
        case "tour": return .tour
        case "lesson": return .lesson
        case "other": return .other
        default: return .recording
        }
    }
    
    private func mapToItemType(_ mediaType: MediaType) -> ItemType {
        switch mediaType {
        case .film: return .production
        case .tv: return .production
        case .recording: return .session
        case .game: return .production
        case .concert: return .concert
        case .tour: return .tour
        case .lesson: return .lesson
        case .other: return .other
        }
    }
    
    // MARK: - Utility Functions
    private func parseCSVLine(_ line: String) -> [String] {
        var fields: [String] = []
        var currentField = ""
        var insideQuotes = false
        var i = line.startIndex
        
        while i < line.endIndex {
            let char = line[i]
            
            if char == "\"" {
                insideQuotes.toggle()
            } else if char == "," && !insideQuotes {
                fields.append(currentField)
                currentField = ""
            } else {
                currentField.append(char)
            }
            
            i = line.index(after: i)
        }
        
        fields.append(currentField)
        return fields
    }
    
    private func parseDate(_ dateString: String) -> Date? {
        // Try ISO 8601 format first
        let iso8601Formatter = ISO8601DateFormatter()
        if let date = iso8601Formatter.date(from: dateString) {
            return date
        }
        
        let formatters: [DateFormatter] = [
            {
                let formatter = DateFormatter()
                formatter.dateFormat = "MM/dd/yyyy"
                return formatter
            }(),
            {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                return formatter
            }(),
            {
                let formatter = DateFormatter()
                formatter.dateFormat = "M/d/yy"
                return formatter
            }()
        ]
        
        for formatter in formatters {
            if let date = formatter.date(from: dateString) {
                return date
            }
        }
        
        return nil
    }
    
    private func parseBool(_ value: String) -> Bool {
        let lowercased = value.lowercased()
        return lowercased == "true" || lowercased == "yes" || lowercased == "1"
    }
}

// MARK: - Supporting Types
enum CSVType {
    case projects
    case items
    case clients
    case ledgerAnalytics
    case unknown
    
    var displayName: String {
        switch self {
        case .projects: return "Projects"
        case .items: return "Items"
        case .clients: return "Clients"
        case .ledgerAnalytics: return "Ledger Analytics"
        case .unknown: return "Unknown"
        }
    }
}

enum CSVImportError: LocalizedError {
    case fileAccessDenied
    case emptyFile
    case unknownFormat
    case invalidData(String)
    
    var errorDescription: String? {
        switch self {
        case .fileAccessDenied:
            return "Unable to access the selected file"
        case .emptyFile:
            return "The selected file is empty"
        case .unknownFormat:
            return "Unable to determine the CSV format. Please ensure your CSV has proper headers."
        case .invalidData(let details):
            return "Invalid data found: \(details)"
        }
    }
}