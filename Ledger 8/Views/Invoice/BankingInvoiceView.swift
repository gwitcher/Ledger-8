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
        
        VStack(alignment: .leading, spacing: 3){
            HStack {
                Text("Bank:")
                
                Spacer()
                
                Text(userData.bankingInfo.bank)
            }
            HStack {
                Text("Name on Acct:")
                
                Spacer()
                
                Text(userData.bankingInfo.accountName)
            }
          
            HStack {
                Text("Routing:")
                Spacer()
                Text(userData.bankingInfo.routingNumber)
            }
            HStack {
                Text("Account:")
                Spacer()
                Text(userData.bankingInfo.accountNumber)
            }
            
            HStack {
                Text("Venmo:")
                Spacer()
                Text(userData.bankingInfo.venmo)
                    
            }
            HStack {
                Text("Zelle:")
                Spacer()
                Text(userData.bankingInfo.zelle)
            }
        }
        .font(.caption)
        //.foregroundStyle(.secondary)
       
    }
}

#Preview {
    BankingInvoiceView()
}
