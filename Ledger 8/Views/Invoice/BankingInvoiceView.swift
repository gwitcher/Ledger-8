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
        
        VStack(spacing: 3){
            LabeledContent {
                TextField("", text: $userData.bankingInfo.bank)
                    .autocorrectionDisabled()
                    .multilineTextAlignment(.trailing)
                
            }   label: {
                Text("Bank:").foregroundStyle(.secondary)
                
            }
            LabeledContent {
                TextField("", text: $userData.bankingInfo.accountName)
                    .autocorrectionDisabled()
                    .multilineTextAlignment(.trailing)
                
            }   label: {
                Text("Name on Account:").foregroundStyle(.secondary)
                
            }
            LabeledContent {
                TextField("", text: $userData.bankingInfo.routingNumber)
                    .autocorrectionDisabled()
                    .multilineTextAlignment(.trailing)
                
            }   label: {
                Text("Routing:").foregroundStyle(.secondary)
                
            }
            LabeledContent {
                TextField("", text: $userData.bankingInfo.accountNumber)
                    .autocorrectionDisabled()
                    .multilineTextAlignment(.trailing)
                
            }   label: {
                Text("Account:").foregroundStyle(.secondary)
                
            }
            
            LabeledContent {
                TextField("", text: $userData.bankingInfo.venmo)
                    .autocorrectionDisabled()
                    .multilineTextAlignment(.trailing)
                
            }   label: {
                Text("Venmo:").foregroundStyle(.secondary)
                
            }
            LabeledContent {
                TextField("", text: $userData.bankingInfo.zelle)
                    .autocorrectionDisabled()
                    .multilineTextAlignment(.trailing)
                
            }   label: {
                Text("Zelle:").foregroundStyle(.secondary)
                
            }
        }
        .font(.caption)
    }
}

#Preview {
    BankingInvoiceView()
}
