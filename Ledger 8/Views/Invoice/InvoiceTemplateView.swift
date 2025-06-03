//
//  InvoiceTemplateView.swift
//  Ledger 8
//
//  Created by Gabe Witcher on 4/17/25.
//

import SwiftUI
import SwiftData

struct InvoiceTemplateView: View {
    @Environment(\.modelContext) var modelContext
    
    @AppStorage("userData") var userData = UserData()
    // var userData = UserData()
    var project: Project
    
    
    
    var body: some View {
        
        VStack(alignment: .leading) {
            ZStack  {
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .foregroundStyle(Color.invoice1)
                    .opacity(0.2)
                
                HStack(alignment: .top) {
                        CompanyLogoView()
                        Spacer()
                        InvoiceAndFee(project: project)
                    }
                    .minimumScaleFactor(0.5)
                    .padding()
            }
            .frame(height: 150)
            
            HStack {
                PayerView(project: project)
                    .frame(width: 250, height: 150)
                
                Spacer()
            }
            .padding()
            
            ItemTableView(project: project)
                .padding()
                .minimumScaleFactor(0.5)
            
            BankingInvoiceView()
                .frame(width: 250, height: 150)
                .padding()
            
            
            Spacer()
        }
    }
}

#Preview {
    InvoiceTemplateView( project: Project(projectName: "Dummy", artist: "Dummy", startDate: Date()))
}


struct InvoiceAndFee: View {
    
    @AppStorage("InitialInvoiceNumber") var initialInvoiceNumber = 0
    
    var project: Project
    
    var body: some View {
        let invoiceNumber = project.invoice?.number ?? initialInvoiceNumber
        
        VStack (alignment: .center) {
            Text("Invoice: \((String(invoiceNumber)))")
                .font(.subheadline)
                .padding(.horizontal)
                .lineLimit(1)
                .minimumScaleFactor(0.2)
            
            Spacer()
            
            Button {
                //No Action
            } label: {
                if let items = project.items {
                    Text("Due: \(project.calculateFeeTotal(items: items).formatted(.currency(code: "USD")))")
                    
                } else {
                    Text("Due: $0.00")
                }
            }
            .buttonBorderShape(.capsule)
            .buttonStyle(.borderedProminent)
            .tint(.feeButton)
            .font(.subheadline)
            .fontWeight(.bold)
            .foregroundStyle(.black)
            .lineLimit(1)
            .minimumScaleFactor(0.2)
        }
        .padding()
    }
}
