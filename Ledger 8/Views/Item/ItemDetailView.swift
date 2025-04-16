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
    @State private var itemType = ItemType.overdub
    @State private var fee = Double("")
    
    
    @FocusState private var isFocused: Bool
    
    private let currencyNumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        
        return formatter
    }()
    
    private let decimalNumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = false
        
        return formatter
    }()
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Item Info") {
                    LabeledContent {
                        TextField("Item Name", text: $name)
                    }   label: {
                        Text("").foregroundStyle(.secondary)
                            .textContentType(.name)
                    }
                    
                    Picker(" Type", selection: $itemType) {
                        ForEach(ItemType.allCases) {type in
                            Text(type.rawValue)
                        }
                    }
                    
                    LabeledContent {
                        TextField("$ Fee", value: $fee, formatter: isFocused ? decimalNumberFormatter : currencyNumberFormatter)
                            .keyboardType(.decimalPad)
                            .focused($isFocused)
                        
                    } label: {
                        Text("")
                    }
                    .keyboardType(.decimalPad)
                }
                
                
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel", role: .cancel) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add") {
                        saveItem(name: name, fee: fee ?? .zero)
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
