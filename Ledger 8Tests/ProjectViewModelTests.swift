//
//  ProjectViewModelTests.swift
//  Ledger 8 Tests
//
//  Created by Test Suite on 10/28/25.
//

import Testing
import SwiftData
import Foundation
@testable import Ledger_8

@Suite("Project ViewModel Tests")
struct ProjectViewModelTests {
    
    private var modelContainer: ModelContainer {
        TestModelContainer.create()
    }
    
    // MARK: - ProjectDetailViewModel Tests
    
    @Test("ProjectDetailViewModel initializes correctly")
    func testProjectDetailViewModelInitialization() async throws {
        let container = modelContainer
        let context = ModelContext(container)
        let project = TestDataFactory.createProject()
        
        let viewModel = ProjectDetailViewModel(project: project, modelContext: context)
        
        #expect(viewModel.project.id == project.id)
        #expect(!viewModel.isLoading)
        #expect(viewModel.errorMessage == nil)
        #expect(!viewModel.hasUnsavedChanges)
    }
    
    @Test("ProjectDetailViewModel handles status transitions")
    func testProjectDetailViewModelStatusTransitions() async throws {
        let container = modelContainer
        let context = ModelContext(container)
        let project = TestDataFactory.createProject()
        context.insert(project)
        
        let viewModel = ProjectDetailViewModel(project: project, modelContext: context)
        
        // Test marking as delivered
        await viewModel.markAsDelivered()
        #expect(project.status == .delivered)
        #expect(project.delivered == true)
        #expect(!viewModel.hasUnsavedChanges) // Should be saved
        
        // Test marking as paid
        await viewModel.markAsPaid()
        #expect(project.status == .closed)
        #expect(project.paid == true)
        #expect(project.delivered == true) // Should remain true
        
        // Test resetting to open
        await viewModel.markAsOpen()
        #expect(project.status == .open)
        #expect(project.delivered == false)
        #expect(project.paid == false)
    }
    
    @Test("ProjectDetailViewModel handles date management")
    func testProjectDetailViewModelDateManagement() async throws {
        let container = modelContainer
        let context = ModelContext(container)
        let project = TestDataFactory.createProject()
        
        let viewModel = ProjectDetailViewModel(project: project, modelContext: context)
        
        let newStartDate = Date()
        let originalEndDate = project.endDate
        
        // Test start date update with auto end date adjustment
        viewModel.updateStartDate(newStartDate)
        #expect(project.startDate == newStartDate)
        #expect(project.endDate != originalEndDate) // Should be auto-updated
        #expect(viewModel.hasUnsavedChanges)
        
        // Test manual end date setting
        let manualEndDate = Calendar.current.date(byAdding: .hour, value: 3, to: newStartDate)!
        viewModel.updateEndDate(manualEndDate)
        #expect(project.endDate == manualEndDate)
        #expect(project.endDateSelected == true)
        #expect(viewModel.endDateWasManuallySet == true)
    }
    
    @Test("ProjectDetailViewModel calculates fees correctly")
    func testProjectDetailViewModelFeeCalculations() async throws {
        let container = modelContainer
        let context = ModelContext(container)
        let project = TestDataFactory.createProject()
        let items = TestDataFactory.createRecordingItems(project: project)
        project.items = items
        
        let viewModel = ProjectDetailViewModel(project: project, modelContext: context)
        
        let expectedTotal = items.reduce(0) { $0 + $1.fee }
        
        #expect(viewModel.totalFee == expectedTotal)
        #expect(!viewModel.formattedTotalFee.isEmpty)
        #expect(viewModel.formattedTotalFee.contains("$"))
        
        let feesByType = viewModel.feesByItemType
        #expect(!feesByType.isEmpty)
    }
    
