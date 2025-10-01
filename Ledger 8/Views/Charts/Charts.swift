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
    
    @Query(filter: #Predicate<Project> {$0.paid == true}) var projects: [Project]
    
    
    var body: some View {
        NavigationStack {
            VStack {
                IncomeToTypeView()
                
                Spacer()
                
                TotalByMonthView()
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

#Preview {
    Charts()
}
