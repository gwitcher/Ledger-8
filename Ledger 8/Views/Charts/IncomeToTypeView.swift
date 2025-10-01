//
//  IncomeToTypeView.swift
//  Ledger 8
//
//  Created by Gabe Witcher on 9/30/25.
//

import SwiftUI
import SwiftData
import Charts

struct IncomeToTypeView: View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss
    
    @Query(filter: #Predicate<Project> {$0.paid == true}) var projects: [Project]
    
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("Income by Media Type")
                
                Chart {
                    ForEach(projects) { project in
//                        BarMark(
//                            x: .value("Media", project.mediaType.rawValue),
//                            y: .value("Total Income", project.calculateFeeTotal(items: project.items ?? []))
//                        )
                        BarMark(x: .value("Total Income", project.calculateFeeTotal(items: project.items ?? [])), y: .value("Media", project.mediaType.rawValue))
                    }
                }
                
                .frame(width: 300, height: 300)
                .foregroundStyle(Color.pink.gradient)
               
                //.chartScrollableAxes(.horizontal)
                .padding()
                
            }
        }
    }
}





#Preview {
    IncomeToTypeView()
}
