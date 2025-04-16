//
//  QuerryOpenView.swift
//  Ledger 7
//
//  Created by Gabe Witcher on 4/10/25.
//

import SwiftUI
import SwiftData

struct TotalsView: View {
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
        
        HStack {
            VStack (alignment: .leading, spacing: 8) {
                Group {
                     sortSelection == .open ? Text("^[\(projects.count) \(sortSelection.feeTotalLabel) PROJECTS](inflect: true)") : Text("^[\(projects.count) PROJECTS](inflect: true) \(sortSelection.feeTotalLabel)")
                }
                .font(.title3)
                .fontWeight(.medium)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .padding([.horizontal])
                
                Text("\(projectsFeeTotal(projects: projects).formatted(.currency(code: "USD")))")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(sortSelection.statusColor)
                    .padding([.bottom, .horizontal])
                
            }
            .background(Color.white)
            Spacer()
        }
//        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
//        .shadow(color: Color.primary.opacity(0.2), radius: 10, x: 0, y: 5)
        
        
    }
}

func projectsFeeTotal(projects: [Project]) -> Double {
    var projectTotal = 0.0
    for project in projects {
        projectTotal += project.calculateFeeTotal(items: project.items!)
    }
    return projectTotal
}

#Preview {
    TotalsView(sortSelection: Status.open)
}
