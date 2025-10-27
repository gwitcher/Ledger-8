import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) var modelContext
    @State private var coordinator = NavigationCoordinator()
    
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
        .sheet(isPresented: Binding(
            get: { coordinator.showingProjectDetail },
            set: { coordinator.showingProjectDetail = $0 }
        )) {
            if let project = coordinator.presentedProject {
                NavigationStack {
                    ProjectDetailView(project: project)
                        .environment(coordinator)
                }
            }
        }
        
        // Settings - Full screen for comprehensive settings
        .fullScreenCover(isPresented: Binding(
            get: { coordinator.showingSettings },
            set: { coordinator.showingSettings = $0 }
        )) {
            NavigationStack {
                SettingsView()
                    .environment(coordinator)
            }
        }
        
        // Analytics - Sheet for dashboard
        .sheet(isPresented: Binding(
            get: { coordinator.showingAnalytics },
            set: { coordinator.showingAnalytics = $0 }
        )) {
            NavigationStack {
                AnalyticsDashboardView()
                    .environment(coordinator)
            }
        }
        
        // Client List - Sheet for selection
        .sheet(isPresented: Binding(
            get: { coordinator.showingClientList },
            set: { coordinator.showingClientList = $0 }
        )) {
            NavigationStack {
                ClientListView()
                    .environment(coordinator)
            }
        }
        
        //TODO: Paywall
        // Paywall - Sheet for subscription
        .sheet(isPresented: Binding(
            get: { coordinator.showingPaywall },
            set: { coordinator.showingPaywall = $0 }
        )) {
            // You'll need to create this view or use a placeholder
            PaywallView(trigger: .clientLimit)
                .environment(coordinator)
        }
        
        // MARK: - Centralized Alerts
        .alert("Delete Project", isPresented: Binding(
            get: { coordinator.showingDeleteConfirmation },
            set: { coordinator.showingDeleteConfirmation = $0 }
        )) {
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

#Preview {
    ContentView()
        .modelContainer(for: [Project.self, Item.self, Client.self], inMemory: true)
}
