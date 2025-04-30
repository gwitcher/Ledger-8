//
//  ShowInvoice.swift
//  Ledger 8
//
//  Created by Gabe Witcher on 4/28/25.
//

import SwiftUI
import PDFKit

struct ShowInvoice: View {
    
    let pdfURL: URL
    
    var body: some View {
        PDFKitView(url: pdfURL)
    }
}

struct PDFKitView: UIViewRepresentable {
    
    let url: URL
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = PDFDocument(url: self.url)
        pdfView.autoScales = true
        return pdfView
    }
    
    func updateUIView(_ pdfView: PDFView, context: Context) {
        // Update pdf if needed
    }
}

//
//#Preview {
//    ShowInvoice()
//}
