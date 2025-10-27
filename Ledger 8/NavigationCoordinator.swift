//
//  NavigationCoordinator.swift
//  Ledger 8
//
//  Created by Assistant on 10/26/25.
//

import SwiftUI
import SwiftData

// MARK: - Navigation Coordinator
@Observable
class NavigationCoordinator {
    // MARK: - Navigation State
    var path = NavigationPath()
    var selectedProject: Project?
    var presentedProject: Project?
    
    // MARK: - Sheet Presentations - Centralized Control
    var showingProjectDetail = false
    var showingSettings = false
    var showingAnalytics = false
    var showingClientList = false
    var showingItemEditor = false
    var showingPaywall = false
    
    // MARK: - Search State
    var searchText = ""
    var isSearchActive = false
    
    // MARK: - Alert State
    var showingDeleteConfirmation = false
    var projectToDelete: Project?
    
    // MARK: - Public Navigation Methods
    
    /// Present a project in a sheet for detailed editing
    func presentProject(_ project: Project) {
        presentedProject = project
        showingProjectDetail = true
    }
    
    /// Navigate to project items list in the navigation stack
    func navigateToProjectItems(_ project: Project) {
        selectedProject = project
        path.append(NavigationDestination.projectItems(project))
    }
    
    /// Navigate to item editor for existing items only
    func navigateToItemEditor(for project: Project, item: Item) {
        path.append(NavigationDestination.itemEditor(project: project, item: item))
    }
    
    /// Present item editor for creating new items
    func navigateToItemEditor(for project: Project) {
        showingItemEditor = true
        selectedProject = project
    }
    
    /// Present settings in full screen (appropriate for settings)
    func presentSettings() {
        showingSettings = true
    }
    
    /// Present analytics dashboard
    func presentAnalytics() {
        showingAnalytics = true
    }
    
    /// Present client list for selection
    func presentClientList() {
        showingClientList = true
    }
    
    /// Show paywall when premium features are accessed
    func presentPaywall(trigger: PaywallTrigger) {
        showingPaywall = true
    }
    
    /// Handle delete confirmation with proper semantics
    func confirmDeleteProject(_ project: Project) {
        projectToDelete = project
        showingDeleteConfirmation = true
    }
    
    /// Dismiss all modals and return to root
    func dismissAll() {
        showingProjectDetail = false
        showingSettings = false
        showingAnalytics = false
        showingClientList = false
        showingItemEditor = false
        showingPaywall = false
        showingDeleteConfirmation = false
        
        popToRoot()
    }
    
    /// Pop to root of navigation stack
    func popToRoot() {
        path.removeLast(path.count)
    }
    
    /// Pop one level back
    func popBack() {
        if !path.isEmpty {
            path.removeLast()
        }
    }
    
    // MARK: - Navigation Destinations
    @ViewBuilder
    func destination(for destination: NavigationDestination) -> some View {
        switch destination {
        case .projectItems(let project):
            ProjectItemsView(project: project)
                .environment(self) // Pass coordinator to child views
                
        case .itemEditor(let project, let item):
            ItemEditView(item: item)
                .environment(self)
        }
    }
}

// MARK: - Navigation Destination Enum
enum NavigationDestination: Hashable {
    case projectItems(Project)
    case itemEditor(project: Project, item: Item)
    
    // Hashable conformance for NavigationPath
    func hash(into hasher: inout Hasher) {
        switch self {
        case .projectItems(let project):
            hasher.combine("projectItems")
            hasher.combine(project.id)
        case .itemEditor(let project, let item):
            hasher.combine("itemEditor")
            hasher.combine(project.id)
            hasher.combine(item.id)
        }
    }
    
    static func == (lhs: NavigationDestination, rhs: NavigationDestination) -> Bool {
        switch (lhs, rhs) {
        case (.projectItems(let lhsProject), .projectItems(let rhsProject)):
            return lhsProject.id == rhsProject.id
        case (.itemEditor(let lhsProject, let lhsItem), .itemEditor(let rhsProject, let rhsItem)):
            return lhsProject.id == rhsProject.id && lhsItem.id == rhsItem.id
        default:
            return false
        }
    }
}

// MARK: - Paywall Trigger Types
enum PaywallTrigger {
    case clientLimit
    case projectLimit
    case templateAccess
    case emailFeature
    case analytics
}