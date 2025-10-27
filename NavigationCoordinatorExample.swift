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
    
    /// Navigate to a specific item editor
    func navigateToItemEditor(for project: Project, item: Item? = nil) {
        path.append(NavigationDestination.itemEditor(project: project, item: item))
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
            EnhancedProjectItemListView(project: project)
                .environment(self) // Pass coordinator to child views
                
        case .itemEditor(let project, let item):
            ItemEditorView(project: project, item: item)
                .environment(self)
        }
    }
}

// MARK: - Navigation Destination Enum
enum NavigationDestination: Hashable {
    case projectItems(Project)
    case itemEditor(project: Project, item: Item?)
    
    // Hashable conformance for NavigationPath
    func hash(into hasher: inout Hasher) {
        switch self {
        case .projectItems(let project):
            hasher.combine("projectItems")
            hasher.combine(project.id)
        case .itemEditor(let project, let item):
            hasher.combine("itemEditor")
            hasher.combine(project.id)
            hasher.combine(item?.id)
        }
    }
    
    static func == (lhs: NavigationDestination, rhs: NavigationDestination) -> Bool {
        switch (lhs, rhs) {
        case (.projectItems(let lhsProject), .projectItems(let rhsProject)):
            return lhsProject.id == rhsProject.id
        case (.itemEditor(let lhsProject, let lhsItem), .itemEditor(let rhsProject, let rhsItem)):
            return lhsProject.id == rhsProject.id && lhsItem?.id == rhsItem?.id
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

// MARK: - Content View with Coordinator
struct ContentView: View {
    @State private var coordinator = NavigationCoordinator()
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        NavigationStack(path: $coordinator.path) {
            ProjectListView()
                .navigationDestination(for: NavigationDestination.self) { destination in
                    coordinator.destination(for: destination)
                }
        }
        .environment(coordinator)
        
        // MARK: - Centralized Modal Presentations
        
        // Project Detail - Sheet for editing
        .sheet(isPresented: $coordinator.showingProjectDetail) {
            if let project = coordinator.presentedProject {
                NavigationStack {
                    ProjectDetailView(project: project)
                        .environment(coordinator)
                }
            }
        }
        
        // Settings - Full screen for comprehensive settings
        .fullScreenCover(isPresented: $coordinator.showingSettings) {
            NavigationStack {
                SettingsView()
                    .environment(coordinator)
            }
        }
        
        // Analytics - Sheet for dashboard
        .sheet(isPresented: $coordinator.showingAnalytics) {
            NavigationStack {
                AnalyticsView()
                    .environment(coordinator)
            }
        }
        
        // Client List - Sheet for selection
        .sheet(isPresented: $coordinator.showingClientList) {
            NavigationStack {
                ClientListView()
                    .environment(coordinator)
            }
        }
        
        // Paywall - Sheet for subscription
        .sheet(isPresented: $coordinator.showingPaywall) {
            PaywallView(trigger: .clientLimit) // Pass appropriate trigger
                .environment(coordinator)
        }
        
        // MARK: - Centralized Alerts
        .alert("Delete Project", isPresented: $coordinator.showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let project = coordinator.projectToDelete {
                    deleteProject(project)
                }
            }
        } message: {
            if let project = coordinator.projectToDelete {
                Text("Are you sure you want to delete '\(project.projectName)'? This action cannot be undone.")
            }
        }
    }
    
    private func deleteProject(_ project: Project) {
        modelContext.delete(project)
        try? modelContext.save()
        coordinator.projectToDelete = nil
    }
}

// MARK: - Updated Project List View
struct ProjectListView: View {
    @Environment(NavigationCoordinator.self) private var coordinator
    @Environment(\.modelContext) private var modelContext
    @Query private var projects: [Project]
    
