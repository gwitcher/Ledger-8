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
    
    init(sortSelection: Status) {
        self.filterSelection = sortSelection
        switch self.filterSelection {
        case .open:
            _projects = Query(filter: #Predicate<Project> {$0.delivered == false && $0.paid == false}, sort: \Project.startDate)
        case .delivered:
            _projects = Query(filter: #Predicate<Project> {$0.delivered == true && $0.paid == false}, sort: \Project.dateDelivered)
        case .closed:
            _projects = Query(filter: #Predicate<Project> {$0.paid == true}, sort: \Project.startDate, order: .reverse)
        }
    }
    
    private var groupedProjectsByMonthYear: [(key: String, value: [Project])] {
        let grouped = Dictionary(grouping: projects) { project in
            project.startDate.monthYearString()
        }
        return grouped.sorted { lhs, rhs in
            guard let firstLhs = lhs.value.first?.startDate, let firstRhs = rhs.value.first?.startDate else { return false }
            return firstLhs > firstRhs
        }
    }
    
    var body: some View {
        if filterSelection == .closed {
            List {
                ForEach(groupedProjectsByMonthYear, id: \.key) { group in
                    Section(header: Text(group.key).font(.headline).foregroundStyle(.secondary)) {
                        ForEach(group.value) { project in
                            NavigationLink(destination: ProjectDetailView(project: project)) {
                                ProjectView(project: project)
                            }
                            .swipeActions {
                                Button("Delete", role: .destructive) {
                                    modelContext.delete(project)
                                }
                            }
                        }
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        } else {
            List {
                ForEach(projects) {project in
                    NavigationLink(destination: ProjectDetailView(project: project)) {
                        ProjectView(project: project)
                    }
                    .swipeActions {
                        Button("Delete", role: .destructive) {
                            modelContext.delete(project)
                        }
                    }
                    .swipeActions(edge: .leading) {
                        if project.status != .open {
                            Button("Open") {
                                project.dateDelivered = project.dateOpened
                                project.dateClosed = project.dateOpened
                                project.delivered = false
                                project.paid = false
                                project.status = .open
                            }
                            .tint(.yellow)
                        }
                    }
                    .swipeActions(edge: .leading) {
                        if project.status != .closed {
                            Button("Paid") {
                                if !project.delivered {
                                    project.dateDelivered = Date.now
                                }
                                project.dateClosed = Date.now
                                project.paid = true
                                project.status = .closed
                            }
                            .tint(.green)
                        }
                    }
                    .swipeActions(edge: .leading) {
                        if project.status != .delivered {
                            Button("Delivered") {
                                project.dateDelivered = Date.now
                                project.delivered = true
                                project.paid = false
                                project.status = .delivered
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

#Preview {
    SortedProjectView(sortSelection: .open)
}
