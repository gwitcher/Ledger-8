//
//  ItemLIstView.swift
//  Ledger 8
//
//  Created by Gabe Witcher on 4/15/25.
//

import SwiftUI
import SwiftData

struct ItemListView: View {
    @Environment(\.modelContext) var modelContext
    
    var project: Project
    
    var body: some View {
        
        List {
            ForEach(project.items ?? []) {item in
                NavigationLink {
                    ItemDetailView(project: project)
                } label: {
                    Text(item.name)
                }

            }
        }
        
    }
}

//#Preview {
//    ItemLIstView()
//}
