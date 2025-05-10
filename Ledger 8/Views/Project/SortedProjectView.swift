//
//  SortedProjectView.swift
//  Ledger 7
//
//  Created by Gabe Witcher on 4/10/25.
//

import SwiftUI
import SwiftData

struct SortedProjectView: View {
    @Environment(\.modelContext) var modelContext
    @Query var projects: [Project]
    
    let filterSelection: Status
    
    init(sortSelection: Status) {
        self.filterSelection = sortSelection
        switch self.filterSelection {
        case .open:
            _projects = Query(filter: #Predicate<Project> {$0.delivered == false && $0.paid == false})
        case .delivered:
            _projects = Query(filter: #Predicate<Project> {$0.delivered == true && $0.paid == false})
        case .closed:
            _projects = Query(filter: #Predicate<Project> {$0.paid == true})
        }
    }
    
    var body: some View {
        
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
                    Button("Paid") {
                        if !project.delivered {
                            project.dateDelivered = Date.now
                        }
                        project.dateClosed = Date.now
                        project.paid.toggle()
                        project.status = .closed
                    }
                    .tint(.green)
                }
                .swipeActions(edge: .leading) {
                    Button("Delivered") {
                        project.dateDelivered = Date.now
                        project.delivered.toggle()
                        project.status = .delivered
                    }
                    .tint(.orange)
                }
            }
            
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        
    }
}

#Preview {
    SortedProjectView(sortSelection: .open)
}
