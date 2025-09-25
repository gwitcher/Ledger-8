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
            Chart {
                ForEach(projects) { project in
                    BarMark(
                        x: .value("Media", project.mediaType.rawValue),
                        y: .value("Count", project.calculateFeeTotal(items: project.items ?? []))
                        
                    )
                    
                }
            }
            .frame(height: 300)
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
