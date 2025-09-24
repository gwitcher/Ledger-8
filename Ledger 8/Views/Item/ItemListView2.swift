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
    
    @State private var sheetIsPresented = false
    
    //@State private var itemEditIsPresented = false
    
    var body: some View {
        
        VStack {
            List {
                ForEach(project.items ?? []) {item in
                    NavigationLink {
                        ItemEditView(item: item)
                    } label: {
                        ItemView(item: item)
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
        .navigationTitle(project.projectName)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .status) {
                Button {
                    sheetIsPresented.toggle()
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(.green)
                        Text("Add Item")
                            .tint(.primary)
                    }
                }
            }
        }
        .sheet(isPresented: $sheetIsPresented) {
            ItemDetailView(project: project)
        }
    }
}

//#Preview {
//    ItemListView2()
//}
