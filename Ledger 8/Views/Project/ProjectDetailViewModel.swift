//
//  ProjectDetailViewModel.swift
//  Ledger 8
//
//  Created by Gabe Witcher on 10/27/25.
//

import SwiftUI
import SwiftData
import MapKit
import Observation

@Observable
@MainActor
final class ProjectDetailViewModel {
    // MARK: - Form State Properties
    var projectName = ""
    var artist = ""
    var startDate = Date()
    var endDate = Date()
    var mediaType = MediaType.recording
    var notes = ""
    var delivered = false
    var paid = false
    var dateDelivered = Date()
    var dateClosed = Date()
    var status = Status.open
    var selectedClient: Client?
    var endDateSelected = false
    var selectedLocation = Place(mapItem: MKMapItem())
    
    // MARK: - UI State Properties
    var showProjectSuggestions = false
    var showStartDatePicker = false
    var showStartTimePicker = false
    var showEndDatePicker = false
    var showEndTimePicker = false
    var showAlert = false
    var itemSheetIsPresented = false
    var clientSelectSheetIsPresented = false
    var statusChange = false
    
    // MARK: - Template and Auto-save State
    var selectedTemplateProject: Project?
    private var saveWorkItem: DispatchWorkItem?
    
    // MARK: - Dependencies
    private let project: Project
    private let modelContext: ModelContext
    
    // MARK: - Constants
    let dateAlertMessage = "The start date must be before the end date"
    
    // MARK: - Initialization
    init(project: Project, modelContext: ModelContext) {
        self.project = project
        self.modelContext = modelContext
        loadProjectData()
    }
    
    // MARK: - Data Loading
    private func loadProjectData() {
        selectedClient = project.client
        projectName = project.projectName
        artist = project.artist
        startDate = project.startDate
        endDate = project.endDate
        mediaType = project.mediaType
        notes = project.notes
        delivered = project.delivered
        paid = project.paid
        dateDelivered = project.dateDelivered
        dateClosed = project.dateClosed
        status = project.status
        endDateSelected = project.endDateSelected
        
        // Initialize statusChange based on current status
        handleStatusChange()
        
        // Ensure new projects are immediately persisted
        if project.projectName.isEmpty && project.artist.isEmpty {
            modelContext.insert(project)
            try? modelContext.save()
        }
    }
    
    // MARK: - Public Interface Methods
    
    func toggleProjectSuggestions() {
        if showProjectSuggestions {
            showProjectSuggestions = false
        } else {
            showProjectSuggestions = true
        }
    }
    
    func handleStartDateChange() {
        if !endDateSelected {
            print("🟢 On Change initialized")
            print("End Date selected: \(endDateSelected)")
            endDate = startDate.adding(hours: 1)
        }
    }
    
    func handleEndDateChange() {
        if endDate != startDate.adding(hours: 1) {
            endDateSelected = true
            print("End Date selected: \(endDateSelected)")
        }
    }
    
    func handleTemplateProjectChange() {
        if let templateProject = selectedTemplateProject {
            projectName = templateProject.projectName
            artist = templateProject.artist
            mediaType = templateProject.mediaType
            notes = templateProject.notes
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.selectedTemplateProject = nil
            }
        }
    }
    
    func handleDeliveredChange() {
        if delivered && dateDelivered == Date.distantPast {
              dateDelivered = Date.now
          }
        updateProjectStatus()
        autoSaveProjectChanges()
    }
    
    func handlePaidChange() {
        if paid && dateClosed == Date.distantFuture {
            dateClosed = Date.now
        }
        
        if !delivered {
            delivered = true
        }
        updateProjectStatus()
        autoSaveProjectChanges()
    }
    
    private func updateProjectStatus() {
        if delivered && paid {
            status = .closed
        } else if delivered && !paid {
            status = .delivered
        } else if !delivered && paid {
            status = .closed
        } else {
            status = .open
        }
    }
    
    func handleStatusChange() {
        switch status {
        case .open:
            statusChange = false
        case .delivered:
            statusChange = true
        case .closed:
            statusChange = true
        }
    }
    
    func saveProject() {
        let generator = UINotificationFeedbackGenerator()
        
        // Check for changes that would affect an invoice
        let projectNameChanged = project.projectName != projectName
        let clientChanged = project.client != selectedClient
        
        // Apply the changes
        project.client = selectedClient
        project.projectName = projectName
        project.artist = artist
        project.startDate = startDate
        project.endDate = endDate
        project.mediaType = mediaType
        project.notes = notes
        project.delivered = delivered
        project.paid = paid
        project.dateDelivered = dateDelivered
        project.dateClosed = dateClosed
        project.status = status
        project.endDateSelected = endDateSelected
        
        // Flag invoice for update if invoice-relevant changes occurred
        if projectNameChanged || clientChanged {
            project.flagInvoiceForUpdate()
        }
        
        modelContext.insert(project)
        
        guard let _ = try? modelContext.save() else {
            print("😡 ERROR: Cannot save")
            return
        }
        generator.notificationOccurred(.success)
    }
    
    func deleteProject() {
        modelContext.delete(project)
        try? modelContext.save()
    }
    
    func clearTextFields() {
        projectName = ""
        artist = ""
        notes = ""
        startDate = Date()
    }
    
    // MARK: - Validation
    func canSaveProject() -> Bool {
        return endDate >= startDate
    }
    
    // MARK: - Auto-save functionality
    func autoSaveProjectChanges() {
        // Apply current field values to the project
        project.client = selectedClient
        project.projectName = projectName
        project.artist = artist
        project.startDate = startDate
        project.endDate = endDate
        project.mediaType = mediaType
        project.notes = notes
        project.delivered = delivered
        project.paid = paid
        project.dateDelivered = dateDelivered
        project.dateClosed = dateClosed
        project.status = status
        project.endDateSelected = endDateSelected
        
        modelContext.insert(project)
        try? modelContext.save()
    }
    
    func debouncedAutoSave() {
        // Cancel previous save work item
        saveWorkItem?.cancel()
        
        // Create new work item with delay
        saveWorkItem = DispatchWorkItem {
            self.autoSaveProjectChanges()
        }
        
        // Execute after delay
        if let workItem = saveWorkItem {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: workItem)
        }
    }
}