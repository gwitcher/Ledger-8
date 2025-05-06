//
//  ItemTableView.swift
//  Ledger 8
//
//  Created by Gabe Witcher on 4/18/25.
//

import SwiftUI
import SwiftData

struct ItemTableView: View {
    @Environment(\.modelContext) var modelContext
    
    var project: Project
    
    //    var items: [Item] = [
    //        Item(name: "Item 1", fee: 200.00, itemType: .arrangement),
    //        Item(name: "Item 2", fee: 200.00, itemType: .concert),
    //        Item(name: "Item 3", fee: 200.00, itemType: .overdub),
    //        Item(name: "Item 4", fee: 200.00, itemType: .session),
    //    ]
    
    var body: some View {
        VStack {
            HStack{
                VStack (alignment: .leading) {
                    Text("Job Date: ")
                        .font(.caption)
                        .fontWeight(.medium)
                    
                    Text("Project: ")
                        .font(.caption)
                        .fontWeight(.medium)
                    
                }
                
                VStack(alignment: .trailing) {
                    
                    Text(project.jobDate.formatted(date: .numeric, time: .omitted))
                        .foregroundStyle(.opacity(0.8))
                    Text(project.projectName)
                        .foregroundStyle(.opacity(0.8))
                    
                }
                Spacer()
            }
            .font(.caption)
            .fontWeight(.medium)
            .minimumScaleFactor(0.5)
            .lineLimit(1)
            .padding(.bottom, 8)
           
            
            
            
            Group {
                Grid(verticalSpacing: 5){
                    GridRow {
                        Text("Type")
                        Text("Name")
                        Text("Fee")
                    }
                    .font(.subheadline)
                    .bold()
                    .gridCellAnchor(UnitPoint(x: 1, y: 0.5))
                    Divider()
                    
                    ForEach(project.items ?? []) { item in
                        GridRow {
                            Text(item.itemType.rawValue)
                                .gridCellAnchor(UnitPoint(x: 1, y: 0.5))
                            Text(item.name)
                                .gridCellAnchor(UnitPoint(x: 1, y: 0.5))
                            Text(item.fee.formatted(.currency(code: "USD")))
                                .gridCellAnchor(UnitPoint(x: 1, y: 0.5))
                        }
                        .font(.caption2)
                        .gridCellUnsizedAxes(.vertical)
                        Divider()
                    }
                    //Divider()
                    GridRow {
                        Text("")
                        Text("")
                        Text("Total:  \(project.calculateFeeTotal(items: project.items!).formatted(.currency(code: "USD")))")
                            .font(.subheadline)
                            .bold()
                    }
                    .gridCellAnchor(UnitPoint(x: 1, y: 0.5))
                }
            }
        }
        
        
        
    }
}

#Preview {
    ItemTableView(project: Project())
}
