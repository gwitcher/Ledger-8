//
//  ClientSelectViewModelTests.swift
//  Ledger 8 Tests
//
//  Created by MVVM Refactoring Assistant
//

import Testing
import SwiftData
import Foundation
@testable import Ledger_8

@Suite("ClientSelectViewModel Tests")
struct ClientSelectViewModelTests {
    
    // MARK: - Test Model Container Setup
    private var modelContainer: ModelContainer {
        TestModelContainer.create()
    }
    
    // MARK: - Initialization Tests
    
    @Test("ViewModel initializes with correct default state")
    func testInitialization() async throws {
        let viewModel = ClientSelectViewModel()
        
        #expect(viewModel.searchText.isEmpty)
        #expect(viewModel.showingNewClientSheet == false)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.allClients.isEmpty)
        #expect(viewModel.selectedClient == nil)
        #expect(viewModel.isEmpty == true)
        #expect(viewModel.hasClients == false)
    }
    
    // MARK: - Data Loading Tests
    
    @Test("ViewModel loads clients from database correctly")
    func testLoadClients() async throws {
        let container = modelContainer
        let context = ModelContext(container)
        let viewModel = ClientSelectViewModel()
        
        // Create test clients
        let client1 = TestDataFactory.createClient(firstName: "Alice", lastName: "Smith")
        let client2 = TestDataFactory.createClient(firstName: "Bob", lastName: "Johnson")
        let client3 = TestDataFactory.createClient(firstName: "Charlie", lastName: "Brown")
        
        context.insert(client1)
        context.insert(client2)
        context.insert(client3)
        try context.save()
        
        // Load clients through ViewModel
        viewModel.setModelContext(context)
        
        #expect(viewModel.allClients.count == 3)
        #expect(viewModel.hasClients == true)
        #expect(viewModel.isEmpty == false)
        #expect(viewModel.isLoading == false)
    }
    
    @Test("ViewModel handles empty database gracefully")
    func testLoadEmptyDatabase() async throws {
        let container = modelContainer
        let context = ModelContext(container)
        let viewModel = ClientSelectViewModel()
        
        viewModel.setModelContext(context)
        
        #expect(viewModel.allClients.isEmpty)
        #expect(viewModel.hasClients == false)
        #expect(viewModel.isEmpty == true)
        #expect(viewModel.isLoading == false)
    }
    
    // MARK: - Search Functionality Tests
    
    @Test("Search filters clients correctly by first name")
    func testSearchByFirstName() async throws {
        let container = modelContainer
        let context = ModelContext(container)
        let viewModel = ClientSelectViewModel()
        
        let alice = TestDataFactory.createClient(firstName: "Alice", lastName: "Smith")
        let bob = TestDataFactory.createClient(firstName: "Bob", lastName: "Johnson")
        let alicia = TestDataFactory.createClient(firstName: "Alicia", lastName: "Brown")
        
        context.insert(alice)
        context.insert(bob)
        context.insert(alicia)
        try context.save()
        
        viewModel.setModelContext(context)
        viewModel.updateSearch("Ali")
        
        #expect(viewModel.filteredClients.count == 2)
        #expect(viewModel.filteredClients.contains(where: { $0.firstName == "Alice" }))
        #expect(viewModel.filteredClients.contains(where: { $0.firstName == "Alicia" }))
        #expect(!viewModel.filteredClients.contains(where: { $0.firstName == "Bob" }))
    }
    
    @Test("Search filters clients correctly by last name")
    func testSearchByLastName() async throws {
        let container = modelContainer
        let context = ModelContext(container)
        let viewModel = ClientSelectViewModel()
        
        let smithAlice = TestDataFactory.createClient(firstName: "Alice", lastName: "Smith")
        let smithBob = TestDataFactory.createClient(firstName: "Bob", lastName: "Smith")
        let johnson = TestDataFactory.createClient(firstName: "Charlie", lastName: "Johnson")
        
        context.insert(smithAlice)
        context.insert(smithBob)
        context.insert(johnson)
        try context.save()
        
        viewModel.setModelContext(context)
        viewModel.updateSearch("Smith")
        
        #expect(viewModel.filteredClients.count == 2)
        #expect(viewModel.filteredClients.allSatisfy { $0.lastName == "Smith" })
        #expect(viewModel.searchResultsCount == 2)
        #expect(viewModel.isSearching == true)
    }
    
