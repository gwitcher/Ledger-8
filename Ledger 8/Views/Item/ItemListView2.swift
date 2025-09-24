//
//  ItemListView2.swift
//  Ledger 8
//
//  Created by Gabe Witcher on 9/22/25.
//

import SwiftUI
import SwiftData

struct ItemListView2: View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss
    
    var project: Project
    
    //@State private var itemEditIsPresented = false
    
    var body: some View {
        
        VStack {
            List {
                ForEach(project.items ?? []) {item in
                    NavigationLink {
                        ItemEditView(item: item)
                    } label: {
                        ItemView2(item: item)
                    }
                    .swipeActions {
                        Button("Delete", role: .destructive) {
                            modelContext.delete(item)
                            
                            guard let _ = try? modelContext.save() else {
                                print("😡 ERROR: Could not save after delete")
                                return
                            }
                        }
                    }
                }
            }
            .listStyle(.sidebar)
        }
//        .navigationTitle(project.projectName)
//        .toolbar {
//            ToolbarItem(placement: .topBarTrailing) {
//                Button("Done") {
//                    dismiss()
//                }
//            }
//        }
    }
}

//#Preview {
//    ItemListView2()
//}
