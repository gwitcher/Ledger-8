//
//  ItemDetailView.swift
//  Ledger 8
//
//  Created by Gabe Witcher on 4/15/25.
//

import SwiftUI
import SwiftData

struct ItemDetailView: View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss
    
    var project: Project
    
    @State private var name = ""
    @State private var fee = 0.0
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("item", text: $name)
                TextField("Fee", value: $fee, format: .currency(code: "USD"))
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel", role: .cancel) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add") {
                        saveItem(name: name, fee: fee)
                        dismiss()
//                        name = ""
//                        fee = .zero
                    }
                }
            }
        }
        .navigationBarBackButtonHidden()
    }
    
    func saveItem(name: String, fee: Double) {
        let newItem = Item(name: name, fee: fee)
        
        project.items?.append(newItem)
        
        guard let _ = try? modelContext.save() else {
            print("ERROR: could not save")
            return
        }
    }
}

//#Preview {
//    ItemDetailView(item: Item())
//}
