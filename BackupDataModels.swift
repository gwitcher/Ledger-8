//
//  BackupDataModels.swift
//  Ledger 8
//
//  Created by MVVM Refactoring on 10/28/25.
//

import Foundation

// MARK: - App Settings Backup

struct BackupAppSettings: Codable {
    var userData: Data?
    var initialInvoiceNumber: Int?
    
    init() {
        self.userData = UserDefaults.standard.data(forKey: "userData")
        self.initialInvoiceNumber = UserDefaults.standard.object(forKey: "InitialInvoiceNumber") as? Int
    }
    
    static func current() -> BackupAppSettings {
        return BackupAppSettings()
    }
    
    func applyToCurrentApp() {
        if let userData = userData {
            UserDefaults.standard.set(userData, forKey: "userData")
        }
        
        if let initialInvoiceNumber = initialInvoiceNumber {
            UserDefaults.standard.set(initialInvoiceNumber, forKey: "InitialInvoiceNumber")
        }
    }
}

// MARK: - Client Backup

struct CompleteBackupClient: Codable {
    let lookupKey: String
    let name: String
    let address: String
    let phoneNumber: String
    let emailAddress: String
    let notes: String
    
    init(from client: Client) {
        self.lookupKey = client.persistentModelID.hashValue.description
        self.name = client.name
        self.address = client.address
        self.phoneNumber = client.phoneNumber
        self.emailAddress = client.emailAddress
        self.notes = client.notes
    }
    
    func applyTo(_ client: Client) {
        client.name = name
        client.address = address
        client.phoneNumber = phoneNumber
        client.emailAddress = emailAddress
        client.notes = notes
    }
}

// MARK: - Project Backup

struct CompleteBackupProject: Codable {
    let lookupKey: String
    let name: String
    let notes: String
    let isCompleted: Bool
    let clientLookupKey: String?
    
    // Location data
    let locationName: String?
    let locationAddress: String?
    let locationNotes: String?
    let latitude: Double?
    let longitude: Double?
    
    init(from project: Project) {
        self.lookupKey = project.persistentModelID.hashValue.description
        self.name = project.name
        self.notes = project.notes
        self.isCompleted = project.isCompleted
        self.clientLookupKey = project.client?.persistentModelID.hashValue.description
        
        // Location data
        if let location = project.location {
            self.locationName = location.name
            self.locationAddress = location.address
            self.locationNotes = location.notes
            self.latitude = location.latitude
            self.longitude = location.longitude
        } else {
            self.locationName = nil
            self.locationAddress = nil
            self.locationNotes = nil
            self.latitude = nil
            self.longitude = nil
        }
    }
    
    func applyTo(_ project: Project) {
        project.name = name
        project.notes = notes
        project.isCompleted = isCompleted
        
        // Apply location if data exists
        if let locationName = locationName {
            let location = Location(
                name: locationName,
                address: locationAddress ?? "",
                notes: locationNotes ?? ""
            )
            
            if let latitude = latitude, let longitude = longitude {
                location.latitude = latitude
                location.longitude = longitude
            }
            
            project.location = location
        }
    }
}

// MARK: - Item Backup

struct CompleteBackupItem: Codable {
    let name: String
    let itemDescription: String
    let isCompleted: Bool
    let projectLookupKey: String?
    
    init(from item: Item) {
        self.name = item.name
        self.itemDescription = item.itemDescription
        self.isCompleted = item.isCompleted
        self.projectLookupKey = item.project?.persistentModelID.hashValue.description
    }
    
    func applyTo(_ item: Item) {
        item.name = name
        item.itemDescription = itemDescription
        item.isCompleted = isCompleted
    }
}

// MARK: - Invoice Backup

struct CompleteBackupInvoice: Codable {
    let number: String
    let name: String
    let urlString: String?
    let projectLookupKey: String?
    
    init(from invoice: Invoice, project: Project?) {
        self.number = invoice.number
        self.name = invoice.name
        self.urlString = invoice.url?.absoluteString
        self.projectLookupKey = project?.persistentModelID.hashValue.description
    }
    
    func applyTo(_ invoice: Invoice) {
        // Note: number and name are set during Invoice initialization
        // URL is handled during restoration
    }
}

// MARK: - Location Model (if not already defined)

// This should match your existing Location model
// If Location is already defined elsewhere, remove this

#if !LOCATION_MODEL_DEFINED
class Location {
    var name: String
    var address: String
    var notes: String
    var latitude: Double?
    var longitude: Double?
    
    init(name: String, address: String, notes: String) {
        self.name = name
        self.address = address
        self.notes = notes
    }
}
#endif