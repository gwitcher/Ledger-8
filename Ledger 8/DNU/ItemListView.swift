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
    @Environment(\.dismiss) var dismiss
    
    var project: Project
    
    @State private var itemEditIsPresented = false
    
    var body: some View {
        
        VStack {
            List {
                ForEach(project.items ?? []) {item in
                    ItemView(item: item)
                        .onTapGesture {
                            itemEditIsPresented = true
                        }
                        .containerShape(Rectangle())
                        .sheet(isPresented: $itemEditIsPresented, content: {
                            ItemEditView(item: item)
                        })
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
        }
        .navigationTitle(project.projectName)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
        }
    }
}


//#Preview {
//    ItemLIstView()
//}
