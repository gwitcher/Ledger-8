//
//  ProjectListViewModel.swift
//  Ledger 8
//
//  Created by Gabe Witcher on 10/28/25.
//

import SwiftUI
import SwiftData

/// ViewModel for ProjectListView following MVVM pattern
/// This class handles all the business logic and state management for the project list screen
@Observable
class ProjectListViewModel {
    
    // MARK: - UI State Properties
    /// Controls whether the new project sheet is shown
    var projectSheetIsPresented = false
    
    /// Controls whether the client list sheet is shown
    var clientListIsPresented = false
    
    /// Controls whether the user info sheet is shown
    var userInfoSheetIsPresented = false
    
    /// Controls whether the settings sheet is shown
    var settingsSheetIsPresented = false
    
    /// Controls whether the analytics chart sheet is shown
    var chartSheetIsPresented = false
    
    /// The current status filter selection (Open, Delivered, Closed, etc.)
    var sortSelection: Status = .open
    
    /// The current search text entered by the user
    var searchText = ""
    
    /// Whether the search mode is currently active
    var isSearching = false
    
    /// Whether the search field should be focused (for keyboard control)
    var searchFieldFocused = false
    
    // MARK: - Computed Properties
    
    /// Returns the appropriate navigation title based on search state
    var navigationTitle: String {
        return isSearching ? "" : "Project Ledger"
    }
    
    // MARK: - Initializer
    init() {
        // Any initial setup can go here
        // For now, we'll use the default values set above
    }
    
    // MARK: - Search Actions
    
    /// Activates search mode with animation
    func startSearching() {
        withAnimation(.easeInOut(duration: 0.25)) {
            isSearching = true
        }
        
        // Focus the search field after a brief delay to ensure the animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.searchFieldFocused = true
        }
    }
    
    /// Cancels search mode and clears search text
    func cancelSearching() {
        withAnimation(.easeInOut(duration: 0.25)) {
            isSearching = false
            searchText = ""
            searchFieldFocused = false
        }
    }
    
    /// Clears the current search text
    func clearSearchText() {
        searchText = ""
    }
    
    // MARK: - Sheet Actions
    
    /// Shows the new project creation sheet
    func showProjectSheet() {
        projectSheetIsPresented = true
    }
    
    /// Shows the client list sheet
    func showClientList() {
        clientListIsPresented = true
    }
    
    /// Shows the settings sheet
    func showSettings() {
        settingsSheetIsPresented = true
    }
    
    /// Shows the analytics chart sheet
    func showChart() {
        chartSheetIsPresented = true
    }
    
    // MARK: - Status Filter Actions
    
    /// Updates the status filter selection
    /// - Parameter status: The new status to filter by
    func updateStatusFilter(to status: Status) {
        sortSelection = status
    }
    
    // MARK: - Helper Methods
    
    /// Determines if projects exist to show content
    /// - Parameter projects: Array of projects from SwiftData
    /// - Returns: True if there are projects to display
    func hasProjects(_ projects: [Project]) -> Bool {
        return !projects.isEmpty
    }
}