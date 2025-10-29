//
//  ProjectDetailViewModel.swift
//  Ledger 8
//
//  Created by Test Suite on 10/28/25.
//

import Foundation
import SwiftData
import SwiftUI
import MapKit
import CoreLocation

/// ViewModel responsible for managing a single project's details and operations
@MainActor
@Observable
class ProjectDetailViewModel {
    
    // MARK: - Published Properties
    private(set) var project: Project
    private(set) var isLoading = false
    private(set) var errorMessage: String?
    
    // Form state
    var hasUnsavedChanges = false
    var endDateWasManuallySet = false
    
    // Location state
    var selectedPlace: Place?
    var isLocationPickerPresented = false
    
    // MARK: - Dependencies
    private let modelContext: ModelContext
    private let dataService: ProjectDataService
    
    // MARK: - Initialization
    init(project: Project, modelContext: ModelContext) {
        self.project = project
        self.modelContext = modelContext
        self.dataService = ProjectDataService(modelContext: modelContext)
        
        // Initialize location if exists
        if let spot = project.location {
            self.selectedPlace = convertSpotToPlace(spot)
        }
    }
    
    // MARK: - Project Status Management
    
    /// Marks the project as delivered and updates all related properties
    func markAsDelivered() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            project.markAsDelivered()
            try await save()
            hasUnsavedChanges = false
        } catch {
            handleError(error)
        }
    }
    
    /// Marks the project as paid and updates all related properties
    func markAsPaid() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            project.markAsPaid()
            try await save()
            hasUnsavedChanges = false
        } catch {
            handleError(error)
        }
    }
    
    /// Resets the project to open status
    func markAsOpen() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            project.markAsOpen()
            try await save()
            hasUnsavedChanges = false
        } catch {
            handleError(error)
        }
    }
    
    // MARK: - Date Management
    
    /// Updates the start date and automatically adjusts end date if not manually set
    func updateStartDate(_ newStartDate: Date) {
        project.startDate = newStartDate
        
        // Auto-update end date if it wasn't manually set
        if !project.endDateSelected {
            let oneHourLater = Calendar.current.date(byAdding: .hour, value: 1, to: newStartDate) ?? newStartDate
            project.endDate = oneHourLater
        }
        
        markAsChanged()
    }
    
    /// Updates the end date and marks it as manually selected
    func updateEndDate(_ newEndDate: Date) {
        project.endDate = newEndDate
        project.endDateSelected = true
        endDateWasManuallySet = true
        markAsChanged()
    }
    
    // MARK: - Fee Calculations
    
    /// Computed property for total project fee
    var totalFee: Double {
        project.totalFee
    }
    
    /// Get fee breakdown by item type
    var feesByItemType: [ItemType: Double] {
        project.feesByItemType()
    }
    
    /// Formatted total fee string for display
    var formattedTotalFee: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: totalFee)) ?? "$0.00"
    }
    
    // MARK: - Item Management
    
    /// Adds a new item to the project
    func addItem(_ item: Item) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            item.project = project
            if project.items == nil {
                project.items = []
            }
            project.items?.append(item)
            modelContext.insert(item)
            
            // Flag invoice for update if exists
            project.flagInvoiceForUpdate()
            
            try await save()
            markAsChanged()
        } catch {
            handleError(error)
        }
    }
    
    /// Removes an item from the project
    func removeItem(_ item: Item) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            project.items?.removeAll { $0.id == item.id }
            modelContext.delete(item)
            
            // Flag invoice for update if exists
            project.flagInvoiceForUpdate()
            
            try await save()
            markAsChanged()
        } catch {
            handleError(error)
        }
    }
    
    // MARK: - Location Management
    
    /// Updates the project location with a new place
    func updateLocation(_ place: Place) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let spot = convertPlaceToSpot(place)
            project.location = spot
            selectedPlace = place
            
            try await save()
            markAsChanged()
        } catch {
            handleError(error)
        }
    }
    
    /// Clears the project location
    func clearLocation() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            project.location = nil
            selectedPlace = nil
            
            try await save()
            markAsChanged()
        } catch {
            handleError(error)
        }
    }
    
    // MARK: - Template Operations
    
    /// Creates a new project using this project as a template
    func createProjectFromTemplate() -> Project {
        let newProject = Project()
        
        // Copy template data
        newProject.projectName = project.projectName
        newProject.artist = project.artist
        newProject.mediaType = project.mediaType
        newProject.notes = project.notes
        
        // Keep new dates and status
        // (default initialization handles this)
        
        return newProject
    }
    
    // MARK: - Validation
    
    /// Validates the current project data
    var isValid: Bool {
        !project.projectName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        project.startDate <= project.endDate
    }
    
    /// Returns validation errors as user-friendly messages
    var validationErrors: [String] {
        var errors: [String] = []
        
        if project.projectName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append("Project name is required")
        }
        
        if project.startDate > project.endDate {
            errors.append("Start date must be before end date")
        }
        
        return errors
    }
    
    // MARK: - Persistence
    
    /// Saves the project to the database
    func save() async throws {
        do {
            try modelContext.save()
            hasUnsavedChanges = false
            clearError()
        } catch {
            throw ProjectError.saveFailed(error.localizedDescription)
        }
    }
    
    /// Reverts unsaved changes
    func revertChanges() {
        modelContext.rollback()
        hasUnsavedChanges = false
        clearError()
    }
    
    // MARK: - Private Helpers
    
    private func markAsChanged() {
        hasUnsavedChanges = true
    }
    
    private func handleError(_ error: Error) {
        if let projectError = error as? ProjectError {
            errorMessage = projectError.localizedDescription
        } else {
            errorMessage = error.localizedDescription
        }
    }
    
    private func clearError() {
        errorMessage = nil
    }
    
    // MARK: - Location Conversion Helpers
    
    private func convertSpotToPlace(_ spot: Spot) -> Place {
        let coordinate = CLLocationCoordinate2D(latitude: spot.latitude, longitude: spot.longitude)
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
        mapItem.name = spot.name
        return Place(mapItem: mapItem, address: spot.address)
    }
    
    private func convertPlaceToSpot(_ place: Place) -> Spot {
        return Spot(
            name: place.name,
            address: place.address,
            latitude: place.lattitude,
            longitude: place.longitude,
            addedDate: Date()
        )
    }
}

// MARK: - Supporting Types

/// Custom errors for project operations
enum ProjectError: LocalizedError {
    case saveFailed(String)
    case validationFailed([String])
    case locationUpdateFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .saveFailed(let message):
            return "Failed to save project: \(message)"
        case .validationFailed(let errors):
            return "Validation failed: \(errors.joined(separator: ", "))"
        case .locationUpdateFailed(let message):
            return "Failed to update location: \(message)"
        }
    }
}

/// Data service for project operations
@MainActor
class ProjectDataService {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func save() async throws {
        try modelContext.save()
    }
    
    func delete(_ object: any PersistentModel) {
        modelContext.delete(object)
    }
    
    func insert(_ object: any PersistentModel) {
        modelContext.insert(object)
    }
}