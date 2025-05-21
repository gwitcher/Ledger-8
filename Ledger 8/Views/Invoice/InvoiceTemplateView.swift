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
    @AppStorage("InitialInvoiceNumber") var initialInvoiceNumber = 0
    
    var project: Project
    
    
    
    var body: some View {
        
        let invoiceNumber = project.invoice?.number ?? initialInvoiceNumber
        
        
        VStack(alignment: .leading) {
            HStack  {
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .foregroundStyle(Color.invoice1)
                    .opacity(0.2)
                    .overlay {
                        HStack (alignment: .top) {
                            CompanyLogoView()
                                .frame(width: 170, height: 100)
                                .padding(.top)
                                .minimumScaleFactor(0.5)
                            
                            
                            Spacer()
                            
                            VStack (alignment: .center) {
                                Text("Invoice: \((String(invoiceNumber)))")
                                    .font(.subheadline)
                                    .padding(.horizontal)
                                //.border(.blue)
                                
                                RoundedRectangle(cornerRadius: 30)
                                    .scaleEffect(1)
                                    .opacity(0.6)
                                    .foregroundStyle(.red)
                                    .overlay {
                                        if let items = project.items {
                                            Text("Due: \(project.calculateFeeTotal(items: items).formatted(.currency(code: "USD")))")
                                        } else {
                                            Text("Due: $0.00")
                                        }
                                    }
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .minimumScaleFactor(0.2)
                                    .lineLimit(1)
                                    .padding()
                                
                                
                                
                            }
                            .padding()
                            
                        }
                        .padding(.horizontal)
                    }
            }
            .frame(width: 400, height: 150)
            
            HStack {
                PayerView(project: project)
                    .frame(width: 250, height: 150)
                //.border(.black)
                
                Spacer()
            }
            .padding()
            //.background(.quinary)
            
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

