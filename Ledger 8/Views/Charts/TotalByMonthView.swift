//
//  TotalByMonthView.swift
//  Ledger 8
//
//  Created by Gabe Witcher on 9/30/25.
//

import SwiftUI
import SwiftData
import Charts

struct TotalByMonthView: View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss
    
    @Query(filter: #Predicate<Project> {$0.paid == true}, sort: \Project.dateClosed) var projects: [Project]
        
    
    var body: some View {
        
        let total = projects.reduce(0) { $0 + $1.calculateFeeTotal(items: $1.items ?? []) }
        
        VStack {
            
            Text("Income By Month")
            
            Text("Total: \(total.formatted(.currency(code: "USD")))")
                .fontWeight(.semibold)
                .font(.footnote)
                .foregroundStyle(Color(.secondaryLabel))
                .padding(.bottom, 12)
            
            Chart {
                ForEach(projects) { project in
                    BarMark(x: .value("Month", getMonthName(project.dateClosed)),
                            y: .value("Total", project.calculateFeeTotal(items: project.items ?? [] )))
                    
                    
                }
            }
            .frame(width: 300, height: 180)
            
            
            
        }
        
    }
    
    func getMonthName(_ month: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM"
        return dateFormatter.string(from: month)
    }
    
    
}

#Preview {
    TotalByMonthView()
}
