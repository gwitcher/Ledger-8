//
//  ProjectEdgeCaseTests.swift
//  Ledger 8 Tests
//
//  Created by Test Suite on 10/28/25.
//

import Testing
import SwiftData
import Foundation
import MapKit
@testable import Ledger_8
internal import SwiftUIFontIcon

@Suite("Project Edge Cases and Error Handling Tests")
struct ProjectEdgeCaseTests {
    
    // MARK: - Test Model Container Setup
    private var modelContainer: ModelContainer {
        TestModelContainer.create()
    }
    
    // MARK: - Boundary Condition Tests
    
    @Test("Project handles extremely large fee amounts")
    func testLargeFeeAmounts() async throws {
        let container = modelContainer
        let context = ModelContext(container)
        
        let project = TestDataFactory.createProject()
        let largeItem = TestDataFactory.createItem(
            name: "Extremely High Fee Service",
            fee: 999999.99,
            project: project
        )
        
        project.items = [largeItem]
        
        context.insert(project)
        context.insert(largeItem)
        
        try context.save()
        
        let calculatedTotal = TestHelpers.calculateProjectTotal(project)
        #expect(calculatedTotal == 999999.99)
        #expect(largeItem.fee == 999999.99)
    }
    
    @Test("Project handles zero and negative fees")
    func testZeroAndNegativeFees() async throws {
        let container = modelContainer
        let context = ModelContext(container)
        
        let project = TestDataFactory.createProject()
        let zeroItem = TestDataFactory.createItem(name: "Free Service", fee: 0.0, project: project)
        let negativeItem = TestDataFactory.createItem(name: "Discount", fee: -100.0, project: project)
        let positiveItem = TestDataFactory.createItem(name: "Regular Service", fee: 500.0, project: project)
        
        project.items = [zeroItem, negativeItem, positiveItem]
        
        context.insert(project)
        context.insert(zeroItem)
        context.insert(negativeItem)
        context.insert(positiveItem)
        
        try context.save()
        
        let calculatedTotal = TestHelpers.calculateProjectTotal(project)
        #expect(calculatedTotal == 400.0) // 0 + (-100) + 500 = 400
    }
    
    @Test("Project handles very long text fields")
    func testLongTextFields() async throws {
        let container = modelContainer
        let context = ModelContext(container)
        
        let longProjectName = String(repeating: "A", count: 1000)
        let longArtistName = String(repeating: "B", count: 1000)
        let longNotes = String(repeating: "This is a very long note. ", count: 100)
        
        let project = Project(
            projectName: longProjectName,
            artist: longArtistName,
            notes: longNotes
        )
        
        context.insert(project)
        try context.save()
        
        #expect(project.projectName.count == 1000)
        #expect(project.artist.count == 1000)
        #expect(project.notes.count > 2000)
    }
    
    @Test("Project handles extreme dates")
    func testExtremeDates() async throws {
        let container = modelContainer
        let context = ModelContext(container)
        
        // Test with very old dates
        let oldDate = Calendar.current.date(from: DateComponents(year: 1900, month: 1, day: 1))!
        let futureDate = Calendar.current.date(from: DateComponents(year: 2100, month: 12, day: 31))!
        
        let project = Project(
            projectName: "Extreme Date Project",
            startDate: oldDate,
            endDate: futureDate
        )
        
        context.insert(project)
        try context.save()
        
        #expect(project.startDate == oldDate)
        #expect(project.endDate == futureDate)
        #expect(project.startDate < project.endDate)
    }
    
    // MARK: - Unicode and Special Character Tests
    
    @Test("Project handles unicode and special characters")
    func testUnicodeCharacters() async throws {
        let container = modelContainer
        let context = ModelContext(container)
        
        let client = Client(
            firstName: "José",
            lastName: "Müller-Schmidt",
            email: "josé@müsic-ñotes.com",
            company: "音楽スタジオ" // "Music Studio" in Japanese
        )
        
        let project = Project(
            projectName: "Café de París Recording 🎵",
            artist: "Björk & 中島美嘉",
            notes: "Notes with émojis: 🎼 🎹 🎸 and special chars: @#$%^&*()"
        )
        
        project.client = client
        
        let item = Item(
            name: "Enregistrement en français 🇫🇷",
            fee: 299.99,
            itemType: .session,
            notes: "Notes avec caractères spéciaux: àáâãäåæçèéêëìíîï"
        )
        item.project = project
        project.items = [item]
        
        context.insert(client)
        context.insert(project)
        context.insert(item)
        
        try context.save()
        
        #expect(project.projectName.contains("🎵"))
        #expect(project.artist.contains("&"))
        #expect(client.company == "音楽スタジオ")
        #expect(item.name.contains("🇫🇷"))
    }
    
