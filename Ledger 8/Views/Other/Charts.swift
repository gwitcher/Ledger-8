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
    
    @Query var items: [Item]
    
    
    var body: some View {
        NavigationStack {
            VStack {
                Chart {
                    ForEach(items) { item in
                        BarMark(
                            x: .value("Type", item.itemType.rawValue),
                            y: .value("Total Income", item.fee)
                            
                        )
                    }
                }
                .frame(height: 180)
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
