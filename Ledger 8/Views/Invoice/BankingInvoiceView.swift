//
//  BankingInvoiceView.swift
//  Ledger 8
//
//  Created by Gabe Witcher on 5/13/25.
//

import SwiftUI

struct BankingInvoiceView: View {
    @AppStorage("userData") var userData = UserData()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            // Only show banking info if at least one field is populated
            let bankingFields = collectBankingInfo()
            
            if !bankingFields.isEmpty {
                ForEach(bankingFields, id: \.label) { field in
                    HStack {
                        Text("\(field.label):")
                        Spacer()
                        Text(field.value)
                    }
                }
            } else {
                // Show placeholder or nothing when no banking info is available
                HStack {
                    Text("Payment Info:")
                    Spacer()
                    Text("To be provided")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .font(.caption)
    }
    
    private func collectBankingInfo() -> [(label: String, value: String)] {
        var fields: [(label: String, value: String)] = []
        
        let banking = userData.bankingInfo
        
        if !banking.bank.isEmpty {
            fields.append(("Bank", banking.bank))
        }
        
        if !banking.accountName.isEmpty {
            fields.append(("Name on Acct", banking.accountName))
        }
        
        if !banking.routingNumber.isEmpty {
            fields.append(("Routing", banking.routingNumber))
        }
        
        if !banking.accountNumber.isEmpty {
            fields.append(("Account", banking.accountNumber))
        }
        
        if !banking.venmo.isEmpty {
            fields.append(("Venmo", banking.venmo))
        }
        
        if !banking.zelle.isEmpty {
            fields.append(("Zelle", banking.zelle))
        }
        
        return fields
    }
}


#Preview {
    BankingInvoiceView()
}
