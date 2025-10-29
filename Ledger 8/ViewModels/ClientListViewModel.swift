//
//  ClientListViewModel.swift
//  Ledger 8
//
//  Created by Gabe Witcher on 10/28/25.
//

import Foundation
import SwiftUI
import SwiftData

@Observable
class ClientListViewModel {
    // MARK: - UI State
    var searchText = ""
    var clientSheetIsPresented = false
    
    // MARK: - Data Processing
    
    func sortedClients(from allClients: [Client]) -> [Client] {
        return allClients.sorted { client1, client2 in
            return getSortKey(for: client1) < getSortKey(for: client2)
        }
    }
    
    func filteredClients(from sortedClients: [Client]) -> [Client] {
        if searchText.isEmpty {
            return sortedClients
        } else {
            return sortedClients.filter { client in
                client.firstName.localizedStandardContains(searchText) ||
                client.lastName.localizedStandardContains(searchText) ||
                client.company.localizedStandardContains(searchText)
            }
        }
    }
    
    func groupedClients(from filteredClients: [Client]) -> [String: [Client]] {
        return Dictionary(grouping: filteredClients) { client in
            let letter = getFirstLetter(for: client)
            // Handle non-alphabetic characters
            return letter.rangeOfCharacter(from: CharacterSet.letters) != nil ? letter : "#"
        }
    }
    
    func sortedSectionKeys(from groupedClients: [String: [Client]]) -> [String] {
        return groupedClients.keys.sorted { key1, key2 in
            // Put # section at the end
            if key1 == "#" && key2 != "#" {
                return false
            } else if key1 != "#" && key2 == "#" {
                return true
            } else {
                return key1 < key2
            }
        }
    }
    
    // MARK: - Business Logic Methods
    
    func deleteClient(_ client: Client, from modelContext: ModelContext) {
        modelContext.delete(client)
        
        do {
            try modelContext.save()
        } catch {
            print("😡 ERROR: Could not save after delete: \(error)")
        }
    }
    
    // MARK: - UI Actions
    
    func showNewClientSheet() {
        clientSheetIsPresented = true
    }
    
    // MARK: - Private Helper Methods
    
    /// Get the sort key for a client based on priority: lastName > firstName > company
    private func getSortKey(for client: Client) -> String {
        if !client.lastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return client.lastName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        } else if !client.firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return client.firstName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        } else if !client.company.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return client.company.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        } else {
            return "" // Empty string sorts last
        }
    }
    
    /// Get the first letter for grouping based on the same logic as sorting
    private func getFirstLetter(for client: Client) -> String {
        if !client.lastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return String(client.lastName.trimmingCharacters(in: .whitespacesAndNewlines).prefix(1)).uppercased()
        } else if !client.firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return String(client.firstName.trimmingCharacters(in: .whitespacesAndNewlines).prefix(1)).uppercased()
        } else if !client.company.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return String(client.company.trimmingCharacters(in: .whitespacesAndNewlines).prefix(1)).uppercased()
        } else {
            return "#" // For clients with no name/company
        }
    }
}