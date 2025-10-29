//
//  AnalyticsDashboardViewModel.swift
//  Ledger 8
//
//  Created by Gabe Witcher on 10/28/25.
//

import Foundation
import SwiftUI

@Observable
@MainActor
class AnalyticsDashboardViewModel {
    
    // MARK: - Types
    enum Timeframe: String, CaseIterable {
        case month = "Month"
        case quarter = "Quarter"
        case yearToDate = "YTD"
        case lastYear = "Last Year"
        case allTime = "All Time"
    }
    
    struct AnalyticsMetrics {
        let totalIncome: Double
        let paidIncome: Double
        let unpaidIncome: Double
        let gigCount: Int
        let averageGigValue: Double
    }
    
    struct MediaTypeData {
        let type: String
        let income: Double
        let count: Int
    }
    
    struct ItemTypeData {
        let type: String
        let income: Double
        let count: Int
    }
    
    struct MonthlyData {
        let month: Date
        let income: Double
    }
    
    // MARK: - UI State
    var selectedYear: Int = Calendar.current.component(.year, from: Date())
    var selectedTimeframe: Timeframe = .yearToDate
    var showingExportSheet = false
    
    // MARK: - Private Properties
    private var allProjects: [Project] = []
    
    // MARK: - Computed Properties
    var filteredProjects: [Project] {
        let calendar = Calendar.current
        let now = Date()
        
        return allProjects.filter { project in
            switch selectedTimeframe {
            case .month:
                return calendar.isDate(project.startDate, equalTo: now, toGranularity: .month)
            case .quarter:
                let currentQuarter = (calendar.component(.month, from: now) - 1) / 3
                let projectQuarter = (calendar.component(.month, from: project.startDate) - 1) / 3
                return currentQuarter == projectQuarter &&
                       calendar.isDate(project.startDate, equalTo: now, toGranularity: .year)
            case .yearToDate:
                return calendar.component(.year, from: project.startDate) == calendar.component(.year, from: now) &&
                       project.startDate <= now
            case .lastYear:
                return calendar.component(.year, from: project.startDate) == calendar.component(.year, from: now) - 1
            case .allTime:
                return true
            }
        }
    }
    
    var analyticsMetrics: AnalyticsMetrics {
        let projects = filteredProjects
        let totalIncome = projects.reduce(0.0) { total, project in
            total + project.calculateFeeTotal(items: project.items ?? [])
        }
        
        let paidIncome = projects.filter { $0.paid }.reduce(0.0) { total, project in
            total + project.calculateFeeTotal(items: project.items ?? [])
        }
        
        let unpaidIncome = totalIncome - paidIncome
        let gigCount = projects.count
        let averageGigValue = gigCount > 0 ? totalIncome / Double(gigCount) : 0
        
        return AnalyticsMetrics(
            totalIncome: totalIncome,
            paidIncome: paidIncome,
            unpaidIncome: unpaidIncome,
            gigCount: gigCount,
            averageGigValue: averageGigValue
        )
    }
    
    var incomeByMediaType: [MediaTypeData] {
        let projects = filteredProjects
        let grouped = Dictionary(grouping: projects, by: { $0.mediaType })
        return grouped.map { 
            MediaTypeData(
                type: $0.key.rawValue,
                income: $0.value.reduce(0.0) { $0 + $1.calculateFeeTotal(items: $1.items ?? []) },
                count: $0.value.count
            )
        }
        .sorted { $0.income > $1.income }
        .prefix(8)
        .map { $0 }
    }
    
    var incomeByItemType: [ItemTypeData] {
        let projects = filteredProjects
        var itemTypeIncome: [String: (income: Double, count: Int)] = [:]
        
        for project in projects {
            guard let items = project.items else { continue }
            for item in items {
                let typeName = item.itemType.rawValue
                let currentData = itemTypeIncome[typeName] ?? (income: 0.0, count: 0)
                itemTypeIncome[typeName] = (
                    income: currentData.income + item.fee,
                    count: currentData.count + 1
                )
            }
        }
        
        return itemTypeIncome.map { 
            ItemTypeData(type: $0.key, income: $0.value.income, count: $0.value.count) 
        }
        .sorted { $0.income > $1.income }
    }
    
    var monthlyIncomeData: [MonthlyData] {
        let projects = filteredProjects
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: projects) { project in
            calendar.startOfMonth(for: project.startDate)
        }
        
