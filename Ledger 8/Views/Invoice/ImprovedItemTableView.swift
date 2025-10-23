//
//  ImprovedItemTableView.swift
//  Ledger 8
//
//  Enhanced version with better empty state handling
//

import SwiftUI
import SwiftData

struct ImprovedItemTableView: View {
    @Environment(\.modelContext) var modelContext
    
    var project: Project
    
    var body: some View {
        VStack {
            HStack {
                VStack(alignment: .leading) {
                    Text("Job Date: ")
                        .font(.caption)
                        .fontWeight(.medium)
                    
                    Text("Project: ")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                
                VStack(alignment: .trailing) {
                    Text(project.startDate.formatted(date: .numeric, time: .omitted))
                        .foregroundStyle(.opacity(0.8))
                    
                    Text(project.projectName.isEmpty ? "Project Name TBD" : project.projectName)
                        .foregroundStyle(.opacity(0.8))
                }
                Spacer()
            }
            .font(.caption)
            .fontWeight(.medium)
            .lineLimit(1)
            .padding(.bottom, 20)
            
            Group {
                Grid(verticalSpacing: 5) {
                    GridRow {
                        Text("Type")
                        Text("Name")
                        Text("Fee")
                    }
                    .font(.subheadline)
                    .bold()
                    .gridCellAnchor(UnitPoint(x: 1, y: 0.5))
                    Divider()
                    
                    // Handle empty items array gracefully
                    if let items = project.items, !items.isEmpty {
                        ForEach(items) { item in
                            GridRow {
                                Text(item.itemType.rawValue)
                                    .gridCellAnchor(UnitPoint(x: 1, y: 0.5))
                                Text(item.name.isEmpty ? "Item \(items.firstIndex(where: { $0.id == item.id }) ?? 0 + 1)" : item.name)
                                    .gridCellAnchor(UnitPoint(x: 1, y: 0.5))
                                Text(item.fee.formatted(.currency(code: "USD")))
                                    .gridCellAnchor(UnitPoint(x: 1, y: 0.5))
                            }
                            .font(.headline)
                            .foregroundStyle(.opacity(0.8))
                            .gridCellUnsizedAxes(.vertical)
                            Divider()
                        }
                        
                        GridRow {
                            Text("")
                            Text("")
                            Text("Total:  \(project.calculateFeeTotal(items: items).formatted(.currency(code: "USD")))")
                                .font(.subheadline)
                                .bold()
                        }
                        .gridCellAnchor(UnitPoint(x: 1, y: 0.5))
                    } else {
                        // Show placeholder when no items
                        GridRow {
                            Text("Service")
                                .gridCellAnchor(UnitPoint(x: 1, y: 0.5))
                            Text("Items to be determined")
                                .gridCellAnchor(UnitPoint(x: 1, y: 0.5))
                            Text("$0.00")
                                .gridCellAnchor(UnitPoint(x: 1, y: 0.5))
                        }
                        .font(.headline)
                        .foregroundStyle(.opacity(0.6))
                        .gridCellUnsizedAxes(.vertical)
                        Divider()
                        
                        GridRow {
                            Text("")
                            Text("")
                            Text("Total:  $0.00")
                                .font(.subheadline)
                                .bold()
                                .foregroundStyle(.opacity(0.6))
                        }
                        .gridCellAnchor(UnitPoint(x: 1, y: 0.5))
                    }
                }
            }
        }
    }
}

#Preview {
    ImprovedItemTableView(project: Project())
}