    // MARK: - Concurrent Access Tests
    
    @Test("Project handles rapid status changes")
    func testRapidStatusChanges() async throws {
        let container = modelContainer
        let context = ModelContext(container)
        
        let project = TestDataFactory.createProject()
        context.insert(project)
        try context.save()
        
        // Simulate rapid status changes that might occur in the UI
        let statuses: [Status] = [.open, .delivered, .closed, .open, .delivered, .closed]
        
        for status in statuses {
            project.status = status
            
            switch status {
            case .open:
                project.delivered = false
                project.paid = false
                project.dateDelivered = Date.distantPast
                project.dateClosed = Date.distantFuture
            case .delivered:
                project.delivered = true
                project.paid = false
                project.dateDelivered = Date()
                project.dateClosed = Date.distantFuture
            case .closed:
                project.delivered = true
                project.paid = true
                project.dateDelivered = Date()
                project.dateClosed = Date()
            }
            
            try context.save()
        }
        
        // Final state should be closed
        #expect(project.status == .closed)
        #expect(project.delivered == true)
        #expect(project.paid == true)
    }
    
    // MARK: - Memory and Performance Edge Cases
    
    @Test("Project handles large number of items")
    func testLargeNumberOfItems() async throws {
        let container = modelContainer
        let context = ModelContext(container)
        
        let project = TestDataFactory.createProject()
        context.insert(project)
        
        let itemCount = 1000
        var items: [Item] = []
        
        for i in 0..<itemCount {
            let item = TestDataFactory.createItem(
                name: "Item \(i)",
                fee: Double(i),
                project: project
            )
            items.append(item)
            context.insert(item)
        }
        
        project.items = items
        
        let startTime = Date()
        try context.save()
        let saveTime = Date().timeIntervalSince(startTime)
        
        #expect(project.items?.count == itemCount)
        #expect(saveTime < 10.0, "Saving \(itemCount) items should take less than 10 seconds")
        
        // Test calculation performance
        let calculationStartTime = Date()
        let total = TestHelpers.calculateProjectTotal(project)
        let calculationTime = Date().timeIntervalSince(calculationStartTime)
        
        // Sum of 0 to 999 = n(n-1)/2 = 999 * 998 / 2 = 498501
        #expect(total == 499500.0) // 0 + 1 + 2 + ... + 999
        #expect(calculationTime < 1.0, "Calculating total should take less than 1 second")
    }
    
    // MARK: - Data Corruption Simulation Tests
    
    @Test("Project handles missing related data gracefully")
    func testMissingRelatedData() async throws {
        let container = modelContainer
        let context = ModelContext(container)
        
        // Create project with client
        let client = TestDataFactory.createClient()
        let project = TestDataFactory.createProject(client: client)
        let item = TestDataFactory.createItem(project: project)
        project.items = [item]
        
        context.insert(client)
        context.insert(project)
        context.insert(item)
        try context.save()
        
        // Simulate data corruption by manually setting relationships to nil
        project.client = nil
        project.items = nil
        
        try context.save()
        
        // Project should still be functional
        #expect(project.client == nil)
        
        // SwiftData initializes to-many relationships as empty arrays, not nil
        // This is expected behavior after saving to SwiftData
        #expect(project.items != nil, "SwiftData initializes to-many relationships as empty arrays")
        #expect(project.items?.isEmpty == true, "Items array should be empty when set to nil")
        #expect(!project.projectName.isEmpty)
        
        // Should be able to calculate total (should be 0 with no items)
        let total = TestHelpers.calculateProjectTotal(project)
        #expect(total == 0.0)
    }
    