    @Test("ProjectDetailViewModel handles item management")
    func testProjectDetailViewModelItemManagement() async throws {
        let container = modelContainer
        let context = ModelContext(container)
        let project = TestDataFactory.createProject()
        context.insert(project)
        
        let viewModel = ProjectDetailViewModel(project: project, modelContext: context)
        
        let initialItemCount = project.items?.count ?? 0
        let newItem = TestDataFactory.createItem(name: "New Item", fee: 100.0)
        
        // Test adding item
        await viewModel.addItem(newItem)
        #expect(project.items?.count == initialItemCount + 1)
        #expect(newItem.project?.id == project.id)
        
        // Test removing item
        await viewModel.removeItem(newItem)
        #expect(project.items?.count == initialItemCount)
    }
    
    @Test("ProjectDetailViewModel validates project data")
    func testProjectDetailViewModelValidation() async throws {
        let container = modelContainer
        let context = ModelContext(container)
        
        // Test invalid project (empty name)
        let invalidProject = Project(projectName: "")
        let viewModel1 = ProjectDetailViewModel(project: invalidProject, modelContext: context)
        
        #expect(!viewModel1.isValid)
        #expect(!viewModel1.validationErrors.isEmpty)
        #expect(viewModel1.validationErrors.contains { $0.contains("required") })
        
        // Test valid project
        let validProject = TestDataFactory.createProject()
        let viewModel2 = ProjectDetailViewModel(project: validProject, modelContext: context)
        
        #expect(viewModel2.isValid)
        #expect(viewModel2.validationErrors.isEmpty)
    }
    
    @Test("ProjectDetailViewModel creates template projects")
    func testProjectDetailViewModelTemplateCreation() async throws {
        let container = modelContainer
        let context = ModelContext(container)
        let templateProject = TestDataFactory.createFilmProject()
        
        let viewModel = ProjectDetailViewModel(project: templateProject, modelContext: context)
        let newProject = viewModel.createProjectFromTemplate()
        
        // Verify template data was copied
        #expect(newProject.projectName == templateProject.projectName)
        #expect(newProject.artist == templateProject.artist)
        #expect(newProject.mediaType == templateProject.mediaType)
        #expect(newProject.notes == templateProject.notes)
        
        // Verify new project has fresh state
        #expect(newProject.status == .open)
        #expect(!newProject.delivered)
        #expect(!newProject.paid)
        #expect(newProject.id != templateProject.id)
    }
    
    // MARK: - ProjectListViewModel Tests
    
    @Test("ProjectListViewModel initializes correctly")
    func testProjectListViewModelInitialization() async throws {
        let container = modelContainer
        let context = ModelContext(container)
        
        let viewModel = ProjectListViewModel(modelContext: context)
        
        #expect(viewModel.projects.isEmpty)
        #expect(viewModel.filteredProjects.isEmpty)
        #expect(!viewModel.isLoading)
        #expect(viewModel.searchText.isEmpty)
        #expect(viewModel.selectedStatus == nil)
        #expect(viewModel.sortOption == .dateOpened)
    }
    
    @Test("ProjectListViewModel loads and filters projects")
    func testProjectListViewModelFiltering() async throws {
        let container = modelContainer
        let context = ModelContext(container)
        
        // Create test projects with different properties
        let openProject = TestDataFactory.createProject(name: "Open Project", status: .open)
        let deliveredProject = TestDataFactory.createProject(name: "Delivered Project", status: .delivered)
        let closedProject = TestDataFactory.createProject(name: "Closed Project", status: .closed)
        let filmProject = TestDataFactory.createProject(name: "Film Project", mediaType: .film)
        
        context.insert(openProject)
        context.insert(deliveredProject)
        context.insert(closedProject)
        context.insert(filmProject)
        try context.save()
        
        let viewModel = ProjectListViewModel(modelContext: context)
        await viewModel.loadProjects()
        
        #expect(viewModel.projects.count == 4)
        #expect(viewModel.filteredProjects.count == 4)
        
        // Test status filtering
        viewModel.selectedStatus = .open
        #expect(viewModel.filteredProjects.count == 1)
        #expect(viewModel.filteredProjects.first?.status == .open)
        
        // Test media type filtering
        viewModel.selectedStatus = nil
        viewModel.selectedMediaType = .film
        #expect(viewModel.filteredProjects.count == 1)
        #expect(viewModel.filteredProjects.first?.mediaType == .film)
        
        // Test search filtering
        viewModel.selectedMediaType = nil
        viewModel.searchText = "Film"
        #expect(viewModel.filteredProjects.count == 1)
        #expect(viewModel.filteredProjects.first?.projectName.contains("Film") == true)
        
        // Test clearing filters
        viewModel.clearAllFilters()
        #expect(viewModel.filteredProjects.count == 4)
        #expect(viewModel.searchText.isEmpty)
        #expect(viewModel.selectedStatus == nil)
    }
    
