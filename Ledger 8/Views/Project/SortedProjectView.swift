//
//  SortedProjectView.swift
//  Ledger 7
//
//  Created by Gabe Witcher on 4/10/25.
//

import SwiftUI
import SwiftData

extension Date {
    func monthYearString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "LLLL yyyy"
        return formatter.string(from: self)
    }
}

struct SortedProjectView: View {
    @Environment(\.modelContext) var modelContext
    
    @Query var projects: [Project]
    
    let filterSelection: Status
    let searchText: String
    
    init(sortSelection: Status, searchText: String = "") {
        self.filterSelection = sortSelection
        self.searchText = searchText
        
        switch self.filterSelection {
        case .open:
            _projects = Query(filter: #Predicate<Project> {$0.delivered == false && $0.paid == false}, sort: \Project.startDate)
        case .delivered:
            _projects = Query(filter: #Predicate<Project> {$0.delivered == true && $0.paid == false}, sort: \Project.dateDelivered)
        case .closed:
            _projects = Query(filter: #Predicate<Project> {$0.paid == true}, sort: \Project.startDate, order: .reverse)
        }
    }
    
    private var filteredProjects: [Project] {
        if searchText.isEmpty {
            return projects
        } else {
            return projects.filter { project in
                project.projectName.localizedCaseInsensitiveContains(searchText) ||
                project.artist.localizedCaseInsensitiveContains(searchText) ||
                project.client?.fullName.localizedCaseInsensitiveContains(searchText) ?? false ||
                project.mediaType.rawValue.localizedCaseInsensitiveContains(searchText) ||
                project.notes.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    private var groupedProjectsByMonthYear: [(key: String, value: [Project])] {
        let grouped = Dictionary(grouping: filteredProjects) { project in
            project.startDate.monthYearString()
        }
        return grouped.sorted { lhs, rhs in
            guard let firstLhs = lhs.value.first?.startDate, let firstRhs = rhs.value.first?.startDate else { return false }
            return firstLhs > firstRhs
        }
    }
    
    var body: some View {
        Group {
            if filterSelection == .closed {
                // Show empty state if no results
                if groupedProjectsByMonthYear.isEmpty && !searchText.isEmpty {
                    List {
                        Section {
                            ContentUnavailableView.search(text: searchText)
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                } else {
                    List {
                        ForEach(groupedProjectsByMonthYear, id: \.key) { group in
                            Section(header: Text(group.key).font(.headline).foregroundStyle(.secondary)) {
                                ForEach(group.value) { project in
                                    NavigationLink(destination: ProjectEventDetailView(project: project)) {
                                        ProjectView(project: project)
                                    }
                                    .swipeActions {
                                        Button("Delete", role: .destructive) {
                                            let generator = UINotificationFeedbackGenerator()
                                            modelContext.delete(project)
                                            generator.notificationOccurred(.success)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                }
            } else {
                // Show empty state if no results
                if filteredProjects.isEmpty && !searchText.isEmpty {
                    List {
                        Section {
                            ContentUnavailableView.search(text: searchText)
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                } else {
                    List {
                        ForEach(filteredProjects) { project in
                            NavigationLink(destination: ProjectEventDetailView(project: project)) {
                                ProjectView(project: project)
                            }
                            .swipeActions {
                                Button("Delete", role: .destructive) {
                                    let generator = UINotificationFeedbackGenerator()
                                    modelContext.delete(project)
                                    generator.notificationOccurred(.success)
                                }
                            }
                            .swipeActions(edge: .leading) {
                                if project.status != .open {
                                    Button("Open") {
                                        let generator = UINotificationFeedbackGenerator()
                                        project.dateDelivered = project.dateOpened
                                        project.dateClosed = project.dateOpened
                                        project.delivered = false
                                        project.paid = false
                                        project.status = .open
                                        generator.notificationOccurred(.success)
                                    }
                                    .tint(.yellow)
                                }
                            }
                            .swipeActions(edge: .leading) {
                                if project.status != .closed {
                                    Button("Paid") {
                                        let generator = UINotificationFeedbackGenerator()
                                        if !project.delivered {
                                            project.dateDelivered = Date.now
                                        }
                                        project.dateClosed = Date.now
                                        project.paid = true
                                        project.status = .closed
                                        generator.notificationOccurred(.success)
                                    }
                                    .tint(.green)
                                }
                            }
                            .swipeActions(edge: .leading) {
                                if project.status != .delivered {
                                    Button("Delivered") {
                                        let generator = UINotificationFeedbackGenerator()
                                        project.dateDelivered = Date.now
                                        project.delivered = true
                                        project.paid = false
                                        project.status = .delivered
                                        generator.notificationOccurred(.success)
                                    }
                                    .tint(.orange)
                                }
                            }
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                }
            }
        }
    }
}



#Preview {
    SortedProjectView(sortSelection: .open)
}
