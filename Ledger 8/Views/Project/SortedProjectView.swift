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
    
    let sortSelection: Status
    
    init(sortSelection: Status) {
        self.sortSelection = sortSelection
        switch self.sortSelection {
        case .open:
            _projects = Query(filter: #Predicate<Project> {$0.invoiced == false && $0.paid == false})
        case .invoiced:
            _projects = Query(filter: #Predicate<Project> {$0.invoiced == true && $0.paid == false})
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
            }
            
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.primary.opacity(0.2), radius: 10, x: 0, y: 5)
    }
}

#Preview {
    SortedProjectView(sortSelection: .open)
}
