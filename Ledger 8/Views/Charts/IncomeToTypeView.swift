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
    
    var projects: [Project]
    
    var body: some View {
        
        let data = createData(project: projects)
        
        NavigationStack {
            
            VStack {
                Text("Income by Media Type")
                    .padding()
                
                Chart {
                    ForEach(data) { item in
                        SectorMark(angle: .value("Total", item.feeTotal),
                                   innerRadius: .ratio(0.618),
                                   angularInset: 2,)
                            .foregroundStyle(by: .value("Media", item.mediaType))
                        
                    }
                }
                .chartBackground { chartProxy in
                    GeometryReader { geometry in
                        if let plotFrame = chartProxy.plotFrame {
                            let frame = geometry[plotFrame]
                            // You can use 'frame' here if needed for custom drawing or overlays
                            VStack {
                                Text("TEMP DATA")
                                    .font(.callout)
                                    .foregroundStyle(Color.secondary)
                                Text("$5000.00")
                                    .font(.title2.bold())
                                    .foregroundStyle(Color.primary)
                            }
                            .position(x: frame.midX, y: frame.midY)
                        }
                    }
                    
                }
                //.chartAngleSelection(value: $selectedAngle)
            }
            //.frame(width: 300, height: 300)
        }
    }
    
    
    struct chartData: Identifiable {
        var id = UUID()
        var client: String
        var mediaType: String
        var dateClosed: Date
        var status: Status
        var feeTotal: Double
    }
    
    
    func makeChartDate(project: Project) -> chartData {
        let client = project.client?.fullName ?? ""
        let mediaType = project.mediaType.rawValue
        let dateClosed = project.dateClosed
        let status: Status = project.status
        let feeTotal: Double = project.calculateFeeTotal(items: project.items ?? [])
        
        return chartData(client: client, mediaType: mediaType, dateClosed: dateClosed, status: status, feeTotal: feeTotal)
    }
    
    func createData(project: [Project]) -> [chartData] {
        var data: [chartData] = []
        
        for project in projects {
            data.append(makeChartDate(project: project))
        }
        
        return data
    }
    
    func getMonthName(_ month: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM"
        return dateFormatter.string(from: month)
    }
}





//#Preview {
//    IncomeToTypeView()
//}
