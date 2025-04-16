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
                    
                    LabeledContent {
                        TextField("$ Fee", value: $fee, formatter: isFocused ? decimalNumberFormatter : currencyNumberFormatter)
                            .keyboardType(.decimalPad)
                            .focused($isFocused)
                        
                    } label: {
                        Text("")
                    }
                    .keyboardType(.decimalPad)
                }
                .onAppear {
                    name = item.name
                    fee = item.fee
                }
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Cancel", role: .cancel) {
                            dismiss()
                        }
                    }
                    
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") {
                            item.name = name
                            item.fee = fee ?? .zero
                            dismiss()
                            
                        }
                    }
                }
            }
            .navigationBarBackButtonHidden()
        }
    }
    
}

#Preview {
    ItemEditView(item: Item(name: "", fee: 0.0))
}