    @Test("ProjectListViewModel handles sorting")
    func testProjectListViewModelSorting() async throws {
        let container = modelContainer
        let context = ModelContext(container)
        
        // Create projects with different properties for sorting
        let projectA = TestDataFactory.createProject(name: "A Project", artist: "Zebra Artist")
        let projectB = TestDataFactory.createProject(name: "Z Project", artist: "Alpha Artist")
        
        // Add items for fee sorting
        let itemsA = [TestDataFactory.createItem(fee: 100.0)]
        let itemsB = [TestDataFactory.createItem(fee: 200.0)]
        projectA.items = itemsA
        projectB.items = itemsB
        
        context.insert(projectA)
        context.insert(projectB)
        for item in itemsA + itemsB {
            context.insert(item)
        }
        try context.save()
        
        let viewModel = ProjectListViewModel(modelContext: context)
        await viewModel.loadProjects()
        
        // Test sorting by project name
        viewModel.sortOption = .projectName
        #expect(viewModel.filteredProjects.first?.projectName == "A Project")
        
        // Test sorting by artist
        viewModel.sortOption = .artist
        #expect(viewModel.filteredProjects.first?.artist == "Alpha Artist")
        
        // Test sorting by fee (highest first)
        viewModel.sortOption = .totalFee
        #expect(viewModel.filteredProjects.first?.totalFee == 200.0)
    }
    
    @Test("ProjectListViewModel calculates statistics")
    func testProjectListViewModelStatistics() async throws {
        let container = modelContainer
        let context = ModelContext(container)
        
        let project1 = TestDataFactory.createProject(status: .open)
        let project2 = TestDataFactory.createProject(status: .delivered)
        
        // Add items for fee calculation
        let items1 = [TestDataFactory.createItem(fee: 100.0)]
        let items2 = [TestDataFactory.createItem(fee: 200.0)]
        project1.items = items1
        project2.items = items2
        
        context.insert(project1)
        context.insert(project2)
        for item in items1 + items2 {
            context.insert(item)
        }
        try context.save()
        
        let viewModel = ProjectListViewModel(modelContext: context)
        await viewModel.loadProjects()
        
        #expect(viewModel.totalFilteredFees == 300.0)
        #expect(viewModel.formattedTotalFees.contains("$"))
        
        let statusCounts = viewModel.statusCounts
        #expect(statusCounts[.open] == 1)
        #expect(statusCounts[.delivered] == 1)
        #expect(statusCounts[.closed] == 0)
    }
    
    @Test("ProjectListViewModel creates and manages projects")
    func testProjectListViewModelProjectManagement() async throws {
        let container = modelContainer
        let context = ModelContext(container)
        
        let viewModel = ProjectListViewModel(modelContext: context)
        
        // Test creating new project
        let newProjectViewModel = viewModel.createProject()
        #expect(newProjectViewModel.project.projectName.isEmpty) // New project starts empty
        
        // Test creating from template
        let template = TestDataFactory.createFilmProject()
        context.insert(template)
        try context.save()
        
        let templateViewModel = viewModel.createProject(from: template)
        #expect(templateViewModel.project.projectName == template.projectName)
        #expect(templateViewModel.project.id != template.id) // Different instance
    }
    