        return grouped.map { 
            MonthlyData(
                month: $0.key,
                income: $0.value.reduce(0.0) { $0 + $1.calculateFeeTotal(items: $1.items ?? []) }
            )
        }
        .sorted { $0.month < $1.month }
        .suffix(12)
        .map { $0 }
    }
    
    var monthlyTrendStats: (average: Double, best: Double, trendPercentage: String, trendColor: Color) {
        let data = monthlyIncomeData
        
        let averageMonthlyIncome: Double = {
            guard !data.isEmpty else { return 0 }
            let total = data.reduce(0.0) { $0 + $1.income }
            return total / Double(data.count)
        }()
        
        let bestMonth = data.map { $0.income }.max() ?? 0
        
        let (trendPercentage, trendColor): (String, Color) = {
            guard data.count >= 2 else { return ("N/A", .gray) }
            let recent = data.suffix(3).reduce(0.0) { $0 + $1.income }
            let previous = data.prefix(max(1, data.count - 3)).reduce(0.0) { $0 + $1.income }
            
            guard previous > 0 else { return ("N/A", .gray) }
            let change = ((recent - previous) / previous * 100)
            let changeString = "\(change > 0 ? "+" : "")\(change.formatted(.number.precision(.fractionLength(1))))%"
            let color: Color = recent > previous ? .green : .red
            return (changeString, color)
        }()
        
        return (averageMonthlyIncome, bestMonth, trendPercentage, trendColor)
    }
    
    // MARK: - Initialization
    init(projects: [Project] = []) {
        self.allProjects = projects
    }
    
    // MARK: - Business Logic Methods
    func updateProjects(_ projects: [Project]) {
        self.allProjects = projects
    }
    
    func updateTimeframe(_ timeframe: Timeframe) {
        selectedTimeframe = timeframe
    }
    
    func showExportSheet() {
        showingExportSheet = true
    }
    
    func hideExportSheet() {
        showingExportSheet = false
    }
    
    // MARK: - Export Methods
    func generateCSVContent() -> String {
        let projects = filteredProjects
        var csv = "Project,Artist,Client,Date,Media Type,Income,Paid\n"
        
        for project in projects {
            let projectName = project.projectName.replacingOccurrences(of: "\"", with: "\"\"")
            let artist = project.artist.replacingOccurrences(of: "\"", with: "\"\"")
            let clientName = project.client?.fullName.replacingOccurrences(of: "\"", with: "\"\"") ?? "No Client"
            let dateString = project.startDate.formatted(date: .numeric, time: .omitted)
            let income = project.calculateFeeTotal(items: project.items ?? [])
            let paidStatus = project.paid ? "Yes" : "No"
            
            csv += "\"\(projectName)\",\"\(artist)\",\"\(clientName)\",\(dateString),\(project.mediaType),\(income),\(paidStatus)\n"
        }
        
        // Add summary at the end
        let metrics = analyticsMetrics
        csv += "\n"
        csv += "Summary\n"
        csv += "Total Projects,\(metrics.gigCount)\n"
        csv += "Total Income,\(metrics.totalIncome)\n"
        csv += "Paid Income,\(metrics.paidIncome)\n"
        csv += "Unpaid Income,\(metrics.unpaidIncome)\n"
        
        return csv
    }
    
    func generateTextSummary() -> String {
        let metrics = analyticsMetrics
        
        return """
        Analytics Summary - \(selectedYear)
        
        Total Income: \(metrics.totalIncome.formatted(.currency(code: "USD")))
        Paid: \(metrics.paidIncome.formatted(.currency(code: "USD")))
        Unpaid: \(metrics.unpaidIncome.formatted(.currency(code: "USD")))
        
        Total Gigs: \(metrics.gigCount)
        Average per Gig: \(metrics.averageGigValue.formatted(.currency(code: "USD")))
        
        Generated from Ledger 8
        """
    }
    
    func createCSVFile() -> URL {
        let csvContent = generateCSVContent()
        
        // Create temporary file
        let fileName = "ledger_analytics_\(selectedYear).csv"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        do {
            try csvContent.write(to: tempURL, atomically: true, encoding: .utf8)
            return tempURL
        } catch {
            print("Error creating CSV: \(error.localizedDescription)")
            // Return empty file if error
            return FileManager.default.temporaryDirectory.appendingPathComponent("error.txt")
        }
    }
    
    // MARK: - Helper Methods
    func colorForItemType(at index: Int) -> Color {
        let colors: [Color] = [.blue, .green, .orange, .purple, .pink, .red, .yellow, .cyan, .indigo, .mint]
        return colors[index % colors.count]
    }
    
    func percentageOfTotal(income: Double) -> Double {
        let totalIncome = incomeByMediaType.reduce(0.0) { $0 + $1.income }
        guard totalIncome > 0 else { return 0 }
        return (income / totalIncome * 100)
    }
    
    func percentageOfTotalItems(income: Double) -> Double {
        let totalIncome = incomeByItemType.reduce(0.0) { $0 + $1.income }
        guard totalIncome > 0 else { return 0 }
        return (income / totalIncome * 100)
    }
}

// MARK: - Extensions
private extension Calendar {
    func startOfMonth(for date: Date) -> Date {
        let components = dateComponents([.year, .month], from: date)
        return self.date(from: components) ?? date
    }
}