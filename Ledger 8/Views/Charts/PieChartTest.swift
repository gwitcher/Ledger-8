//
//  PieChartTest.swift
//  Ledger 8
//
//  Created by Gabe Witcher on 10/2/25.
//

import SwiftUI
import Charts

struct PieChartTest: View {
    @State private var selectedAngle: Double? = nil
    
    struct PieChartData: Identifiable {
        var id: Int
        var value: Double
        var color: Color = .blue
    }
    
    let data: [PieChartData] = [
        PieChartData(id: 0, value: 10),
        PieChartData(id: 1, value: 20),
        PieChartData(id: 2, value: 30),
        PieChartData(id: 3, value: 40),
    ]
    
    
    
    var body: some View {
        VStack {
            Chart(data) {item in
                SectorMark(angle: .value("Count", item.value),
                           angularInset: 2.0)
                .foregroundStyle(by: .value("Id", item.id))
            }
            .chartAngleSelection(value: $selectedAngle)
           
        }
        
    }
}

#Preview {
    PieChartTest()
}
