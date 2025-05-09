//
//  InvoiceLinkView.swift
//  Ledger 8
//
//  Created by Gabe Witcher on 4/30/25.
//

import SwiftUI
import SwiftData
import PDFKit

struct InvoiceLinkView: View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss
    
    var project: Project
    
    @State private var invoiceSheetIsPresented = false
    
    
    
    var body: some View {
        
        let path = project.invoice?.url?.absoluteString
        
        NavigationStack {
            
            HStack {
                Image(systemName: "doc")
                Text("\(project.invoice?.name ?? "No Invoice")...")
                    .font(.footnote)
                    .minimumScaleFactor(0.5)
            }
            .onTapGesture {
                invoiceSheetIsPresented.toggle()
                print("Invoice url: \(String(describing: path))")
            }
            .swipeActions {
                Button("Delete", role: .destructive) {
                    deletePdf(invoice: project.invoice!)
                    project.invoice = nil
                }
                
                
            }
            .onAppear {
                print("\(path ?? "No URL")")
            }
            .sheet(isPresented: $invoiceSheetIsPresented) {
                if let pdfURL = project.invoice?.url! {
                    //ShowInvoice(pdfURL: url, pdfTitle: project.invoice!.name)
                    NavigationStack {
                        VStack{
                            WebkitPdfView(pdfURL: pdfURL, pdfTitle: project.invoice!.name)
                        }
                        .navigationTitle(project.invoice!.name)
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .topBarLeading) {
                                Button("Done") {
                                    dismiss()
                                }
                            }
                            
                            ToolbarItem(placement: .topBarTrailing) {
                                ShareLink(item: pdfURL)
                            }
                        }
                    }
                } else {
                    Text("No Invoice")
                }
            }
        }
        
    }
    func deletePdf(invoice: Invoice) {
        if let fileUrl = invoice.url {
            do {
                try FileManager.default.removeItem(at: fileUrl)
            } catch {
                print("😡ERROR: Can not remove file at path: \(fileUrl.lastPathComponent), \(error.localizedDescription)")
            }
            modelContext.delete(invoice)
            
        } else {
            print("ERROR: could not delete PDF \(invoice.name)")
        }
        guard let _ = try? modelContext.save() else{
            print("😡 ERROR: Cannot save")
            return
        }
    }
}
//#Preview {
//    InvoiceLinkView(project: Project(), invoiceSheetisPresented:)
//}
