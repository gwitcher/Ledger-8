//
//  QuerryOpenView.swift
//  Ledger 7
//
//  Created by Gabe Witcher on 4/10/25.
//

import SwiftUI
import SwiftData

struct PrimaryTotalsView: View {
    @Environment(\.modelContext) var modelContext
    @Query var projects: [Project]
    @Query(filter: #Predicate<Project> {$0.invoiced == false && $0.paid == false}) var projectsOpen: [Project]
    @Query(filter: #Predicate<Project> {$0.invoiced == true && $0.paid == false}) var projectsInvoiced: [Project]
    @Query(filter: #Predicate<Project> {$0.paid == true}) var projectsClosed: [Project]
    
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
            let openTotal = projectsFeeTotal(projects: projectsOpen)
            let invoicedTotal = projectsFeeTotal(projects: projectsInvoiced)
            let closedTotal = projectsFeeTotal(projects: projectsClosed)
            
            VStack (alignment: .leading, spacing: 8) {
                Group {
                    sortSelection == .open ? Text("^[\(projects.count) \(sortSelection.feeTotalLabel) PROJECTS](inflect: true)") : Text("^[\(projects.count) PROJECTS](inflect: true) \(sortSelection.feeTotalLabel)")
                }
                .font(.title3)
                .fontWeight(.medium)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .padding(.horizontal)
                
                Text("\(projectsFeeTotal(projects: projects).formatted(.currency(code: "USD")))")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(sortSelection.statusColor)
                    .padding([.bottom, .horizontal])
                
            }
            .background(Color.white)
            
            Spacer()
            
            Group {
                if sortSelection == .open {
                    VStack (alignment: .trailing, spacing: 5) {
                        Text("\(invoicedTotal.formatted(.currency(code: "USD")))")
                            .font(.subheadline)
                            .foregroundStyle(Status.invoiced.statusColor)
                        Text("\(closedTotal.formatted(.currency(code: "USD")))")
                            .font(.subheadline)
                            .foregroundStyle(Status.closed.statusColor)
                    }
                    .padding([.horizontal, .bottom])
                    
                } else if sortSelection == .invoiced {
                    VStack (alignment: .trailing, spacing: 8) {
                        Text("\(openTotal.formatted(.currency(code: "USD")))")
                            .font(.subheadline)
                            .foregroundStyle(Status.open.statusColor)
                        Text("\(closedTotal.formatted(.currency(code: "USD")))")
                            .font(.subheadline)
                            .foregroundStyle(Status.closed.statusColor)
                    }
                    .padding([.horizontal, .bottom])
                } else {
                    VStack (alignment: .trailing, spacing: 8) {
                        Text("\(openTotal.formatted(.currency(code: "USD")))")
                            .font(.subheadline)
                            .foregroundStyle(Status.open.statusColor)
                        Text("\(invoicedTotal.formatted(.currency(code: "USD")))")
                            .font(.subheadline)
                            .foregroundStyle(Status.invoiced.statusColor)
                    }
                    .padding([.horizontal, .bottom])
                }
            }
        }
    }
    
    func projectsFeeTotal(projects: [Project]) -> Double {
        var projectTotal = 0.0
        for project in projects {
            projectTotal += project.calculateFeeTotal(items: project.items!)
        }
        return projectTotal
    }
}
#Preview {
    PrimaryTotalsView(sortSelection: Status.open)
}
