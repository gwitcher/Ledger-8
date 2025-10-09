//
//  ItemEditView.swift
//  Ledger 8
//
//  Created by Gabe Witcher on 4/16/25.
//

import SwiftUI
import SwiftData

struct ItemEditView: View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss
    
    var item: Item
    
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
                    }   label: {
                        Text("").foregroundStyle(.secondary)
                            .textContentType(.name)
                            .submitLabel(.next)
                            .focused($focusField, equals: .itemName)
                            .onSubmit {
                                focusField = .fee
                            }
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
                .onAppear {
                    name = item.name
                    itemType = item.itemType
                    fee = item.fee
                    notes = item.notes
                }
                
            }
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel", systemImage: "xmark", role: .cancel) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done", systemImage: "checkmar.circle.fill") {
                        item.name = name
                        item.itemType = itemType
                        item.fee = fee ?? .zero
                        dismiss()
                        
                    }
                }
            }
        }
    }
    
}

#Preview {
    ItemEditView(item: Item(name: "", fee: 0.0))
}
