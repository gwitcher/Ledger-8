//
//  Charts.swift
//  Ledger 8
//
//  Created by Gabe Witcher on 9/24/25.
//

import SwiftUI
import SwiftData
import Charts

struct Charts: View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    @Query(filter: #Predicate<Project> {$0.paid == true}) var projects: [Project]
    
    //@Binding var selectedAngle: Double?
     
    var body: some View {
        NavigationStack {
            ScrollView (.vertical){
                VStack {
                    MediaTypeDonutChartView(projects: projects)
                        .padding()
                     
                    Spacer()
                    
                    TotalsByMonth(projects: projects)
                }
            }
            .navigationTitle("Charts")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

//#Preview {
//    Charts()
//}
