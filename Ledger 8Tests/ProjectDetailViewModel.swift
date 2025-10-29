//
//  ProjectDetailViewModel.swift
//  Ledger 8
//
//  Created by Refactoring Assistant
//

import Foundation
import SwiftData
import SwiftUI
import Combine

@Observable
class ProjectDetailViewModel {
    // MARK: - Published Properties
    var project: Project
    var projectName: String = ""
    var artist: String = ""
    var startDate: Date = Date()
    var endDate: Date = Date()
    var notes: String = ""
    var delivered: Bool = false
    var paid: Bool = false
    var dateDelivered: Date = Date()
    var dateClosed: Date = Date()
    var mediaType: MediaType = .recording
    
    // Client and Location
    var selectedClient: Client?
    var selectedLocation: Spot?
    var selectedTemplateProject: Project?
    
    // UI State
    var showProjectSuggestions: Bool = false
    var showStartDatePicker: Bool = false
    var showStartTimePicker: Bool = false
    var showEndDatePicker: Bool = false
    var showEndTimePicker: Bool = false
    var focusField: ProjectField?
    
    // Alerts
    var showAlert: Bool = false
    var dateAlertMessage: String = ""
    
    // MARK: - Computed Properties
    var statusChange: Bool {
        delivered || paid
    }
    
    // MARK: - Private Properties
    private var modelContext: ModelContext?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init(project: Project) {
        self.project = project
        loadProjectData()
    }
    
    // MARK: - Public Methods
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }
    
    func validateAndPrepareForSave() -> Bool {
        guard startDate <= endDate else {
            dateAlertMessage = "Start date must be before or equal to end date."
            showAlert = true
            return false
        }
        
        syncToProject()
        return true
    }
    
    func saveProject(to context: ModelContext, withFeedback: Bool = false) {
        guard validateAndPrepareForSave() else { return }
        
        do {
            if project.modelContext == nil {
                context.insert(project)
            }
            try context.save()
            
            if withFeedback {
                // Add haptic feedback or other UI feedback here
            }
        } catch {
            print("Failed to save project: \(error)")
        }
    }
    
    func clearTextFields() {
        projectName = ""
        artist = ""
        notes = ""
        selectedClient = nil
        selectedLocation = nil
    }
    
    func getMediaIcon(for mediaType: MediaType) -> String {
        switch mediaType {
        case .film: return "film"
        case .tv: return "tv"
        case .recording: return "mic"
        case .concert: return "person.3"
        case .tour: return "bus"
        case .lesson: return "graduationcap"
        case .other: return "questionmark.circle"
        case .game: return "gamecontroller"
        }
    }
    
    func toggleProjectSuggestions() {
        showProjectSuggestions.toggle()
    }
    
    func sortedProjectsByFrequency(_ projects: [Project]) -> [Project] {
        // Group projects by name and count occurrences
        let projectGroups = Dictionary(grouping: projects) { $0.projectName }
        let sortedGroups = projectGroups.sorted { $0.value.count > $1.value.count }
        
        // Return unique project names, most frequent first
        return sortedGroups.compactMap { $0.value.first }
    }
    
    // MARK: - Change Handlers
    func handleStartDateChange() {
        if endDate < startDate {
            endDate = Calendar.current.date(byAdding: .hour, value: 1, to: startDate) ?? startDate
        }
        project.flagInvoiceForUpdate()
    }
    
    func handleEndDateChange() {
        project.flagInvoiceForUpdate()
    }
    
    func handleTemplateProjectChange() {
        guard let template = selectedTemplateProject else { return }
        
        projectName = template.projectName
        mediaType = template.mediaType
        
        // Copy items if they exist
        if let templateItems = template.items {
            // This should trigger a UI update or confirmation dialog
        }
    }
    
    func handleClientChange() {
        project.client = selectedClient
        project.flagInvoiceForUpdate()
    }
    
    func handleDeliveredChange() {
        updateProjectStatus()
        if delivered {
            dateDelivered = Date()
        } else {
            dateDelivered = Date.distantPast
            paid = false
        }
        project.flagInvoiceForUpdate()
    }
    
    func handlePaidChange() {
        updateProjectStatus()
        if paid {
            delivered = true
            dateClosed = Date()
            if dateDelivered == Date.distantPast {
                dateDelivered = Date()
            }
        } else {
            dateClosed = Date.distantFuture
        }
        project.flagInvoiceForUpdate()
    }
    
    func handleProjectFieldFocusChange() {
        // Handle any focus-related logic here
        showProjectSuggestions = focusField == .project && 
                                  selectedClient?.project?.isEmpty == false
    }
    
    // MARK: - Private Methods
    private func loadProjectData() {
        projectName = project.projectName
        artist = project.artist
        startDate = project.startDate
        endDate = project.endDate
        notes = project.notes
        delivered = project.delivered
        paid = project.paid
        dateDelivered = project.dateDelivered
        dateClosed = project.dateClosed
        mediaType = project.mediaType
        selectedClient = project.client
        selectedLocation = project.location
    }
    
    private func syncToProject() {
        project.projectName = projectName
        project.artist = artist
        project.startDate = startDate
        project.endDate = endDate
        project.notes = notes
        project.delivered = delivered
        project.paid = paid
        project.dateDelivered = dateDelivered
        project.dateClosed = dateClosed
        project.mediaType = mediaType
        project.client = selectedClient
        project.location = selectedLocation
        
        updateProjectStatus()
    }
    
    private func updateProjectStatus() {
        if paid {
            project.status = .closed
        } else if delivered {
            project.status = .delivered
        } else {
            project.status = .open
        }
    }
}

// MARK: - Supporting Types
enum ProjectField {
    case project
    case artist
    case startDate
    case endDate
    case notes
}