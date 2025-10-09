//
//  IncomeByMonthView.swift
//  Ledger 8
//
//  Created by Gabe Witcher on 10/5/25.
//

import SwiftUI
import SwiftData
import Charts

struct IncomeByMonthView: View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
//    @Query(filter: #Predicate<Project> {$0.paid == true})
    var projects: [Project]
    @State private var timeRange: TimeRange = .month
    
    enum TimeRange: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case sixMonths = "6 Months"
        case year = "Year"
        
        var dateRange: (start: Date, end: Date, unit: Calendar.Component) {
            let calendar = Calendar.current
            let now = Date()
            
            switch self {
            case .week:
                let start = calendar.date(byAdding: .weekOfYear, value: -12, to: now) ?? now // Show 12 weeks of data
                let end = calendar.date(byAdding: .weekOfYear, value: 1, to: now) ?? now
                return (start, end, .day)
            case .month:
                let start = calendar.date(byAdding: .month, value: -24, to: calendar.startOfMonth(for: now)) ?? now // Show 24 months
                let end = calendar.endOfMonth(for: now) ?? now
                return (start, end, .month)
            case .sixMonths:
                let start = calendar.date(byAdding: .month, value: -12, to: calendar.startOfMonth(for: now)) ?? now // Show 12 months
                let end = calendar.endOfMonth(for: now) ?? now
                return (start, end, .month)
            case .year:
                let currentYear = calendar.component(.year, from: now)
                let start = calendar.date(from: DateComponents(year: currentYear - 2, month: 1, day: 1)) ?? now // Show 3 years
                let end = calendar.date(from: DateComponents(year: currentYear, month: 12, day: 31)) ?? now
                return (start, end, .month)
            }
        }
        
        var visibleRange: Int {
            switch self {
            case .week:
                return 1 // Show 1 weeks at a time
            case .month:
                return 1 // Show 1 month at a time
            case .sixMonths:
                return 6 // Show 6 months at a time
            case .year:
                return 12 // Show 12 months at a time
            }
        }
        
        var snapUnit: Calendar.Component {
            switch self {
            case .week:
                return .weekOfYear
            case .month, .sixMonths, .year:
                return .month
            }
        }
    }
    
    struct totalByMonth: Identifiable, Hashable {
        let id = UUID()
        let mediaType: MediaType
        let totalFee: Double
        let date: Date
        var typeColor: Color {
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
    
    struct MonthlyTotal: Identifiable {
        let id = UUID()
        let date: Date
        let totalFee: Double
    }
    
    private var totalsByTimeRange: [totalByMonth] {
        let calendar = Calendar.current
        let range = timeRange.dateRange
        
        // Group projects by time period and media type, summing fees
        var timePeriodTotals: [String: [MediaType: Double]] = [:]
        
        for project in projects {
            let projectDate = project.dateClosed
            guard projectDate >= range.start && projectDate <= range.end else { continue }
            
            let periodKey: String
            switch timeRange {
            case .week:
                // Group by day for week view
                periodKey = calendar.dateComponents([.year, .month, .day], from: projectDate).description
            case .month, .sixMonths, .year:
                // Group by month
                periodKey = calendar.monthYearKey(for: projectDate)
            }
            
            let mediaType = project.mediaType
            let fee = project.calculateFeeTotal(items: project.items ?? [])
            
            if timePeriodTotals[periodKey] == nil {
                timePeriodTotals[periodKey] = [:]
            }
            
            timePeriodTotals[periodKey]?[mediaType, default: 0] += fee
        }
        
        // Generate array with all time periods (including empty ones)
        var result: [totalByMonth] = []
        var currentPeriod = range.start
        
        while currentPeriod <= range.end {
            let periodKey: String
            switch timeRange {
            case .week:
                periodKey = calendar.dateComponents([.year, .month, .day], from: currentPeriod).description
            case .month, .sixMonths, .year:
                periodKey = calendar.monthYearKey(for: currentPeriod)
            }
            
            // Get totals for this period (if any)
            let totalsForPeriod = timePeriodTotals[periodKey] ?? [:]
            
            // Create entries for all media types (including zeros) for proper stacking
            for mediaType in MediaType.allCases {
                let totalFee = totalsForPeriod[mediaType] ?? 0
                result.append(totalByMonth(
                    mediaType: mediaType,
                    totalFee: totalFee,
                    date: currentPeriod
                ))
            }
            
            // Move to next period
            switch timeRange {
            case .week:
                currentPeriod = calendar.date(byAdding: .day, value: 1, to: currentPeriod) ?? currentPeriod
            case .month, .sixMonths, .year:
                currentPeriod = calendar.date(byAdding: .month, value: 1, to: currentPeriod) ?? currentPeriod
            }
        }
        
        return result.sorted { $0.date < $1.date }
    }
    
    // Aggregated totals by time range (all media types combined)
    private var aggregatedTotalsByTimeRange: [MonthlyTotal] {
        let calendar = Calendar.current
        let range = timeRange.dateRange
        
        // Group projects by time period, summing all fees
        var timePeriodTotals: [String: Double] = [:]
        
        for project in projects {
            let projectDate = project.dateClosed
            guard projectDate >= range.start && projectDate <= range.end else { continue }
            
            let periodKey: String
            switch timeRange {
            case .week:
                periodKey = calendar.dateComponents([.year, .month, .day], from: projectDate).description
            case .month, .sixMonths, .year:
                periodKey = calendar.monthYearKey(for: projectDate)
            }
            
            let fee = project.calculateFeeTotal(items: project.items ?? [])
            timePeriodTotals[periodKey, default: 0] += fee
        }
        
        // Generate array with all time periods (including empty ones)
        var result: [MonthlyTotal] = []
        var currentPeriod = range.start
        
        while currentPeriod <= range.end {
            let periodKey: String
            switch timeRange {
            case .week:
                periodKey = calendar.dateComponents([.year, .month, .day], from: currentPeriod).description
            case .month, .sixMonths, .year:
                periodKey = calendar.monthYearKey(for: currentPeriod)
            }
            
            let totalFee = timePeriodTotals[periodKey] ?? 0
            
            result.append(MonthlyTotal(
                date: currentPeriod,
                totalFee: totalFee
            ))
            
            // Move to next period
            switch timeRange {
            case .week:
                currentPeriod = calendar.date(byAdding: .day, value: 1, to: currentPeriod) ?? currentPeriod
            case .month, .sixMonths, .year:
                currentPeriod = calendar.date(byAdding: .month, value: 1, to: currentPeriod) ?? currentPeriod
            }
        }
        
        return result.sorted { $0.date < $1.date }
    }
    
   
    
    var body: some View {
        NavigationView {
            VStack {
                // Debug info
                Text("Projects count: \(projects.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("Chart data count: \(totalsByTimeRange.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                if let firstProject = projects.first {
                    Text("First project: \(firstProject.projectName) - \(firstProject.dateClosed, format: .dateTime.month().day().year())")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Time range picker
                Picker("Time Range", selection: $timeRange) {
                    ForEach(TimeRange.allCases, id: \.self) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                
                
                // Scrollable Chart with stacked bars by media type
                Chart(totalsByTimeRange) { data in
                    BarMark(
                        x: .value("Time Period", data.date, unit: timeRange == .week ? .day : .month),
                        y: .value("Total Fee", data.totalFee)
                    )
                    .foregroundStyle(by: .value("Media Type", data.mediaType.rawValue))
                    //.opacity(data.totalFee > 0 ? 1.0 : 0.0) // Hide zero values
                }
                .frame(height: 350)
                //.chartScrollableAxes(.horizontal
                //.chartXVisibleDomain(length: visibleDomainLength)
//                .chartForegroundStyleScale([
//                    "Film": Color(.systemGreen),
//                    "TV": Color(.systemPink),
//                    "Recording": Color(.systemRed),
//                    "Concert": Color(.systemBlue),
//                    "Tour": Color(.systemCyan),
//                    "Lesson": Color(.systemOrange),
//                    "Other": Color(.systemPurple)
//                ])
//                .chartXAxis {
//                    AxisMarks(values: axisStride) { value in
//                        AxisGridLine()
//                        AxisTick()
//                        AxisValueLabel(format: axisLabelFormat, centered: true)
//                    }
//                }
//                .chartYAxis {
//                    AxisMarks { value in
//                        AxisGridLine()
//                        AxisTick()
//                        AxisValueLabel(format: .currency(code: "USD"))
//                    }
//                }
//                .chartLegend(position: .bottom) {
//                    HStack {
//                        ForEach(MediaType.allCases, id: \.self) { mediaType in
//                            HStack(spacing: 4) {
//                                Rectangle()
//                                    .fill(colorForMediaType(mediaType))
//                                    .frame(width: 12, height: 12)
//                                Text(mediaType.rawValue.capitalized)
//                                    .font(.caption)
//                            }
//                        }
//                    }
//                }
                .padding()
                
                Spacer()
            }
            .navigationTitle(navigationTitle)
        }
    }
    
    private var visibleDomainLength: Int {
        switch timeRange {
        case .week:
            return 28 // Show 4 weeks (28 days) at a time
        case .month:
            return 12 // Show 12 months at a time
        case .sixMonths:
            return 6 // Show 6 months at a time
        case .year:
            return 12 // Show 12 months at a time
        }
    }
    
    private var navigationTitle: String {
        switch timeRange {
        case .week:
            return "Income This Week"
        case .month:
            return "Income by Month"
        case .sixMonths:
            return "Income (6 Months)"
        case .year:
            return "Income This Year"
        }
    }
    
    private var axisStride: AxisMarkValues {
        switch timeRange {
        case .week:
            return .stride(by: .day, count: 1)
        case .month:
            return .stride(by: .month, count: 1)
        case .sixMonths:
            return .stride(by: .month, count: 1)
        case .year:
            return .stride(by: .month, count: 1)
        }
    }
    
    private var axisLabelFormat: Date.FormatStyle {
        switch timeRange {
        case .week:
            return .dateTime.weekday(.abbreviated)
        case .month:
            return .dateTime.month(.abbreviated)
        case .sixMonths:
            return .dateTime.month(.abbreviated)
        case .year:
            return .dateTime.month(.abbreviated)
        }
    }
    
    private func colorForMediaType(_ mediaType: MediaType) -> Color {
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

// MARK: - Calendar Extensions
extension Calendar {
    func startOfMonth(for date: Date) -> Date {
        let components = dateComponents([.year, .month], from: date)
        return self.date(from: components) ?? date
    }
    
    func endOfMonth(for date: Date) -> Date {
        guard let startOfMonth = self.date(from: dateComponents([.year, .month], from: date)),
              let endOfMonth = self.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth) else {
            return date
        }
        return endOfMonth
    }
    
    func monthYearKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        return formatter.string(from: date)
    }
}

//#Preview("Income by Time Range Chart") {
//    @MainActor
//    struct PreviewContainer: View {
//        let container: ModelContainer
//        
//        init() {
//            // Create in-memory container
//            let schema = Schema([Project.self, Item.self])
//            let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
//            
//            do {
//                container = try ModelContainer(for: schema, configurations: [configuration])
//                
//                // Insert mock data into the container
//                let context = container.mainContext
//                let calendar = Calendar.current
//                let mediaTypes: [MediaType] = [.film, .recording, .concert, .tv, .lesson, .tour, .other]
//                
//                // Create projects for the current year
//                let currentYear = calendar.component(.year, from: Date())
//                for month in 1...12 {
//                    guard let monthDate = calendar.date(from: DateComponents(year: currentYear, month: month, day: 15)) else { continue }
//                    
//                    // Add 1-4 projects per month with varying media types
//                    let projectCount = Int.random(in: 1...4)
//                    for i in 0..<projectCount {
//                        let mediaType = mediaTypes.randomElement() ?? .recording
//                        let project = Project(
//                            projectName: "\(mediaType.rawValue) Project \(month)-\(i)",
//                            artist: "Artist \(month)-\(i)",
//                            mediaType: mediaType,
//                            paid: true,
//                            dateClosed: monthDate
//                        )
//                        
//                        // Create mock items with realistic fees based on media type
//                        let baseFee = baseFeeForMediaType(mediaType)
//                        let item1 = Item(
//                            name: "Primary Service",
//                            fee: baseFee + Double.random(in: -200...500)
//                        )
//                        let item2 = Item(
//                            name: "Additional Work", 
//                            fee: Double.random(in: 100...800)
//                        )
//                        
//                        context.insert(project)
//                        context.insert(item1)
//                        context.insert(item2)
//                        
//                        project.items = [item1, item2]
//                    }
//                }
//                
//                // Add some projects for current week (for week view testing)
//                let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
//                for dayOffset in 0..<7 {
//                    guard let dayDate = calendar.date(byAdding: .day, value: dayOffset, to: startOfWeek) else { continue }
//                    
//                    if Int.random(in: 1...3) == 1 { // Random chance of having projects each day
//                        let mediaType = mediaTypes.randomElement() ?? .recording
//                        let project = Project(
//                            projectName: "Daily \(mediaType.rawValue) Project",
//                            artist: "Week Artist \(dayOffset)",
//                            mediaType: mediaType,
//                            paid: true,
//                            dateClosed: dayDate
//                        )
//                        
//                        let baseFee = baseFeeForMediaType(mediaType)
//                        let item = Item(
//                            name: "Daily Work",
//                            fee: baseFee * 0.5 // Smaller amounts for daily view
//                        )
//                        
//                        context.insert(project)
//                        context.insert(item)
//                        project.items = [item]
//                    }
//                }
//                
//                try context.save()
//            } catch {
//                fatalError("Failed to create preview container: \(error)")
//            }
//        }
//        
//        var body: some View {
//            IncomeByMonthView()
//                .modelContainer(container)
//        }
//    }
//    
//    // Helper function to set realistic base fees
//    func baseFeeForMediaType(_ mediaType: MediaType) -> Double {
//        switch mediaType {
//        case .film:
//            return Double.random(in: 2000...5000)
//        case .tv:
//            return Double.random(in: 1500...4000)
//        case .recording:
//            return Double.random(in: 800...2500)
//        case .concert:
//            return Double.random(in: 500...2000)
//        case .tour:
//            return Double.random(in: 1000...3000)
//        case .lesson:
//            return Double.random(in: 50...150)
//        case .other:
//            return Double.random(in: 200...1000)
//        }
//    }
//    
//    return PreviewContainer()
//}
