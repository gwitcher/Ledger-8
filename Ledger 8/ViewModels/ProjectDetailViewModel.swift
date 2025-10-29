//
//  ProjectDetailViewModel.swift
//  Ledger 8
//
//  Created by Gabe Witcher on 10/28/25.
//

import Foundation
import SwiftUI
import SwiftData
import MapKit

@Observable
class ProjectDetailViewModel {
    // MARK: - Published Properties (Form State)
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
    var selectedLocation = Place(mapItem: MKMapItem())
    var endDateSelected = false
    
    // MARK: - UI State
    var showProjectSuggestions = false
    var showStartDatePicker = false
    var showStartTimePicker = false
    var showEndDatePicker = false
    var showEndTimePicker = false
    var statusChange = false
    
    // MARK: - Focus and Alert State  
    var focusField: ProjectField?
    var showAlert = false
    var selectedTemplateProject: Project?
    
    // MARK: - Private Properties
    private let _project: Project
    
    // MARK: - Public Properties
    var project: Project { _project }
    
    // MARK: - Constants
    let dateAlertMessage = "The start date must be before the end date"
    
    // MARK: - Initialization
    init(project: Project) {
        self._project = project
        loadProjectData()
    }
    
    // MARK: - Data Loading
    func loadProjectData() {
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
        
        // Load location if it exists
        if let location = project.location {
            let mapItem = MKMapItem(placemark: MKPlacemark(
                coordinate: CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
            ))
            mapItem.name = location.name
            selectedLocation = Place(mapItem: mapItem)
        }
        
        // Update status change flag
        updateStatusChangeFlag()
    }
    
    // MARK: - Business Logic Methods
    
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
    }
    
    func handlePaidChange() {
        if paid && dateClosed == Date.distantFuture {
            dateClosed = Date.now
        }
        
        if !delivered {
            delivered = true
        }
        updateProjectStatus()
    }
    
    func handleClientChange() {
        showProjectSuggestions = false
    }
    
    func toggleProjectSuggestions() {
        if showProjectSuggestions {
            withAnimation(.easeInOut(duration: 0.2)) {
                showProjectSuggestions = false
            }
            focusField = nil
        } else {
            focusField = .project
            withAnimation(.easeInOut(duration: 0.2)) {
                showProjectSuggestions = true
            }
        }
    }
    
    func handleProjectFieldFocusChange() {
        if focusField == .project,
           let client = selectedClient,
           let clientProjects = client.project,
           !clientProjects.isEmpty {
            withAnimation(.easeInOut(duration: 0.2)) {
                showProjectSuggestions = true
            }
        } else if focusField != .project {
            withAnimation(.easeInOut(duration: 0.2)) {
                showProjectSuggestions = false
            }
        }
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
        
        updateStatusChangeFlag()
    }
    
    private func updateStatusChangeFlag() {
        switch status {
        case .open:
            statusChange = false
        case .delivered, .closed:
            statusChange = true
        }
    }
    
    // MARK: - Validation
    
    func canSaveProject() -> Bool {
        return endDate >= startDate
    }
    
    func validateAndPrepareForSave() -> Bool {
        if endDate < startDate {
            showAlert = true
            return false
        }
        return true
    }
    
    // MARK: - Save Operations
    
    func saveProject(to modelContext: ModelContext, withFeedback: Bool = false) {
        let generator = UINotificationFeedbackGenerator()
        
        // Apply all current UI state to the project model
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
        
        // Convert selectedLocation back to Spot if needed
        if !selectedLocation.isEmpty {
            var spot = Spot()
            spot.name = selectedLocation.name
            spot.address = selectedLocation.address
            spot.latitude = selectedLocation.lattitude
            spot.longitude = selectedLocation.longitude
            spot.addedDate = Date()
            project.location = spot
        }
        
        // Insert the project into context (SwiftData handles duplicates gracefully)
        modelContext.insert(project)
        
        // Save to database
        do {
            try modelContext.save()
            if withFeedback {
                generator.notificationOccurred(.success)
            }
        } catch {
            print("Error saving project: \(error)")
            if withFeedback {
                generator.notificationOccurred(.error)
            }
        }
    }
    
    // MARK: - UI Helper Methods
    
    func clearTextFields() {
        projectName = ""
        artist = ""
        notes = ""
        startDate = Date()
    }
    
    // MARK: - Data Processing Helpers
    
    func sortedProjectsByFrequency(_ projects: [Project]) -> [Project] {
        // Filter out projects with empty names first
        let projectsWithNames = projects.filter { !$0.projectName.isEmpty }
        
        // Group projects by name and count occurrences
        let projectCounts = Dictionary(grouping: projectsWithNames, by: { $0.projectName })
            .mapValues { $0.count }
        
        // Get unique projects (one per project name) using the most recent one for each name
        let uniqueProjects = Dictionary(grouping: projectsWithNames, by: { $0.projectName })
            .compactMapValues { projectsWithSameName in
                // Return the most recent project for each name
                projectsWithSameName.max(by: { $0.startDate < $1.startDate })
            }
            .values
        
        // Sort first by frequency (descending), then alphabetically (ascending)
        return Array(uniqueProjects).sorted { project1, project2 in
            let count1 = projectCounts[project1.projectName] ?? 0
            let count2 = projectCounts[project2.projectName] ?? 0
            
            // If counts are different, sort by count (higher first)
            if count1 != count2 {
                return count1 > count2
            }
            
            // If counts are the same, sort alphabetically
            return project1.projectName.localizedStandardCompare(project2.projectName) == .orderedAscending
        }
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
}