    @Test("Project handles circular references")
    func testCircularReferences() async throws {
        let container = modelContainer
        let context = ModelContext(container)
        
        let client = TestDataFactory.createClient()
        let project1 = TestDataFactory.createProject(name: "Project 1", client: client)
        let project2 = TestDataFactory.createProject(name: "Project 2", client: client)
        
        context.insert(client)
        context.insert(project1)
        context.insert(project2)
        
        try context.save()
        
        // Both projects should reference the same client
        #expect(project1.client?.id == client.id)
        #expect(project2.client?.id == client.id)
        #expect(client.project?.count == 2)
        
        // Delete one project, client should still exist with one project
        context.delete(project1)
        try context.save()
        
        #expect(client.project?.count == 1)
        #expect(client.project?.first?.id == project2.id)
    }
    
    // MARK: - Date Edge Cases
    
    @Test("Project handles daylight saving time transitions")
    func testDaylightSavingTransitions() async throws {
        let container = modelContainer
        let context = ModelContext(container)
        
        // Create dates around DST transition (spring forward)
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = 2024
        components.month = 3  // March
        components.day = 10   // DST transition day in 2024
        components.hour = 1   // Before DST
        components.minute = 30
        
        let beforeDST = calendar.date(from: components)!
        components.hour = 3   // After DST (2 AM doesn't exist)
        let afterDST = calendar.date(from: components)!
        
        let project = Project(
            projectName: "DST Test Project",
            startDate: beforeDST,
            endDate: afterDST
        )
        
        context.insert(project)
        try context.save()
        
        #expect(project.startDate == beforeDST)
        #expect(project.endDate == afterDST)
        #expect(project.startDate < project.endDate)
    }
    
    @Test("Project handles leap year dates")
    func testLeapYearDates() async throws {
        let container = modelContainer
        let context = ModelContext(container)
        
        let calendar = Calendar.current
        
        // February 29, 2024 (leap year)
        let leapYearDate = calendar.date(from: DateComponents(year: 2024, month: 2, day: 29))!
        
        let project = Project(
            projectName: "Leap Year Project",
            startDate: leapYearDate,
            endDate: calendar.date(byAdding: .day, value: 1, to: leapYearDate)!
        )
        
        context.insert(project)
        try context.save()
        
        #expect(project.startDate == leapYearDate)
        
        let components = calendar.dateComponents([.year, .month, .day], from: project.startDate)
        #expect(components.year == 2024)
        #expect(components.month == 2)
        #expect(components.day == 29)
    }
    
    // MARK: - Location Edge Cases
    
    @Test("Project handles invalid location coordinates")
    func testInvalidLocationCoordinates() async throws {
        let container = modelContainer
        let context = ModelContext(container)
        
        let project = TestDataFactory.createProject()
        
        // Test with invalid coordinates
        let invalidSpot = Spot(
            name: "Invalid Location",
            address: "Nowhere",
            latitude: 9999.0,  // Invalid latitude (should be -90 to 90)
            longitude: -9999.0, // Invalid longitude (should be -180 to 180)
            addedDate: Date()
        )
        
        project.location = invalidSpot
        
        context.insert(project)
        try context.save()
        
        #expect(project.location?.latitude == 9999.0)
        #expect(project.location?.longitude == -9999.0)
        #expect(project.location?.name == "Invalid Location")
        
        // The app should handle invalid coordinates gracefully when creating Map items
    }
    
    @Test("Project handles empty location data")
    func testEmptyLocationData() async throws {
        let container = modelContainer
        let context = ModelContext(container)
        
        let project = TestDataFactory.createProject()
        
        let emptySpot = Spot(
            name: "",
            address: "",
            latitude: 0.0,
            longitude: 0.0,
            addedDate: Date()
        )
        
        project.location = emptySpot
        
        context.insert(project)
        try context.save()
        
        #expect(project.location?.name == "")
        #expect(project.location?.address == "")
        #expect(project.location?.latitude == 0.0)
        #expect(project.location?.longitude == 0.0)
        
        // Test isEmpty-like functionality
        let mapItem = MKMapItem(placemark: MKPlacemark(
            coordinate: CLLocationCoordinate2D(
                latitude: project.location?.latitude ?? 0.0,
                longitude: project.location?.longitude ?? 0.0
            )
        ))
        mapItem.name = project.location?.name
        let place = Place(mapItem: mapItem)
        
        #expect(place.isEmpty == true)
    }
    
    // MARK: - Invoice Edge Cases
    
