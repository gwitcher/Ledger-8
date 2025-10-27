//
//  NavigationCoordinator.swift
//  Ledger 8
//
//  Created by Assistant on 10/26/25.
//

import SwiftUI
import SwiftData

@Observable
class NavigationCoordinator {
    var path = NavigationPath()
    var selectedProject: Project?
    var presentedProject: Project?
    
    // Sheet presentations
    var showingProjectDetail = false
    var showingSettings = false
    var showingAnalytics = false
    var showingClientList = false
    
    // Navigation methods
    func presentProject(_ project: Project) {
        presentedProject = project
        showingProjectDetail = true
    }
    
    func navigateToProjectItems(_ project: Project) {
        selectedProject = project
        path.append("items-\(project.id)")
    }
    
    func presentSettings() {
        showingSettings = true
    }
    
    func presentAnalytics() {
        showingAnalytics = true
    }
    
    func presentClientList() {
        showingClientList = true
    }
    
    func popToRoot() {
        path.removeLast(path.count)
    }
    
    func dismissAll() {
        showingProjectDetail = false
        showingSettings = false
        showingAnalytics = false
        showingClientList = false
        popToRoot()
    }
}

// Navigation destination resolver
extension NavigationCoordinator {
    @ViewBuilder
    func destination(for value: Any) -> some View {
        switch value {
        case let project as Project:
            EnhancedProjectItemListView(project: project)
        case let itemsPath as String where itemsPath.hasPrefix("items-"):
            if let project = selectedProject {
                EnhancedProjectItemListView(project: project)
            } else {
                Text("Project not found")
            }
        default:
            Text("Unknown destination")
        }
    }
}