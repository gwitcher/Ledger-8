//  MediaTypeDonutChartView.swift
//  Ledger 8
//
//  Created by Assistant on 10/2/25.
//

import SwiftUI
import Charts

struct MediaTypeDonutChartView: View {
    var projects: [Project]
    @Environment(\.colorScheme) var colorScheme
    
    struct MediaTypeTotal: Identifiable, Hashable {
        let id: MediaType
        let mediaType: MediaType
        let totalFee: Double
        var sliceColor: Color {
            switch mediaType {
            case .concert:
                Color(.systemBlue)
            case .film:
                Color(.systemGreen) 
            case .lesson:
                Color(.systemOrange)
            case .other:
                Color(.systemPurple)
            case .recording:
                Color(.systemRed)
            case .tour:
                Color(.systemCyan)
            case .tv:
                Color(.systemPink)
            case .game:
                Color(.systemYellow)
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
        let displayPie = selectedPie ?? lastSelectedMediaType
        
        VStack(alignment: .leading) {
            
            VStack(alignment: .leading){
                Text("Revenue By Media Type")
                    .font(.title3.bold())
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    //.padding(.bottom, 5)
                
                    Group {
                        if let displayPie {
                            VStack(alignment: .leading) {
                                Text(displayPie.mediaType.rawValue)
                                    .fontWeight(.semibold)
                                Text("\(displayPie.totalFee.formatted(.currency(code: "USD")))")
                                    .fontWeight(.light)
                            }
                            
                        }
                        else {
                            VStack(alignment: .leading) {
                                Text("Total")
                                    .fontWeight(.semibold)
                                Text("\(totalFee(project: projects).formatted(.currency(code: "USD")))")
                                    .fontWeight(.light)
                            }
                        }
                    }
                    .padding(8)
                    
                
                
            }
            //.border(.red)
            
            
            
            
            
            
            
            
            
            
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
                        
                        VStack {
                            Text("Total")
                                .fontWeight(.semibold)
                            Text("\(totalFee(project: projects).formatted(.currency(code: "USD")))")
                                .fontWeight(.light)
                        }
                        .position(x: frame.midX, y: frame.midY)
                        
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

#Preview("Media Type Donut Chart") {
    // Create comprehensive mock data for preview
    let mockProjects: [Project] = {
        var projects: [Project] = []
        let mediaTypes: [MediaType] = [.film, .tv, .recording, .concert, .tour, .lesson, .other]
        
        // Create projects for each media type with varying amounts
        for (index, mediaType) in mediaTypes.enumerated() {
            // Create 1-3 projects per media type
            let projectCount = Int.random(in: 1...3)
            
            for i in 0..<projectCount {
                let project = Project(
                    projectName: "\(mediaType.rawValue) Project \(i + 1)",
                    artist: "Artist \(index + 1)-\(i + 1)",
                    status: .closed, // Make sure they're closed to show in chart
                    mediaType: mediaType
                )
                
                // Add items with realistic fees based on media type
                let baseFee = baseFeeForMediaType(mediaType)
                let mockItems = [
                    Item(
                        name: "Primary Service",
                        fee: baseFee + Double.random(in: -200...500)
                    ),
                    Item(
                        name: "Additional Work",
                        fee: Double.random(in: 100...800)
                    )
                ]
                
                project.items = mockItems
                projects.append(project)
            }
        }
        
        return projects
    }()
    
    // Helper function to set realistic base fees
    func baseFeeForMediaType(_ mediaType: MediaType) -> Double {
        switch mediaType {
        case .film:
            return Double.random(in: 2000...5000)
        case .tv:
            return Double.random(in: 1500...4000)
        case .recording:
            return Double.random(in: 800...2500)
        case .concert:
            return Double.random(in: 500...2000)
        case .tour:
            return Double.random(in: 1000...3000)
        case .lesson:
            return Double.random(in: 50...150)
        case .other:
            return Double.random(in: 200...1000)
        case .game:
            return Double.random(in: 200...1000)
        }
    }
    
    return MediaTypeDonutChartView(projects: mockProjects)
        .padding()
        .previewLayout(.sizeThatFits)
}

