//  MediaTypeDonutChartView.swift
//  Ledger 8
//
//  Created by Assistant on 10/2/25.
//

import SwiftUI
import Charts

struct MediaTypeDonutChartView: View {
    var projects: [Project]
    
    struct MediaTypeTotal: Identifiable, Hashable {
        let id: MediaType
        let mediaType: MediaType
        let totalFee: Double
        var sliceColor: Color {
            switch mediaType {
            case .concert:
                    .blue
            case .film:
                    .green
            case .lesson:
                    .orange
            case .other:
                    .purple
            case .recording:
                    .red
            case .tour:
                    .cyan
            case .tv:
                    .pink
            }
        }
    }
    
    // Filter and sum total fees per MediaType for closed projects
    private var mediaTypeTotals: [MediaTypeTotal] {
        let closedProjects = projects.filter { $0.status == .closed }
        let grouped = Dictionary(grouping: closedProjects, by: { $0.mediaType })
        return grouped.map { (mediaType, projects) in
            let sum = projects.reduce(0.0) { $0 + $1.calculateFeeTotal(items: $1.items ?? []) }
            return MediaTypeTotal(id: mediaType, mediaType: mediaType, totalFee: sum)
        }
        .filter { $0.totalFee > 0 }
        .sorted { $0.totalFee > $1.totalFee }
    }
    
    func totalFee(project: [Project]) -> Double {
        project.reduce(0.0) { $0 + $1.calculateFeeTotal(items: $1.items ?? []) }
    }
    
    @State private var lastSelectedMediaType: MediaTypeTotal? = nil
    @State private var selectedAngle: Double? = nil
    
    private var selectedPie: MediaTypeTotal? {
        guard let selectedAngle else { return nil }
        var accumulatedDataValue: Double = 0
        for type in mediaTypeTotals {
            accumulatedDataValue += type.totalFee
            if selectedAngle < accumulatedDataValue {
                //print(type.mediaType.rawValue)
                return type
            }
        }
        return nil
    }
    
    
    
    
    var body: some View {
        let chartData = mediaTypeTotals
        VStack(alignment: .center) {
            Text("Revenue By Media Type")
                .font(.title3.bold())
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .padding(.bottom, 20)
            
            Chart(chartData) { item in
                SectorMark(
                    angle: .value("Total Fee", item.totalFee),
                    innerRadius: .ratio(0.6),
                    outerRadius: (selectedPie == nil ? .ratio(0.9) : (selectedPie!.mediaType == item.mediaType ? .ratio(1.0) : .ratio(0.9))),
                    angularInset: 2.0
                )
                
                .foregroundStyle(by: .value("MediaType", item.mediaType.rawValue))
                
                
                .cornerRadius(3)
                .opacity(selectedPie == nil ? 1 : (selectedPie!.mediaType == item.mediaType ? 1 : 0.3))
            }
            .chartLegend(position: .bottom, alignment: .center)
            .chartAngleSelection(value: $selectedAngle)
            .chartBackground(alignment: .center, content: { chartProxy in
                GeometryReader { geometry in
                    if let plotFrame = chartProxy.plotFrame {
                        let frame = geometry[plotFrame]
                        let displayPie = selectedPie ?? lastSelectedMediaType
                        
                        if let displayPie {
                            VStack {
                                Text(displayPie.mediaType.rawValue)
                                    .fontWeight(.bold)
                                Text("\(displayPie.totalFee.formatted(.currency(code: "USD")))")
                            }
                            .position(x: frame.midX, y: frame.midY)
                        }
                        else {
                            VStack {
                                Text("Total")
                                    .fontWeight(.bold)
                                Text("\(totalFee(project: projects).formatted(.currency(code: "USD")))")
                            }
                            .position(x: frame.midX, y: frame.midY)
                        }
                    }
                }
            })
            .frame(width: 300, height: 300)
        }
        .onChange(of: selectedAngle) { _, newValue in
            if newValue != nil {
                print(selectedPie!.mediaType.rawValue)
                lastSelectedMediaType = selectedPie
            }
        }
    }
}

#if DEBUG
// Dummy preview data
struct MediaTypeDonutChartView_Previews: PreviewProvider {
    static var previews: some View {
        let mt: [MediaType] = [.film, .tv, .recording, .concert, .tour, .lesson, .other]
        let projects: [Project] = mt.map { type in
            let proj = Project()
            proj.status = .closed
            proj.mediaType = type
            let item = Item(fee: Double.random(in: 500...4000))
            proj.items = [item]
            return proj
        }
        MediaTypeDonutChartView(projects: projects)
    }
}
#endif

