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
    
    @Query var projects: [Project]
    
    
    var body: some View {
        NavigationStack {
            VStack {
                Chart {
                    ForEach(projects) { project in
                        BarMark(
                            x: .value("Client", project.client?.fullName ?? ""),
                            y: .value("Total Income", project.calculateFeeTotal(items: project.items ?? []))
                            
                        )
                    }
                }
                .frame(width: 300, height: 300)
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
