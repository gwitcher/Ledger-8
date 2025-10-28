//
//  ProjectEventDetailViewModel.swift
//  Ledger 8
//
//  Created by Gabe Witcher on 10/28/25.
//

import Foundation
import SwiftUI
import SwiftData
import MapKit

@Observable
class ProjectEventDetailViewModel {
    // MARK: - UI State
    var region: MKCoordinateRegion = MKCoordinateRegion()
    var projectDetailViewIsShowing = false
    var itemListIsShowing = false
    var showingDeleteConfirmation = false
    
    // MARK: - Private Properties
    private let _project: Project
    
    // MARK: - Public Properties
    var project: Project { _project }
    
    // MARK: - Initialization
    init(project: Project) {
        self._project = project
        setupMapRegion()
    }
    
    // MARK: - Setup Methods
    
    private func setupMapRegion() {
        if let location = project.location {
            let center = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
            region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        }
    }
    
    // MARK: - Business Logic Methods
    
    func updateProjectStatus(_ status: Status, in modelContext: ModelContext) {
        project.status = status
        
        // Update delivered and paid bools to match status
        switch status {
        case .open:
            project.delivered = false
            project.paid = false
        case .delivered:
            project.delivered = true
            project.paid = false
        case .closed:
            project.delivered = true
            project.paid = true
        }
        
        // Save the context to persist all changes
        do {
            try modelContext.save()
        } catch {
            print("Failed to save status change: \(error)")
        }
    }
    
    func deleteProject(from modelContext: ModelContext, customDismissAction: (() -> Void)? = nil, dismiss: DismissAction) {
        modelContext.delete(project)
        do {
            try modelContext.save()
        } catch {
            print("Error deleting project: \(error)")
        }
        
        // Use custom dismiss action if provided, otherwise use simple dismiss
        if let customDismissAction = customDismissAction {
            customDismissAction()
        } else {
            dismiss()
        }
    }
    
    // MARK: - Computed Properties and Helpers
    
    func totalFee(items: [Item]) -> Double {
        return items.reduce(0) { $0 + $1.fee }
    }
    
    func dateTimeString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    func eventDateDetails(start: Date, end: Date) -> (String, String) {
        let calendar = Calendar.current
        
        let longDateFormatter = DateFormatter()
        longDateFormatter.dateFormat = "EEEE, MMM d, yyyy"
        
        let shortDateFormatter = DateFormatter()
        shortDateFormatter.dateFormat = "E, MMM d, yyyy"
        
        let hourFormatter = DateFormatter()
        hourFormatter.dateFormat = "ha"
        hourFormatter.amSymbol = "AM"
        hourFormatter.pmSymbol = "PM"
        
        if calendar.isDate(start, inSameDayAs: end) {
            // Same day: line 1 is the full date, line 2 is "11AM–12PM"
            let dateString = longDateFormatter.string(from: start)
            let startTime = hourFormatter.string(from: start).replacingOccurrences(of: " ", with: "")
            let endTime = hourFormatter.string(from: end).replacingOccurrences(of: " ", with: "")
            let timeString = "\(startTime)–\(endTime)"
            return (dateString, timeString)
        } else {
            // Different days: "from 11AM Thu, Oct 30, 2025", "to 12PM Fri, Oct 31, 2025"
            let startTime = hourFormatter.string(from: start).replacingOccurrences(of: " ", with: "")
            let startDate = shortDateFormatter.string(from: start)
            let endTime = hourFormatter.string(from: end).replacingOccurrences(of: " ", with: "")
            let endDate = shortDateFormatter.string(from: end)
            let line1 = "from \(startTime) \(startDate)"
            let line2 = "to \(endTime) \(endDate)"
            return (line1, line2)
        }
    }
    
    func openInMaps(location: Spot) {
        let coordinate = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
        mapItem.name = location.name.isEmpty ? "Project Location" : location.name
        mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
    }
    
    // MARK: - UI Actions
    
    func toggleProjectDetailView() {
        projectDetailViewIsShowing.toggle()
    }
    
    func toggleItemList() {
        itemListIsShowing.toggle()
    }
    
    func showDeleteConfirmation() {
        showingDeleteConfirmation = true
    }
}