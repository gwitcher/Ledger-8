//
//  BankingInfoView.swift
//  Ledger 8
//
//  Created by Gabe Witcher on 5/6/25.
//

import SwiftUI

struct BankingInfoView: View {
    
    @AppStorage("userData") var userData = UserData()
    
    
    var body: some View {
        Form {
            Section("Banking Info") {
                LabeledContent {
                    TextField("", text: $userData.bankingInfo.bank)
                        .autocorrectionDisabled()
                    
                }   label: {
                    Text("Bank:").foregroundStyle(.secondary)
                    
                }
                LabeledContent {
                    TextField("", text: $userData.bankingInfo.accountName)
                        .autocorrectionDisabled()
                    
                }   label: {
                    Text("Name on Account:").foregroundStyle(.secondary)
                    
                }
                LabeledContent {
                    TextField("", text: $userData.bankingInfo.routingNumber)
                        .autocorrectionDisabled()
                    
                }   label: {
                    Text("Routing Number:").foregroundStyle(.secondary)
                    
                }
                LabeledContent {
                    TextField("", text: $userData.bankingInfo.accountNumber)
                        .autocorrectionDisabled()
                    
                }   label: {
                    Text("Account Number:").foregroundStyle(.secondary)
                    
                }
            }
            Section("Apps"){
                LabeledContent {
                    TextField("", text: $userData.bankingInfo.venmo)
                        .autocorrectionDisabled()
                    
                }   label: {
                    Text("Venmo:").foregroundStyle(.secondary)
                    
                }
                LabeledContent {
                    TextField("", text: $userData.bankingInfo.zelle)
                        .autocorrectionDisabled()
                    
                }   label: {
                    Text("Zelle:").foregroundStyle(.secondary)
                    
                }
                
            }
        }
        //.font(.caption)

    }
}

#Preview {
    BankingInfoView(userData: UserData())
}