    @Test("Search filters clients correctly by company")
    func testSearchByCompany() async throws {
        let container = modelContainer
        let context = ModelContext(container)
        let viewModel = ClientSelectViewModel()
        
        let appleEmployee = TestDataFactory.createClient(
            firstName: "Tim",
            lastName: "Cook",
            company: "Apple Inc."
        )
        let googleEmployee = TestDataFactory.createClient(
            firstName: "Sundar",
            lastName: "Pichai", 
            company: "Google LLC"
        )
        
        context.insert(appleEmployee)
        context.insert(googleEmployee)
        try context.save()
        
        viewModel.setModelContext(context)
        viewModel.updateSearch("Apple")
        
        #expect(viewModel.filteredClients.count == 1)
        #expect(viewModel.filteredClients.first?.company == "Apple Inc.")
    }
    
    @Test("Search is case insensitive")
    func testCaseInsensitiveSearch() async throws {
        let container = modelContainer
        let context = ModelContext(container)
        let viewModel = ClientSelectViewModel()
        
        let client = TestDataFactory.createClient(firstName: "Alice", lastName: "SMITH")
        context.insert(client)
        try context.save()
        
        viewModel.setModelContext(context)
        
        // Test various case combinations
        viewModel.updateSearch("alice")
        #expect(viewModel.filteredClients.count == 1)
        
        viewModel.updateSearch("ALICE")
        #expect(viewModel.filteredClients.count == 1)
        
        viewModel.updateSearch("smith")
        #expect(viewModel.filteredClients.count == 1)
        
        viewModel.updateSearch("Smith")
        #expect(viewModel.filteredClients.count == 1)
    }
    
    @Test("Empty search returns all clients")
    func testEmptySearch() async throws {
        let container = modelContainer
        let context = ModelContext(container)
        let viewModel = ClientSelectViewModel()
        
        let client1 = TestDataFactory.createClient(firstName: "Alice")
        let client2 = TestDataFactory.createClient(firstName: "Bob") 
        let client3 = TestDataFactory.createClient(firstName: "Charlie")
        
        context.insert(client1)
        context.insert(client2)
        context.insert(client3)
        try context.save()
        
        viewModel.setModelContext(context)
        viewModel.updateSearch("")
        
        #expect(viewModel.filteredClients.count == 3)
        #expect(viewModel.isSearching == false)
    }
    
    // MARK: - Client Grouping Tests
    
    @Test("Clients are grouped correctly by last name")
    func testClientGroupingByLastName() async throws {
        let container = modelContainer
        let context = ModelContext(container)
        let viewModel = ClientSelectViewModel()
        
        let alice = TestDataFactory.createClient(firstName: "Alice", lastName: "Anderson")
        let bob = TestDataFactory.createClient(firstName: "Bob", lastName: "Brown")  
        let charlie = TestDataFactory.createClient(firstName: "Charlie", lastName: "Anderson")
        
        context.insert(alice)
        context.insert(bob)
        context.insert(charlie)
        try context.save()
        
        viewModel.setModelContext(context)
        
        let grouped = viewModel.groupedClients
        
        #expect(grouped.count == 2) // "A" and "B" groups
        
        let aGroup = grouped.first { $0.key == "A" }
        let bGroup = grouped.first { $0.key == "B" }
        
        #expect(aGroup?.value.count == 2) // Alice and Charlie Anderson
        #expect(bGroup?.value.count == 1) // Bob Brown
    }
    
    @Test("Clients without last name are grouped by first name")
    func testClientGroupingByFirstName() async throws {
        let container = modelContainer
        let context = ModelContext(container)
        let viewModel = ClientSelectViewModel()
        
        let alice = TestDataFactory.createClient(firstName: "Alice", lastName: "")
        let bob = TestDataFactory.createClient(firstName: "Bob", lastName: "")
        
        context.insert(alice)
        context.insert(bob)
        try context.save()
        
        viewModel.setModelContext(context)
        
        let grouped = viewModel.groupedClients
        
        #expect(grouped.count == 2) // "A" and "B" groups
        #expect(grouped.contains { $0.key == "A" && $0.value.count == 1 })
        #expect(grouped.contains { $0.key == "B" && $0.value.count == 1 })
    }
    
    @Test("Clients without names are grouped by company")
    func testClientGroupingByCompany() async throws {
        let container = modelContainer
        let context = ModelContext(container)
        let viewModel = ClientSelectViewModel()
        
        let appleClient = TestDataFactory.createClient(
            firstName: "",
            lastName: "",
            company: "Apple Inc."
        )
        let googleClient = TestDataFactory.createClient(
            firstName: "",
            lastName: "",
            company: "Google LLC"
        )
        
        context.insert(appleClient)
        context.insert(googleClient)
        try context.save()
        
        viewModel.setModelContext(context)
        
        let grouped = viewModel.groupedClients
        
        #expect(grouped.count == 2) // "A" and "G" groups
        #expect(grouped.contains { $0.key == "A" && $0.value.first?.company == "Apple Inc." })
        #expect(grouped.contains { $0.key == "G" && $0.value.first?.company == "Google LLC." })
    }
    