    var body: some View {
        List {
            ForEach(filteredProjects) { project in
                ProjectRowView(project: project)
                    .onTapGesture {
                        // Navigate to project items using coordinator
                        coordinator.navigateToProjectItems(project)
                    }
                    .swipeActions(edge: .trailing) {
                        Button("Edit") {
                            coordinator.presentProject(project)
                        }
                        .tint(.blue)
                        
                        Button("Delete", role: .destructive) {
                            coordinator.confirmDeleteProject(project)
                        }
                    }
            }
        }
        
        // MARK: - Native Search Integration
        .searchable(text: $coordinator.searchText, isPresented: $coordinator.isSearchActive)
        
        // MARK: - Modern Toolbar with Semantic Actions
        .toolbar(id: "project-list-toolbar") {
            ToolbarItem(id: "settings", placement: .topBarLeading) {
                Button {
                    coordinator.presentSettings()
                } label: {
                    Label("Settings", systemImage: "gear")
                }
                .buttonStyle(.secondary)
            }
            
            ToolbarItem(id: "analytics", placement: .topBarLeading) {
                Button {
                    coordinator.presentAnalytics()
                } label: {
                    Label("Analytics", systemImage: "chart.bar.xaxis")
                }
                .buttonStyle(.secondary)
            }
            
            ToolbarItem(id: "clients", placement: .topBarTrailing) {
                Button {
                    coordinator.presentClientList()
                } label: {
                    Label("Clients", systemImage: "person.circle")
                }
                .buttonStyle(.secondary)
            }
            
            ToolbarItem(id: "add-project", placement: .topBarTrailing) {
                Button {
                    let newProject = Project()
                    coordinator.presentProject(newProject)
                } label: {
                    Label("Add Project", systemImage: "plus")
                }
                .buttonStyle(.primary)  // Highest prominence for primary action
            }
        }
        .navigationTitle("Projects")
    }
    
    private var filteredProjects: [Project] {
        if coordinator.searchText.isEmpty {
            return projects
        } else {
            return projects.filter { project in
                project.projectName.localizedCaseInsensitiveContains(coordinator.searchText) ||
                project.artist.localizedCaseInsensitiveContains(coordinator.searchText) ||
                project.client?.fullName.localizedCaseInsensitiveContains(coordinator.searchText) == true
            }
        }
    }
}

// MARK: - Updated Project Detail View
struct ProjectDetailView: View {
    let project: Project
    @Environment(NavigationCoordinator.self) private var coordinator
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        Form {
            // Project form sections...
            Section("Actions") {
                Button("View Project Items") {
                    coordinator.navigateToProjectItems(project)
                    dismiss() // Close the sheet first, then navigate
                }
                .buttonStyle(.primary)
                
                Button("Add New Item") {
                    coordinator.navigateToItemEditor(for: project)
                    dismiss()
                }
                .buttonStyle(.secondary)
            }
        }
        .navigationTitle("Project Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.secondary)
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") {
                    // Save logic
                    dismiss()
                }
                .buttonStyle(.primary)
            }
        }
    }
}

// MARK: - Button Style Extensions for Semantic Hierarchy
extension ButtonStyle where Self == LedgerButtonStyle {
    static var primary: LedgerButtonStyle { LedgerButtonStyle(.primary) }
    static var secondary: LedgerButtonStyle { LedgerButtonStyle(.secondary) }
    static var destructive: LedgerButtonStyle { LedgerButtonStyle(.destructive) }
}

struct LedgerButtonStyle: ButtonStyle {
    enum Priority {
        case primary, secondary, destructive
        
        var baseStyle: any ButtonStyle {
            switch self {
            case .primary: return .borderedProminent
            case .secondary: return .bordered
            case .destructive: return .bordered
            }
        }
        
        var tintColor: Color {
            switch self {
            case .primary: return .accentColor
            case .secondary: return .primary
            case .destructive: return .red
            }
        }
    }
    
    let priority: Priority
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .buttonStyle(priority.baseStyle)
            .tint(priority.tintColor)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}