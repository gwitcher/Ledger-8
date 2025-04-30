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
    let invoiceNumbers = [1002, 1003, 1004, 1007, 1009, 1012]
    
    
    
    //@State private var showInvoiceLink = false
    @State private var newInvoice: Invoice?
    
    var body: some View {
        
        if (project.invoice == nil) {
            Button {
                
                let newInvoice = project.renderInvoice(project: project, invoiceNumbers: invoiceNumbers)
                
                    saveInvoice(invoice: newInvoice)
                
                
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(.green)
                    Text("Add Invoice")
                        .tint(.primary)
                }
            }
        } else {
            let url = URL(string: project.invoice?.urlString ?? "www.apple.com")
            NavigationLink("\(project.invoice?.name ?? "No URL")") {
                ShowInvoice(pdfURL: url!)
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
}

#Preview {
    AddInvoiceView(project: Project())
}