    @Test("ProjectListViewModel handles project deletion")
    func testProjectListViewModelDeletion() async throws {
        let container = modelContainer
        let context = ModelContext(container)
        
        let project = TestDataFactory.createProject()
        context.insert(project)
        try context.save()
        
        let viewModel = ProjectListViewModel(modelContext: context)
        await viewModel.loadProjects()
        
        #expect(viewModel.projects.count == 1)
        
        await viewModel.deleteProject(project)
        
        #expect(viewModel.projects.isEmpty)
        #expect(viewModel.filteredProjects.isEmpty)
    }
    
    @Test("ProjectListViewModel handles bulk operations")
    func testProjectListViewModelBulkOperations() async throws {
        let container = modelContainer
        let context = ModelContext(container)
        
        let project1 = TestDataFactory.createProject(name: "Project 1", status: .open)
        let project2 = TestDataFactory.createProject(name: "Project 2", status: .open)
        
        context.insert(project1)
        context.insert(project2)
        try context.save()
        
        let viewModel = ProjectListViewModel(modelContext: context)
        await viewModel.loadProjects()
        
        // Test bulk delivery
        await viewModel.markProjectsAsDelivered([project1, project2])
        
        #expect(project1.status == .delivered)
        #expect(project2.status == .delivered)
        
        // Test bulk payment
        await viewModel.markProjectsAsPaid([project1, project2])
        
        #expect(project1.status == .closed)
        #expect(project2.status == .closed)
    }
    
    @Test("ViewModels work together in realistic scenarios")
    func testViewModelIntegration() async throws {
        let container = modelContainer
        let context = ModelContext(container)
        
        // Create a project using the list view model
        let listViewModel = ProjectListViewModel(modelContext: context)
        let detailViewModel = listViewModel.createProject()
        
        // Set up the project using the detail view model
        detailViewModel.project.projectName = "Integration Test Project"
        detailViewModel.project.artist = "Test Artist"
        detailViewModel.project.mediaType = .recording
        
        // Add items using the detail view model
        let item1 = TestDataFactory.createItem(name: "Recording", fee: 500.0)
        await detailViewModel.addItem(item1)
        
        #expect(detailViewModel.totalFee == 500.0)
        #expect(detailViewModel.project.items?.count == 1)
        
        // Mark as delivered using business logic
        await detailViewModel.markAsDelivered()
        #expect(detailViewModel.project.status == .delivered)
        
        // Reload list and verify project appears with correct status
        await listViewModel.loadProjects()
        #expect(listViewModel.projects.count == 1)
        #expect(listViewModel.projects.first?.status == .delivered)
        
        // Filter for delivered projects
        listViewModel.showDeliveredProjects()
        #expect(listViewModel.filteredProjects.count == 1)
        
        // Mark as paid and verify status change
        await detailViewModel.markAsPaid()
        await listViewModel.refresh()
        
        // Should no longer show in delivered filter
        #expect(listViewModel.filteredProjects.isEmpty)
        
        // But should show in closed filter
        listViewModel.showClosedProjects()
        #expect(listViewModel.filteredProjects.count == 1)
        #expect(listViewModel.totalFilteredFees == 500.0)
    }
    
    @Test("ProjectListViewModel handles quick filters")
    func testProjectListViewModelQuickFilters() async throws {
        let container = modelContainer
        let context = ModelContext(container)
        
        let openProject = TestDataFactory.createProject(status: .open)
        let deliveredProject = TestDataFactory.createProject(status: .delivered)
        let closedProject = TestDataFactory.createProject(status: .closed)
        
        context.insert(openProject)
        context.insert(deliveredProject)
        context.insert(closedProject)
        try context.save()
        
        let viewModel = ProjectListViewModel(modelContext: context)
        await viewModel.loadProjects()
        
        // Test show open projects
        viewModel.showOpenProjects()
        #expect(viewModel.selectedStatus == .open)
        #expect(viewModel.filteredProjects.count == 1)
        
        // Test show delivered projects
        viewModel.showDeliveredProjects()
        #expect(viewModel.selectedStatus == .delivered)
        #expect(viewModel.filteredProjects.count == 1)
        
        // Test show closed projects
        viewModel.showClosedProjects()
        #expect(viewModel.selectedStatus == .closed)
        #expect(viewModel.filteredProjects.count == 1)
    }
}