    @Test("Project handles duplicate invoice numbers")
    func testDuplicateInvoiceNumbers() async throws {
        let container = modelContainer
        let context = ModelContext(container)
        
        let project1 = TestDataFactory.createProject(name: "Project 1")
        let project2 = TestDataFactory.createProject(name: "Project 2")
        
        let invoice1 = TestDataFactory.createInvoice(number: 1001, name: "Invoice 1")
        let invoice2 = TestDataFactory.createInvoice(number: 1001, name: "Invoice 2") // Duplicate number
        
        project1.invoice = invoice1
        project2.invoice = invoice2
        
        context.insert(project1)
        context.insert(project2)
        context.insert(invoice1)
        context.insert(invoice2)
        
        try context.save()
        
        // Both invoices should exist with same number (if business logic allows)
        #expect(project1.invoice?.number == 1001)
        #expect(project2.invoice?.number == 1001)
        #expect(invoice1.id != invoice2.id) // Different invoices
    }
    
    // MARK: - Search and Query Edge Cases
    
    @Test("Project search handles special query characters")
    func testSearchWithSpecialCharacters() async throws {
        let container = modelContainer
        let context = ModelContext(container)
        
        let specialProject = Project(
            projectName: "Project with \"quotes\" and 'apostrophes'",
            artist: "Artist & Co. (feat. Someone Else)",
            notes: "Notes with % wildcards * and ? characters"
        )
        
        context.insert(specialProject)
        try context.save()
        
        // Test search with quotes
        let quotesDescriptor = FetchDescriptor<Project>(
            predicate: #Predicate<Project> { project in
                project.projectName.localizedStandardContains("quotes")
            }
        )
        let quotesResults = try context.fetch(quotesDescriptor)
        #expect(quotesResults.count == 1)
        
        // Test search with ampersand
        let ampersandDescriptor = FetchDescriptor<Project>(
            predicate: #Predicate<Project> { project in
                project.artist.localizedStandardContains("&")
            }
        )
        let ampersandResults = try context.fetch(ampersandDescriptor)
        #expect(ampersandResults.count == 1)
        
        // Test search with wildcards
        let wildcardDescriptor = FetchDescriptor<Project>(
            predicate: #Predicate<Project> { project in
                project.notes.localizedStandardContains("wildcards")
            }
        )
        let wildcardResults = try context.fetch(wildcardDescriptor)
        #expect(wildcardResults.count == 1)
    }
    
    @Test("Project handles empty search results")
    func testEmptySearchResults() async throws {
        let container = modelContainer
        let context = ModelContext(container)
        
        // Search for something that doesn't exist
        let nonExistentDescriptor = FetchDescriptor<Project>(
            predicate: #Predicate<Project> { project in
                project.projectName.localizedStandardContains("ThisProjectDoesNotExist12345")
            }
        )
        
        let results = try context.fetch(nonExistentDescriptor)
        #expect(results.isEmpty)
        #expect(results.count == 0)
    }
    
    // MARK: - Enumeration Edge Cases
    
    @Test("Project handles all media type cases")
    func testAllMediaTypeCases() async throws {
        let container = modelContainer
        let context = ModelContext(container)
        
        for (index, mediaType) in MediaType.allCases.enumerated() {
            let project = Project(
                projectName: "Project \(index)",
                mediaType: mediaType
            )
            
            context.insert(project)
            
            // Verify media type is properly set
            #expect(project.mediaType == mediaType)
            #expect(project.projectName == "Project \(index)")
        }
        
        try context.save()
        
        // Verify all projects were saved
        let allProjectsDescriptor = FetchDescriptor<Project>()
        let allProjects = try context.fetch(allProjectsDescriptor)
        #expect(allProjects.count == MediaType.allCases.count)
    }
    
    @Test("Project handles all item type cases")
    func testAllItemTypeCases() async throws {
        let container = modelContainer
        let context = ModelContext(container)
        
        let project = TestDataFactory.createProject()
        context.insert(project)
        
        var items: [Item] = []
        
        for (index, itemType) in ItemType.allCases.enumerated() {
            let item = Item(
                name: "Item \(index)",
                fee: Double(index + 1) * 10,
                itemType: itemType
            )
            item.project = project
            items.append(item)
            context.insert(item)
            
            // Verify item type is properly set
            #expect(item.itemType == itemType)
            #expect(item.name == "Item \(index)")
        }
        
        project.items = items
        try context.save()
        
        #expect(project.items?.count == ItemType.allCases.count)
    }
}
