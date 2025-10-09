//
//  Extensions.swift
//  Ledger 8
//
//  Created by Gabe Witcher on 4/16/25.
//

import Foundation
import SwiftUI

@MainActor
extension Project {
    
    func calculateFeeTotal(items: [Item] ) -> Double {
        var total = 0.0
        for item in items {
            total += item.fee
        }
        return total
    }
    
    func projectsFeeTotal(projects: [Project]) -> Double {
        var projectTotal = 0.0
        for project in projects {
            projectTotal += project.calculateFeeTotal(items: project.items!)
        }
        return projectTotal
    }
    
    func renderInvoice(project: Project, invoiceNumber: Int) -> Invoice {
        let invoiceDate = Date.now
        let nextInvoiceNumber = invoiceNumber + 1
        let invoiceName = "Invoice_\(nextInvoiceNumber)_\(project.client?.fullName ?? "")_\(invoiceDate.formatted(.iso8601.year().month().day().dateSeparator(.dash))).pdf"
        
        let newInvoice = Invoice(number: nextInvoiceNumber, name: invoiceName)
        
        project.invoice = newInvoice
        
        // 1: Render Hello World with some modifiers
        let renderer = ImageRenderer(content:
                                        InvoiceTemplateView(project: project)
                                     
        )
        
        // 2: Save it to our documents directory
        let url = URL.documentsDirectory.appending(path: invoiceName)
        
        
        
        // 3: Start the rendering process
        renderer.render { size, context in
            // 4: Tell SwiftUI our PDF should be the same size as the views we're rendering
            var box = CGRect(x: 0, y: 0, width: size.width, height: size.height) //Letter size w: 612, h: 792
            
            // 5: Create the CGContext for our PDF pages
            guard let pdf = CGContext(url as CFURL, mediaBox: &box, nil) else {
                return
            }
            
            // 6: Start a new PDF page
            pdf.beginPDFPage(nil)
            
            // 7: Render the SwiftUI view data onto the page
            context(pdf)
            
            // 8: End the page and close the file
            pdf.endPDFPage()
            pdf.closePDF()
        }
        print("Invoice Name: \(invoiceName)")
        
        newInvoice.url = url
        
        return newInvoice
    }
    
    func nextInvoiceNumber(projects: [Project], defaultInvoiceNumber: Int) -> Int{
        var invoiceNumbers: [Int] = []
        for project in projects {
            invoiceNumbers.append(project.invoice?.number ?? defaultInvoiceNumber)
        }
        return invoiceNumbers.max() ?? defaultInvoiceNumber
        
        
    }
}

extension Date {
    func adding(minutes: Int) -> Date {
        Calendar.current.date(byAdding: .minute, value: minutes, to: self)!
    }

    func adding(hours: Int) -> Date {
        Calendar.current.date(byAdding: .hour, value: hours, to: self)!
    }
}

extension View {
    func hideKeyboard() {
        let resign = #selector(UIResponder.resignFirstResponder)
        UIApplication.shared.sendAction(resign, to: nil, from: nil, for: nil)
    }
}
