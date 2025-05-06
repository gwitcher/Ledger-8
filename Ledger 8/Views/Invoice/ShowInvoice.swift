//
//  ShowInvoice.swift
//  Ledger 8
//
//  Created by Gabe Witcher on 4/28/25.
//

import SwiftUI
import PDFKit

struct ShowInvoice: View {
    @Environment(\.dismiss) var dismiss
    
    let pdfURL: URL
    let pdfTitle: String
  
    
    var body: some View {
        NavigationStack {
            VStack {
                PDFKitView(url: pdfURL)
                    .scaledToFit()
            }
            .toolbar {
                ToolbarItem {
                    ShareLink(item: pdfURL)
                }
                
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
            }
            .navigationTitle(pdfTitle)
            .navigationBarTitleDisplayMode(.inline)
        }
        
        
        
    }
}

struct PDFKitView: UIViewRepresentable {
    
    let url: URL
    
    init(url: URL) {
        self.url = url
    }
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = PDFDocument(url: self.url)
        pdfView.autoScales = true
        pdfView.displayDirection = .horizontal
        pdfView.minScaleFactor = 0.5
        pdfView.maxScaleFactor = 2.0
        return pdfView
    }
    
    func updateUIView(_ pdfView: PDFView, context: Context) {
        // Update pdf if needed
    }
}


//#Preview {
//    ShowInvoice(pdfURL: URL(string: "file:///Users/gabewitcher/Library/Developer/CoreSimulator/Devices/9E2EFB53-705A-4BAE-8085-6377A4C596D5/data/Containers/Data/Application/1F49E395-428A-46BA-AB22-668478B2049C/Documents/Invoice_1_Dude_2025-05-05.pdf")!)
//}
