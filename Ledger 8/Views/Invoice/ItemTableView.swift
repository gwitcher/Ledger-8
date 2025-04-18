//
//  ItemTableView.swift
//  Ledger 8
//
//  Created by Gabe Witcher on 4/18/25.
//

import SwiftUI

struct ItemTableView: View {
    
    var items: [Item] = [
        Item(name: "Item 1", fee: 200.00, itemType: .arrangement),
        Item(name: "Item 2", fee: 200.00, itemType: .concert),
        Item(name: "Item 3", fee: 200.00, itemType: .overdub),
        Item(name: "Item 4", fee: 200.00, itemType: .session),
    ]
    
    var body: some View {
        
        List {
            Grid {
                GridRow {
                    Text("Type")
                    Text("Name")
                    Text("Fee")
                }
                .bold()
                .gridCellAnchor(UnitPoint(x: 1, y: 0.5))
                Divider()
                
                ForEach(items) { item in
                    GridRow {
                        Text(item.itemType.rawValue)
                            .gridCellAnchor(UnitPoint(x: 1, y: 0.5))
                        Text(item.name)
                            .gridCellAnchor(UnitPoint(x: 1, y: 0.5))
                        Text(item.fee.formatted(.currency(code: "USD")))
                            .gridCellAnchor(UnitPoint(x: 1, y: 0.5))
                    }
                    .gridCellUnsizedAxes(.vertical)
                }
                Divider()
                GridRow {
                    Text("")
                    Text("")
                    Text("TOTAL:   $800")
                        .font(.title3)
                        .bold()
                }
                .gridCellAnchor(UnitPoint(x: 1, y: 0.5))
            }
        }
        .padding()
//        Table(items) {
//            TableColumn("Type", value: \.itemType.rawValue)
//            TableColumn("Name", value: \.name)
//            TableColumn("Fee") { item in
//                Text(String(item.fee))
//                
//            }
//        }
    }
}

#Preview {
    ItemTableView()
}
