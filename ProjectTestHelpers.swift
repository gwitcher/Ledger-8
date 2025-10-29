//
//  ProjectTestHelpers.swift
//  Ledger 8 Tests
//
//  Created by Test Suite on 10/28/25.
//

import Testing
import SwiftData
import Foundation
@testable import Ledger_8

/// Shared test helpers and data factories for Project tests
struct ProjectTestHelpers {
    
    // MARK: - Model Container Factory
    static func createTestModelContainer() -> ModelContainer {
        let schema = Schema([
            Project.self,
            Client.self,
            Item.self,
            Invoice.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        
        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            return container
        } catch {
            fatalError("Could not create test ModelContainer: \(error)")
        }
    }
    
    // MARK: - Test Data Factories
    static func createTestProject(
        name: String = "Test Project",
        artist: String = "Test Artist",
        mediaType: MediaType = .recording,
        status: Status = .open
    ) -> Project {
        Project(
            projectName: name,
            artist: artist,
            status: status,
            mediaType: mediaType
        )
    }
    
    static func createTestClient(
        firstName: String = "John",
        lastName: String = "Doe",
        email: String = "john.doe@test.com",
        company: String = "Test Company"
    ) -> Client {
        Client(
            firstName: firstName,
            lastName: lastName,
            email: email,
            company: company
        )
    }
    
    static func createTestItems(for project: Project? = nil) -> [Item] {
        [
            Item(name: "Recording Session", fee: 250.0, itemType: .session, project: project),
            Item(name: "Mixing", fee: 150.0, itemType: .production, project: project),
            Item(name: "Per Diem", fee: 75.0, itemType: .perDiem, project: project)
        ]
    }
    
    // MARK: - Test Assertions Helpers
    static func assertProjectStatusUpdate(
        project: Project,
        delivered: Bool,
        paid: Bool,
        expectedStatus: Status
    ) {
        project.delivered = delivered
        project.paid = paid
        
        // Business logic for status updates
        if delivered && paid {
            project.status = .closed
        } else if delivered && !paid {
            project.status = .delivered
        } else if !delivered && paid {
            project.status = .closed
        } else {
            project.status = .open
        }
        
        #expect(project.status == expectedStatus)
    }
}