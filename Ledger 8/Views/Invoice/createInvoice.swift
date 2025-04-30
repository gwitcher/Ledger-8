//
//  createInvoice.swift
//  Ledger 8
//
//  Created by Gabe Witcher on 4/28/25.
//

import SwiftUI


struct createInvoice: View {
    @Environment(\.modelContext) var modelContaxt
    
    var project: Project
    
    let invoiceNumbers = [1002, 1003, 1004, 1007, 1009, 1012]
    
    let invoiceDate = Date.now.formatted(date: .numeric, time: .omitted)
   
    
    var body: some View {
        let nextInvoiceNumber = (invoiceNumbers.max() ?? 0) + 1
        Text("\(nextInvoiceNumber.formatted(.number.grouping(.never)))")
        
        let invoiceName = "Invoice_\(nextInvoiceNumber)_\(String(describing: project.client?.name))_\(invoiceDate).pdf"
        
        Text(invoiceName)
        
        let fileNameFormat = Date.now.formatted(.iso8601.year().month().day().dateSeparator(.dash))
        
        Text(fileNameFormat)
    }
    
    
    
}

#Preview {
    createInvoice(project: Project())
}