    @Test("Clients with no identifying info are grouped under '#'")
    func testClientGroupingFallback() async throws {
        let container = modelContainer
        let context = ModelContext(container)
        let viewModel = ClientSelectViewModel()
        
        let emptyClient = TestDataFactory.createClient(firstName: "", lastName: "", company: "")
        context.insert(emptyClient)
        try context.save()
        
        viewModel.setModelContext(context)
        
        let grouped = viewModel.groupedClients
        
        #expect(grouped.count == 1)
        #expect(grouped.first?.key == "#")
        #expect(grouped.first?.value.count == 1)
    }
    
    // MARK: - Client Selection Tests
    
    @Test("Client selection updates selected client")
    func testClientSelection() async throws {
        let container = modelContainer
        let context = ModelContext(container)
        let viewModel = ClientSelectViewModel()
        
        let client = TestDataFactory.createClient(firstName: "Alice", lastName: "Smith")
        context.insert(client)
        try context.save()
        
        viewModel.setModelContext(context)
        viewModel.selectClient(client)
        
        #expect(viewModel.selectedClient?.id == client.id)
        #expect(viewModel.selectedClient?.fullName == "Alice Smith")
    }
    
    @Test("Client selection can be cleared")
    func testClientSelectionClearing() async throws {
        let container = modelContainer
        let context = ModelContext(container)
        let viewModel = ClientSelectViewModel()
        
        let client = TestDataFactory.createClient(firstName: "Alice")
        context.insert(client)
        try context.save()
        
        viewModel.setModelContext(context)
        viewModel.selectClient(client)
        #expect(viewModel.selectedClient != nil)
        
        viewModel.clearSelection()
        #expect(viewModel.selectedClient == nil)
    }
    
    // MARK: - UI State Tests
    
    @Test("New client sheet state management")
    func testNewClientSheetState() async throws {
        let viewModel = ClientSelectViewModel()
        
        #expect(viewModel.showingNewClientSheet == false)
        
        viewModel.showNewClientSheet()
        #expect(viewModel.showingNewClientSheet == true)
        
        viewModel.hideNewClientSheet()
        #expect(viewModel.showingNewClientSheet == false)
    }
    
    @Test("Search suggestions are generated correctly")
    func testSearchSuggestions() async throws {
        let container = modelContainer
        let context = ModelContext(container)
        let viewModel = ClientSelectViewModel()
        
        let apple = TestDataFactory.createClient(firstName: "Tim", lastName: "Cook", company: "Apple Inc.")
        let appleMusic = TestDataFactory.createClient(firstName: "Eddie", lastName: "Cue", company: "Apple Music")
        
        context.insert(apple)
        context.insert(appleMusic)
        try context.save()
        
        viewModel.setModelContext(context)
        viewModel.updateSearch("App")
        
        let suggestions = viewModel.searchSuggestions
        #expect(suggestions.count <= 3) // Limited to 3 suggestions
        #expect(suggestions.contains("Apple Inc.") || suggestions.contains("Apple Music"))
    }
    
    // MARK: - Error Handling Tests
    
    @Test("ViewModel handles database errors gracefully")
    func testErrorHandling() async throws {
        let viewModel = ClientSelectViewModel()
        
        // Try to load without setting model context
        viewModel.loadClients()
        
        #expect(viewModel.showError == true)
        #expect(!viewModel.errorMessage.isEmpty)
        #expect(viewModel.isLoading == false)
    }
    
    // MARK: - Performance Tests
    
    @Test("ViewModel handles large number of clients efficiently")
    func testLargeDataSetPerformance() async throws {
        let container = modelContainer
        let context = ModelContext(container)
        let viewModel = ClientSelectViewModel()
        
        // Create 1000 test clients
        for i in 0..<1000 {
            let client = TestDataFactory.createClient(
                firstName: "Client",
                lastName: "\(i)",
                company: "Company \(i % 100)"
            )
            context.insert(client)
        }
        try context.save()
        
        let startTime = Date()
        viewModel.setModelContext(context)
        let loadTime = Date().timeIntervalSince(startTime)
        
        #expect(loadTime < 2.0, "Loading 1000 clients should take less than 2 seconds")
        #expect(viewModel.allClients.count == 1000)
        
        // Test search performance
        let searchStartTime = Date()
        viewModel.updateSearch("Client")
        let searchTime = Date().timeIntervalSince(searchStartTime)
        
        #expect(searchTime < 0.5, "Searching 1000 clients should take less than 0.5 seconds")
        #expect(viewModel.filteredClients.count == 1000)
    }
}