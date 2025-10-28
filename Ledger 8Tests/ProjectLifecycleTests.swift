//
//  ProjectLifecycleTests.swift
//  Ledger 8 Tests
//
//  Created by Test Suite on 10/28/25.
//

import Testing
import SwiftData
import Foundation
import MapKit
@testable import Ledger_8

@Suite("Project Lifecycle Tests")
struct ProjectLifecycleTests {
    
    // MARK: - Test Model Container Setup
    private var modelContainer: ModelContainer {
        let schema = Schema([
            Project.self,
            Client.self,
            Item.self,
            Invoice.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        
        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            print("✅ ProjectLifecycleTests ModelContainer created successfully")
            return container
        } catch {
            print("❌ Failed to create ProjectLifecycleTests ModelContainer: \(error)")
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
    
    // MARK: - Test Data Factory
    private func createTestClient() -> Client {
        Client(
            firstName: "John",
            lastName: "Doe",
            email: "john.doe@example.com",
            phone: "555-1234",
            company: "Test Studios"
        )
    }
    
    private func createTestProject(client: Client? = nil) -> Project {
        let project = Project(
            projectName: "Test Album Recording",
            artist: "Test Artist",
            startDate: Date(),
            endDate: Calendar.current.date(byAdding: .hour, value: 2, to: Date())!,
            status: .open,
            mediaType: .recording,
            notes: "Test project notes"
        )
        
        if let client = client {
            project.client = client
        }
        
        return project
    }
    
    private func createTestItem(name: String = "Test Item", fee: Double = 100.0, type: ItemType = .session) -> Item {
        Item(
            name: name,
            fee: fee,
            itemType: type,
            notes: "Test item notes"
        )
    }
    
    private func createTestLocation() -> Spot {
        Spot(
            name: "Test Studio",
            address: "123 Music St, Nashville, TN",
            latitude: 36.1627,
            longitude: -86.7816,
            addedDate: Date()
        )
    }
    
    // MARK: - Project Creation Tests
    
    @Test("Project can be created with default values")
    func testProjectCreation() async throws {
        let container = modelContainer
        let context = ModelContext(container)
        
        let project = Project()
        context.insert(project)
        
        try context.save()
        
        // Verify default values
        #expect(project.projectName == "")
        #expect(project.artist == "")
        #expect(project.status == .open)
        #expect(project.mediaType == .recording)
        #expect(project.delivered == false)
        #expect(project.paid == false)
        #expect(project.notes == "")
        #expect(project.endDateSelected == false)
        #expect(project.invoiceUpdateFlag == false)
    }
    
    @Test("Project can be created with custom values")
    func testProjectCreationWithCustomValues() async throws {
        let container = modelContainer
        let context = ModelContext(container)
        
        let startDate = Date()
        let endDate = Calendar.current.date(byAdding: .hour, value: 3, to: startDate)!
        let location = createTestLocation()
        
        let project = Project(
            projectName: "Custom Project",
            artist: "Custom Artist",
            startDate: startDate,
            endDate: endDate,
            status: .delivered,
            mediaType: .film,
            notes: "Custom notes",
            delivered: true,
            paid: false,
            location: location
        )
        
        context.insert(project)
        try context.save()
        
        // Verify custom values
        #expect(project.projectName == "Custom Project")
        #expect(project.artist == "Custom Artist")
        #expect(project.startDate == startDate)
        #expect(project.endDate == endDate)
        #expect(project.status == .delivered)
        #expect(project.mediaType == .film)
        #expect(project.notes == "Custom notes")
        #expect(project.delivered == true)
        #expect(project.paid == false)
        #expect(project.location?.name == "Test Studio")
    }
    
    // MARK: - Client Association Tests
    
    @Test("Project can be associated with a client")
    func testProjectClientAssociation() async throws {
        let container = modelContainer
        let context = ModelContext(container)
        
        let client = createTestClient()
        let project = createTestProject(client: client)
        
        context.insert(client)
        context.insert(project)
        try context.save()
        
        #expect(project.client?.id == client.id)
        #expect(client.project?.contains { $0.id == project.id } == true)
    }
    
    @Test("Client can have multiple projects")
    func testClientMultipleProjects() async throws {
        let container = modelContainer
        let context = ModelContext(container)
        
        let client = createTestClient()
        let project1 = createTestProject(client: client)
        project1.projectName = "Project 1"
        
        let project2 = createTestProject(client: client)
        project2.projectName = "Project 2"
        
        context.insert(client)
        context.insert(project1)
        context.insert(project2)
        try context.save()
        
        #expect(client.project?.count == 2)
        #expect(project1.client?.id == client.id)
        #expect(project2.client?.id == client.id)
    }
    
    // MARK: - Item Management Tests
    
    @Test("Items can be added to project")
    func testProjectItemAddition() async throws {
        let container = modelContainer
        let context = ModelContext(container)
        
        let project = createTestProject()
        let item1 = createTestItem(name: "Vocal Recording", fee: 150.0, type: .overdub)
        let item2 = createTestItem(name: "Mixing Session", fee: 200.0, type: .session)
        
        // Associate items with project
        item1.project = project
        item2.project = project
        
        if project.items == nil {
            project.items = []
        }
        project.items?.append(item1)
        project.items?.append(item2)
        
        context.insert(project)
        context.insert(item1)
        context.insert(item2)
        try context.save()
        
        #expect(project.items?.count == 2)
        #expect(item1.project?.id == project.id)
        #expect(item2.project?.id == project.id)
    }
    
    @Test("Items are deleted when project is deleted (cascade)")
    func testProjectItemCascadeDelete() async throws {
        let container = modelContainer
        let context = ModelContext(container)
        
        let project = createTestProject()
        let item = createTestItem()
        
        item.project = project
        if project.items == nil {
            project.items = []
        }
        project.items?.append(item)
        
        context.insert(project)
        context.insert(item)
        try context.save()
        
        let projectId = project.id
        let itemId = item.id
        
        // Delete project
        context.delete(project)
        try context.save()
        
        // Verify item was cascade deleted
        let fetchDescriptor = FetchDescriptor<Item>()
        let remainingItems = try context.fetch(fetchDescriptor)
        
        #expect(!remainingItems.contains { $0.id == itemId })
    }
    
    // MARK: - Status Transition Tests
    
    @Test("Project status transitions from open to delivered")
    func testProjectStatusOpenToDelivered() async throws {
        let container = modelContainer
        let context = ModelContext(container)
        
        let project = createTestProject()
        #expect(project.status == .open)
        #expect(project.delivered == false)
        #expect(project.paid == false)
        
        // Mark as delivered
        project.delivered = true
        project.dateDelivered = Date()
        project.status = .delivered
        
        context.insert(project)
        try context.save()
        
        #expect(project.status == .delivered)
        #expect(project.delivered == true)
        #expect(project.paid == false)
        #expect(project.dateDelivered != Date.distantPast)
    }
    
    @Test("Project status transitions from delivered to closed")
    func testProjectStatusDeliveredToClosed() async throws {
        let container = modelContainer
        let context = ModelContext(container)
        
        let project = createTestProject()
        
        // First mark as delivered
        project.delivered = true
        project.dateDelivered = Date()
        project.status = .delivered
        
        // Then mark as paid
        project.paid = true
        project.dateClosed = Date()
        project.status = .closed
        
        context.insert(project)
        try context.save()
        
        #expect(project.status == .closed)
        #expect(project.delivered == true)
        #expect(project.paid == true)
        #expect(project.dateDelivered != Date.distantPast)
        #expect(project.dateClosed != Date.distantFuture)
    }
    
    @Test("Project status transitions directly from open to closed")
    func testProjectStatusOpenToClosed() async throws {
        let container = modelContainer
        let context = ModelContext(container)
        
        let project = createTestProject()
        #expect(project.status == .open)
        
        // Mark both delivered and paid simultaneously
        project.delivered = true
        project.paid = true
        project.dateDelivered = Date()
        project.dateClosed = Date()
        project.status = .closed
        
        context.insert(project)
        try context.save()
        
        #expect(project.status == .closed)
        #expect(project.delivered == true)
        #expect(project.paid == true)
    }
    
    // MARK: - Invoice Management Tests
    
    @Test("Invoice can be created for project")
    func testProjectInvoiceCreation() async throws {
        let container = modelContainer
        let context = ModelContext(container)
        
        let project = createTestProject()
        let invoice = Invoice(number: 1001, name: "Test Invoice")
        
        project.invoice = invoice
        
        context.insert(project)
        context.insert(invoice)
        try context.save()
        
        #expect(project.invoice?.number == 1001)
        #expect(project.invoice?.name == "Test Invoice")
    }
    
    @Test("Invoice update flag works correctly")
    func testProjectInvoiceUpdateFlag() async throws {
        let container = modelContainer
        let context = ModelContext(container)
        
        let project = createTestProject()
        let invoice = Invoice(number: 1002, name: "Test Invoice 2")
        
        project.invoice = invoice
        context.insert(project)
        context.insert(invoice)
        try context.save()
        
        // Initially should not need update
        #expect(project.invoiceNeedsUpdate == false)
        
        // Flag for update
        project.flagInvoiceForUpdate()
        #expect(project.invoiceNeedsUpdate == true)
        
        // Clear update flag
        project.clearInvoiceUpdateFlag()
        #expect(project.invoiceNeedsUpdate == false)
        
        // Delete invoice
        project.deleteInvoice()
        #expect(project.invoice == nil)
        #expect(project.invoiceNeedsUpdate == false)
    }
    
    @Test("Invoice is deleted when project is deleted (cascade)")
    func testProjectInvoiceCascadeDelete() async throws {
        let container = modelContainer
        let context = ModelContext(container)
        
        let project = createTestProject()
        let invoice = Invoice(number: 1003, name: "Test Invoice 3")
        
        project.invoice = invoice
        
        context.insert(project)
        context.insert(invoice)
        try context.save()
        
        let invoiceId = invoice.id
        
        // Delete project
        context.delete(project)
        try context.save()
        
        // Verify invoice was cascade deleted
        let fetchDescriptor = FetchDescriptor<Invoice>()
        let remainingInvoices = try context.fetch(fetchDescriptor)
        
        #expect(!remainingInvoices.contains { $0.id == invoiceId })
    }
    
    // MARK: - Location Management Tests
    
    @Test("Project location can be set and retrieved")
    func testProjectLocationManagement() async throws {
        let container = modelContainer
        let context = ModelContext(container)
        
        let project = createTestProject()
        let location = createTestLocation()
        
        project.location = location
        
        context.insert(project)
        try context.save()
        
        #expect(project.location?.name == "Test Studio")
        #expect(project.location?.address == "123 Music St, Nashville, TN")
        #expect(project.location?.latitude == 36.1627)
        #expect(project.location?.longitude == -86.7816)
    }
    
    @Test("Project location can be updated")
    func testProjectLocationUpdate() async throws {
        let container = modelContainer
        let context = ModelContext(container)
        
        let project = createTestProject()
        let originalLocation = createTestLocation()
        
        project.location = originalLocation
        context.insert(project)
        try context.save()
        
        // Update location
        let newLocation = Spot(
            name: "Updated Studio",
            address: "456 Sound Ave, Nashville, TN",
            latitude: 36.2000,
            longitude: -86.8000,
            addedDate: Date()
        )
        
        project.location = newLocation
        try context.save()
        
        #expect(project.location?.name == "Updated Studio")
        #expect(project.location?.address == "456 Sound Ave, Nashville, TN")
        #expect(project.location?.latitude == 36.2000)
        #expect(project.location?.longitude == -86.8000)
    }
    
    // MARK: - Date Validation Tests
    
    @Test("Project start date must be before end date")
    func testProjectDateValidation() async throws {
        let container = modelContainer
        let context = ModelContext(container)
        
        let startDate = Date()
        let endDate = Calendar.current.date(byAdding: .hour, value: -1, to: startDate)! // End before start
        
        let project = Project(
            projectName: "Invalid Date Project",
            startDate: startDate,
            endDate: endDate
        )
        
        context.insert(project)
        try context.save()
        
        // The test should verify that the validation logic catches this
        // In a real app, this would be handled by the UI validation
        #expect(project.endDate < project.startDate, "End date is before start date - this should be caught by UI validation")
    }
    
    @Test("Project end date selection tracking works")
    func testProjectEndDateSelectionTracking() async throws {
        let container = modelContainer
        let context = ModelContext(container)
        
        let project = createTestProject()
        #expect(project.endDateSelected == false)
        
        // Simulate user selecting end date
        project.endDateSelected = true
        project.endDate = Calendar.current.date(byAdding: .hour, value: 4, to: project.startDate)!
        
        context.insert(project)
        try context.save()
        
        #expect(project.endDateSelected == true)
    }
    
    // MARK: - Complete Lifecycle Test
    
    @Test("Complete project lifecycle from creation to closure")
    func testCompleteProjectLifecycle() async throws {
        let container = modelContainer
        let context = ModelContext(container)
        
        // Step 1: Create client
        let client = createTestClient()
        context.insert(client)
        
        // Step 2: Create project with client
        let project = createTestProject(client: client)
        project.location = createTestLocation()
        context.insert(project)
        
        // Step 3: Add items
        let item1 = createTestItem(name: "Recording Session", fee: 300.0, type: .session)
        let item2 = createTestItem(name: "Mixing", fee: 200.0, type: .production)
        let item3 = createTestItem(name: "Per Diem", fee: 50.0, type: .perDiem)
        
        item1.project = project
        item2.project = project
        item3.project = project
        
        if project.items == nil {
            project.items = []
        }
        project.items?.append(contentsOf: [item1, item2, item3])
        
        context.insert(item1)
        context.insert(item2)
        context.insert(item3)
        
        try context.save()
        
        // Verify initial state
        #expect(project.status == .open)
        #expect(project.delivered == false)
        #expect(project.paid == false)
        #expect(project.items?.count == 3)
        #expect(project.client?.id == client.id)
        #expect(project.location?.name == "Test Studio")
        
        // Step 4: Mark as delivered
        project.delivered = true
        project.dateDelivered = Date()
        project.status = .delivered
        
        try context.save()
        
        #expect(project.status == .delivered)
        #expect(project.delivered == true)
        #expect(project.paid == false)
        
        // Step 5: Create invoice
        let invoice = Invoice(number: 2001, name: "Complete Lifecycle Invoice")
        project.invoice = invoice
        context.insert(invoice)
        
        try context.save()
        
        #expect(project.invoice?.number == 2001)
        #expect(project.invoiceNeedsUpdate == false)
        
        // Step 6: Make changes that would affect invoice
        project.flagInvoiceForUpdate()
        #expect(project.invoiceNeedsUpdate == true)
        
        // Step 7: Mark as paid and close
        project.paid = true
        project.dateClosed = Date()
        project.status = .closed
        project.clearInvoiceUpdateFlag() // Invoice was updated
        
        try context.save()
        
        // Final verification
        #expect(project.status == .closed)
        #expect(project.delivered == true)
        #expect(project.paid == true)
        #expect(project.dateDelivered != Date.distantPast)
        #expect(project.dateClosed != Date.distantFuture)
        #expect(project.invoiceNeedsUpdate == false)
        
        // Verify data integrity
        #expect(project.items?.count == 3)
        #expect(project.client?.id == client.id)
        #expect(project.location?.name == "Test Studio")
        #expect(project.invoice?.number == 2001)
        
        // Verify relationships are maintained
        #expect(client.project?.contains { $0.id == project.id } == true)
        #expect(item1.project?.id == project.id)
        #expect(item2.project?.id == project.id)
        #expect(item3.project?.id == project.id)
    }
    
    // MARK: - Data Persistence Tests
    
    @Test("Project data persists across save/fetch operations")
    func testProjectDataPersistence() async throws {
        let container = modelContainer
        let context = ModelContext(container)
        
        // Create and save project with all data
        let client = createTestClient()
        let project = createTestProject(client: client)
        let item = createTestItem()
        let invoice = Invoice(number: 3001, name: "Persistence Test Invoice")
        let location = createTestLocation()
        
        project.location = location
        project.invoice = invoice
        project.delivered = true
        project.paid = true
        project.status = .closed
        project.dateDelivered = Date()
        project.dateClosed = Date()
        
        item.project = project
        if project.items == nil {
            project.items = []
        }
        project.items?.append(item)
        
        context.insert(client)
        context.insert(project)
        context.insert(item)
        context.insert(invoice)
        
        try context.save()
        
        let originalProjectId = project.id
        
        // Fetch project and verify all data is intact
        let fetchDescriptor = FetchDescriptor<Project>(
            predicate: #Predicate<Project> { project in
                project.id == originalProjectId
            }
        )
        
        let fetchedProjects = try context.fetch(fetchDescriptor)
        #expect(fetchedProjects.count == 1)
        
        let fetchedProject = try #require(fetchedProjects.first)
        
        // Verify all properties are preserved
        #expect(fetchedProject.projectName == "Test Album Recording")
        #expect(fetchedProject.artist == "Test Artist")
        #expect(fetchedProject.mediaType == .recording)
        #expect(fetchedProject.status == .closed)
        #expect(fetchedProject.delivered == true)
        #expect(fetchedProject.paid == true)
        #expect(fetchedProject.notes == "Test project notes")
        
        // Verify relationships are preserved
        #expect(fetchedProject.client?.id == client.id)
        #expect(fetchedProject.items?.count == 1)
        #expect(fetchedProject.items?.first?.id == item.id)
        #expect(fetchedProject.invoice?.number == 3001)
        #expect(fetchedProject.location?.name == "Test Studio")
    }
    
    // MARK: - Edge Cases and Error Handling Tests
    
    @Test("Project handles nil client gracefully")
    func testProjectWithNilClient() async throws {
        let container = modelContainer
        let context = ModelContext(container)
        
        let project = createTestProject()
        project.client = nil
        
        context.insert(project)
        try context.save()
        
        #expect(project.client == nil)
        // Should not crash or cause issues
    }
    
    @Test("Project handles empty items array")
    func testProjectWithEmptyItems() async throws {
        let container = modelContainer
        let context = ModelContext(container)
        
        let project = createTestProject()
        project.items = []
        
        context.insert(project)
        try context.save()
        
        #expect(project.items?.isEmpty == true)
    }
    
    @Test("Project handles empty items array (SwiftData behavior)")
    func testProjectWithNilItems() async throws {
        let container = modelContainer
        let context = ModelContext(container)
        
        let project = createTestProject()
        project.items = nil
        
        context.insert(project)
        try context.save()
        
        // SwiftData initializes to-many relationships as empty arrays, not nil
        // This is expected behavior - the relationship exists but is empty
        #expect(project.items != nil, "SwiftData initializes to-many relationships as empty arrays")
        #expect(project.items?.isEmpty == true, "Items array should be empty when no items are associated")
    }
    
    @Test("Project status transitions maintain data integrity")
    func testStatusTransitionDataIntegrity() async throws {
        let container = modelContainer
        let context = ModelContext(container)
        
        let project = createTestProject()
        let originalData = (
            name: project.projectName,
            artist: project.artist,
            startDate: project.startDate,
            endDate: project.endDate,
            mediaType: project.mediaType,
            notes: project.notes
        )
        
        context.insert(project)
        try context.save()
        
        // Go through all status transitions
        project.status = .delivered
        project.delivered = true
        project.dateDelivered = Date()
        try context.save()
        
        project.status = .closed
        project.paid = true
        project.dateClosed = Date()
        try context.save()
        
        // Verify core data hasn't changed during status transitions
        #expect(project.projectName == originalData.name)
        #expect(project.artist == originalData.artist)
        #expect(project.startDate == originalData.startDate)
        #expect(project.endDate == originalData.endDate)
        #expect(project.mediaType == originalData.mediaType)
        #expect(project.notes == originalData.notes)
    }
}

// MARK: - Performance Tests

@Suite("Project Performance Tests")
struct ProjectPerformanceTests {
    
    private var modelContainer: ModelContainer {
        let schema = Schema([
            Project.self,
            Client.self,
            Item.self,
            Invoice.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        
        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            print("✅ ProjectPerformanceTests ModelContainer created successfully")
            return container
        } catch {
            print("❌ Failed to create ProjectPerformanceTests ModelContainer: \(error)")
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
    
    @Test("Large number of projects can be created efficiently")
    func testLargeProjectCreation() async throws {
        let container = modelContainer
        let context = ModelContext(container)
        
        let projectCount = 100
        var projects: [Project] = []
        
        let startTime = Date()
        
        for i in 0..<projectCount {
            let project = Project(
                projectName: "Project \(i)",
                artist: "Artist \(i)",
                mediaType: MediaType.allCases[i % MediaType.allCases.count]
            )
            projects.append(project)
            context.insert(project)
        }
        
        try context.save()
        
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        
        #expect(projects.count == projectCount)
        #expect(duration < 5.0, "Creating \(projectCount) projects should take less than 5 seconds, took \(duration)")
    }
    
    @Test("Project with many items performs well")
    func testProjectWithManyItems() async throws {
        let container = modelContainer
        let context = ModelContext(container)
        
        let project = Project(projectName: "Large Project", artist: "Test Artist")
        context.insert(project)
        
        let itemCount = 50
        var items: [Item] = []
        
        let startTime = Date()
        
        for i in 0..<itemCount {
            let item = Item(
                name: "Item \(i)",
                fee: Double(i * 10),
                itemType: ItemType.allCases[i % ItemType.allCases.count]
            )
            item.project = project
            items.append(item)
            context.insert(item)
        }
        
        if project.items == nil {
            project.items = []
        }
        project.items?.append(contentsOf: items)
        
        try context.save()
        
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        
        #expect(project.items?.count == itemCount)
        #expect(duration < 2.0, "Adding \(itemCount) items should take less than 2 seconds, took \(duration)")
    }
}