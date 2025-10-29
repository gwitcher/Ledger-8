//
//  ClientSelectViewModel.swift
//  Ledger 8
//
//  Created by MVVM Refactoring Assistant
//

import Foundation
import SwiftData
import SwiftUI
import Combine

@Observable
class ClientSelectViewModel {
    // MARK: - Published Properties (UI State)
    var searchText: String = ""
    var showingNewClientSheet: Bool = false
    var isLoading: Bool = false
    var errorMessage: String = ""
    var showError: Bool = false
    
    // MARK: - Data Properties
    var allClients: [Client] = []
    var selectedClient: Client?
    
    // MARK: - Computed Properties
    var filteredClients: [Client] {
        if searchText.isEmpty {
            return allClients
        } else {
            return allClients.filter { client in
                client.firstName.localizedStandardContains(searchText) ||
                client.lastName.localizedStandardContains(searchText) ||
                client.company.localizedStandardContains(searchText) ||
                client.email.localizedStandardContains(searchText)
            }
        }
    }
    
    var groupedClients: [(key: String, value: [Client])] {
        let grouped = Dictionary(grouping: filteredClients) { client in
            getGroupingKey(for: client)
        }
        return grouped.sorted { $0.key < $1.key }
    }
    
    var hasClients: Bool {
        !allClients.isEmpty
    }
    
    var isEmpty: Bool {
        allClients.isEmpty
    }
    
    // MARK: - Dependencies
    private var modelContext: ModelContext?
    
    // MARK: - Initialization
    init() {
        // Initialize with empty state - clients will be loaded when model context is set
    }
    
    // MARK: - Public Methods
    
    /// Sets the model context and loads initial data
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        loadClients()
    }
    
    /// Loads all clients from the database
    func loadClients() {
        guard let modelContext = modelContext else {
            handleError("Model context not available")
            return
        }
        
        isLoading = true
        
        do {
            let descriptor = FetchDescriptor<Client>(
                sortBy: [SortDescriptor(\Client.firstName), SortDescriptor(\Client.lastName)]
            )
            allClients = try modelContext.fetch(descriptor)
            isLoading = false
        } catch {
            handleError("Failed to load clients: \(error.localizedDescription)")
        }
    }
    
    /// Selects a client and provides feedback
    func selectClient(_ client: Client) {
        selectedClient = client
        
        // Add haptic feedback for better user experience
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        print("✅ ClientSelectViewModel: Selected client - \(client.fullName)")
    }
    
    /// Clears the current selection
    func clearSelection() {
        selectedClient = nil
    }
    
    /// Shows the new client creation sheet
    func showNewClientSheet() {
        showingNewClientSheet = true
    }
    
    /// Hides the new client creation sheet
    func hideNewClientSheet() {
        showingNewClientSheet = false
        // Reload clients in case a new one was added
        loadClients()
    }
    
    /// Clears the search text
    func clearSearch() {
        searchText = ""
    }
    
    /// Updates search text and provides search analytics
    func updateSearch(_ text: String) {
        searchText = text
        
        // Optional: Add search analytics or debouncing here
        if !text.isEmpty {
            print("🔍 Searching for: '\(text)' - Found \(filteredClients.count) results")
        }
    }
    
    // MARK: - Private Methods
    
    /// Determines the grouping key for alphabetical sections
    private func getGroupingKey(for client: Client) -> String {
        // Priority: lastName -> firstName -> company -> fallback
        if !client.lastName.isEmpty {
            return String(client.lastName.prefix(1)).uppercased()
        } else if !client.firstName.isEmpty {
            return String(client.firstName.prefix(1)).uppercased()
        } else if !client.company.isEmpty {
            return String(client.company.prefix(1)).uppercased()
        } else {
            return "#" // For clients with no meaningful name data
        }
    }
    
    /// Handles errors and updates UI state
    private func handleError(_ message: String) {
        print("❌ ClientSelectViewModel Error: \(message)")
        errorMessage = message
        showError = true
        isLoading = false
    }
    
    // MARK: - Search Enhancement Methods
    
    /// Provides search suggestions based on current input
    var searchSuggestions: [String] {
        guard !searchText.isEmpty else { return [] }
        
        let suggestions = Set(allClients.compactMap { client -> [String] in
            var suggestions: [String] = []
            
            // Add company names
            if !client.company.isEmpty && 
               client.company.localizedStandardContains(searchText) {
                suggestions.append(client.company)
            }
            
            // Add full names
            if !client.fullName.isEmpty && 
               client.fullName.localizedStandardContains(searchText) {
                suggestions.append(client.fullName)
            }
            
            return suggestions
        }.flatMap { $0 })
        
        return Array(suggestions).sorted().prefix(3).map { $0 }
    }
    
    /// Returns the number of search results
    var searchResultsCount: Int {
        filteredClients.count
    }
    
    /// Indicates if search is active
    var isSearching: Bool {
        !searchText.isEmpty
    }
}

// MARK: - Extension for View Integration
extension ClientSelectViewModel {
    /// Creates a binding for the selected client that can be used with Views
    func selectedClientBinding() -> Binding<Client?> {
        Binding(
            get: { self.selectedClient },
            set: { self.selectedClient = $0 }
        )
    }
    
    /// Creates a binding for search text
    func searchTextBinding() -> Binding<String> {
        Binding(
            get: { self.searchText },
            set: { self.updateSearch($0) }
        )
    }
}