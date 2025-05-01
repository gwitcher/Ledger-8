//
//  InvoiceLinkView.swift
//  Ledger 8
//
//  Created by Gabe Witcher on 4/30/25.
//

import SwiftUI
import SwiftData

struct InvoiceLinkView: View {
    @Environment(\.modelContext) var modelContext
    
    var project: Project
    
    var body: some View {
        
        NavigationStack {
            
            NavigationLink {
                ShowInvoice(pdfURL: (project.invoice?.url)!)
            } label: {
                HStack {
                    Image(systemName: "doc")
                    Text("\(project.invoice?.name ?? "No Invoice")")
                        .font(.footnote)
                        .minimumScaleFactor(0.5)
                }
            }
        }
        .swipeActions {
            Button("Delete", role: .destructive) {
                modelContext.delete(project.invoice!)
            }
        }
        .onAppear {
            print("\(project.invoice?.url?.absoluteString ?? "No URL")")
        }
    }
}

#Preview {
    InvoiceLinkView(project: Project())
}
