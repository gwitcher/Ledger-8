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
    
    func render(project: Project) -> URL {
           // 1: Render Hello World with some modifiers
           let renderer = ImageRenderer(content:
                                            InvoiceTemplateTest(project: project)
           )

           // 2: Save it to our documents directory
           let url = URL.documentsDirectory.appending(path: "Invoice_1111_PROJECT_DATE.pdf")
        
        

           // 3: Start the rendering process
           renderer.render { size, context in
               // 4: Tell SwiftUI our PDF should be the same size as the views we're rendering
               var box = CGRect(x: 0, y: 0, width: size.width, height: size.height)

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

           return url
       }
    
}
