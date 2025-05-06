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
    
    @Query private var projects: [Project]
    var project: Project
    
    let defaultInvoiceNumber = 1000
    
    
    var body: some View {
        let nextInvoiceNumber = project.nextInvoiceNumber(projects: projects, defaultInvoiceNumber: defaultInvoiceNumber)
        
            Button {
                
                let newInvoice = project.renderInvoice(project: project, invoiceNumber: nextInvoiceNumber)
                print("\(newInvoice.url?.absoluteString ?? "No URL")")
                saveInvoice(newInvoice: newInvoice)
                
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(.green)
                    Text("Add Invoice")
                        .tint(.primary)
                }
            }
    }
    func saveInvoice(newInvoice: Invoice) {
        project.invoice = newInvoice
        
        guard let _ = try? modelContext.save() else{
            print("😡 ERROR: Cannot save")
            return
        }
        
    }
}

#Preview {
    AddInvoiceView(project: Project())
}
