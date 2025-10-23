//
//  FlexibleInvoiceTemplateView.swift
//  Ledger 8
//
//  Enhanced invoice template with flexible empty field handling
//

import SwiftUI
import SwiftData

struct FlexibleInvoiceTemplateView: View {
    @Environment(\.modelContext) var modelContext
    
    @AppStorage("userData") var userData = UserData()
    var project: Project
    
    var body: some View {
        VStack(alignment: .leading) {
            ZStack {
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .foregroundStyle(Color.invoice1)
                    .opacity(0.2)
                
                HStack(alignment: .top) {
                    CompanyLogoView()
                    Spacer()
                    FlexibleInvoiceAndFee(project: project)
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
            
            ImprovedItemTableView(project: project)
                .padding()
                .minimumScaleFactor(0.5)
            
            BankingInvoiceView()
                .frame(width: 250, height: 150)
                .padding()
            
            Spacer()
        }
    }
}

struct FlexibleInvoiceAndFee: View {
    @AppStorage("InitialInvoiceNumber") var initialInvoiceNumber = 0
    
    var project: Project
    
    var body: some View {
        let invoiceNumber = project.invoice?.number ?? initialInvoiceNumber
        let displayNumber = invoiceNumber > 0 ? String(invoiceNumber) : "TBD"
        
        VStack(alignment: .center) {
            Text("Invoice: \(displayNumber)")
                .font(.subheadline)
                .padding(.horizontal)
                .lineLimit(1)
                .minimumScaleFactor(0.2)
            
            Spacer()
            
            Button {
                // No Action - this is just for display
            } label: {
                let totalAmount = calculateTotalAmount()
                Text("Due: \(totalAmount.formatted(.currency(code: "USD")))")
            }
            .buttonBorderShape(.capsule)
            .buttonStyle(.borderedProminent)
            .tint(calculateTotalAmount() > 0 ? .feeButton : .feeButton)
            .font(.subheadline)
            .fontWeight(.bold)
            .foregroundStyle(.black)
            .lineLimit(1)
            .minimumScaleFactor(0.2)
        }
        .padding()
    }
    
    private func calculateTotalAmount() -> Double {
        guard let items = project.items, !items.isEmpty else {
            return 0.0
        }
        return project.calculateFeeTotal(items: items)
    }
}

#Preview {
    FlexibleInvoiceTemplateView(project: Project(projectName: "Dummy", artist: "Dummy", startDate: Date()))
}
