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
    @State private var notes = ""
    
    
    @FocusState private var isFocused: Bool
    @FocusState private var focusField: ItemField?
    
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
                            .textContentType(.name)
                            .focused($focusField, equals: .itemName)
                            .submitLabel(.next)
                            .onSubmit {
                                focusField = .fee
                            }
                    }   label: {
                        Text("").foregroundStyle(.secondary)
                            
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
                            .focused($focusField, equals: .fee)
                        
                    } label: {
                        Text("")
                    }
                    .keyboardType(.decimalPad)
                }
                
                Section("Notes") {
                    TextField("", text: $notes, axis: .vertical)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel", systemImage: "xmark", role: .cancel) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add") {
                        saveItem(name: name, fee: fee ?? .zero, itemType: itemType, notes: notes)
                        dismiss()
                    }
                }
                
                
                ToolbarItem(placement: .keyboard){
                    Button("Submit") {
                        isFocused = false
                    }
                    
                }
            }
        }
        .navigationBarBackButtonHidden()
    }
    
    func saveItem(name: String, fee: Double, itemType: ItemType, notes: String) {
        let newItem = Item(name: name, fee: fee, itemType: itemType, notes: notes)
        
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
