//
//  AddInvoiceView.swift
//  Ledger 8
//
//  Created by Gabe Witcher on 4/24/25.
//

import SwiftUI
import SwiftData

struct AddInvoiceView: View {
    @Environment(\.modelContext) var modelContext
    
    var project: Project
    
    @Query var invoices: [Invoice]
    
    //let invoiceNumbers = [1002, 1003, 1004, 1007, 1009, 1012]
    
    @State private var newInvoice: Invoice?
    
    var body: some View {
        
            Button {
                
                let newInvoice = project.renderInvoice(project: project, invoiceNumber: nextInvoiceNumber(invoices: invoices))
                print("\(newInvoice.url?.absoluteString ?? "No URL")")
                    saveInvoice(invoice: newInvoice)
                
                
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(.green)
                    Text("Add Invoice")
                        .tint(.primary)
                }
            }
    }
    
    
    func saveInvoice(invoice: Invoice) {
        project.invoice = invoice
        
        modelContext.insert(invoice)
        guard let _ = try? modelContext.save() else{
            print("😡 ERROR: Cannot save")
            return
        }
    }
    
    func nextInvoiceNumber(invoices: [Invoice]) -> Int{
        var invoiceNumbers: [Int] = []
        for invoice in invoices {
            invoiceNumbers.append(invoice.number)
        }
        return invoiceNumbers.max() ?? 0
    }
}

#Preview {
    AddInvoiceView(project: Project())
}
