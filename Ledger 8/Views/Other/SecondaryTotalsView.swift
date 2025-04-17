//
//  SecondaryTotalsView.swift
//  Ledger 8
//
//  Created by Gabe Witcher on 4/16/25.
//

import SwiftUI
import SwiftData

struct SecondaryTotalsView: View {
    @Environment(\.modelContext) var modelContext
    @Query(filter: #Predicate<Project> {$0.invoiced == false && $0.paid == false}) var projectsOpen: [Project]
    @Query(filter: #Predicate<Project> {$0.invoiced == true && $0.paid == false}) var projectsInvoiced: [Project]
    @Query(filter: #Predicate<Project> {$0.paid == true}) var projectsClosed: [Project]
    
   
    
    var body: some View {
        let openTotal = projectsFeeTotal(projects: projectsOpen)
        let invoicedTotal = projectsFeeTotal(projects: projectsInvoiced)
        let closedTotal = projectsFeeTotal(projects: projectsClosed)
        Text("\(openTotal)")
        Text("\(invoicedTotal)")
        Text("\(closedTotal)")
        
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
    SecondaryTotalsView()
}
