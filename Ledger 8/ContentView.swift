import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) var modelContext
    @State private var coordinator = NavigationCoordinator()
    
    var body: some View {
        NavigationStack(path: $coordinator.path) {
            ProjectListView()
                .navigationDestination(for: Project.self) { project in
                    coordinator.destination(for: project)
                }
                .navigationDestination(for: String.self) { pathString in
                    coordinator.destination(for: pathString)
                }
        }
        .environment(coordinator)
        // Handle modal presentations at the root level
        .sheet(isPresented: $coordinator.showingProjectDetail) {
            if let project = coordinator.presentedProject {
                ProjectDetailView(project: project)
            }
        }
        .fullScreenCover(isPresented: $coordinator.showingSettings) {
            SettingsView()
        }
        .fullScreenCover(isPresented: $coordinator.showingAnalytics) {
            AnalyticsDashboardView()
        }
        .sheet(isPresented: $coordinator.showingClientList) {
            ClientListView()
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Project.self, Item.self, Client.self], inMemory: true)
}
