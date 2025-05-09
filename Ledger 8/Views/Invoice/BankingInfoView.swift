//
//  BankingInfoView.swift
//  Ledger 8
//
//  Created by Gabe Witcher on 5/6/25.
//

import SwiftUI

struct BankingInfoView: View {
    
    let bank = "Chase Bank"
    let routingNumber = "0021000021"
    let accountNumber = "4152479337"
    let accountName = "MFGW Family Group, Inc."
    let zelle = "gabewitcher@gmail.com"
    let venmo = "@Gabriel-Witcher"
    
    
    var body: some View {
        VStack(spacing: 6){
            LabeledContent {
                Text(bank)
            } label: {
                Text("Bank: ")
            }
            LabeledContent {
                Text(accountName)
            } label: {
                Text("Account Name: ")
            }
            LabeledContent {
                Text(routingNumber)
            } label: {
                Text("Routing Number: ")
            }
            LabeledContent {
                Text(accountNumber)
            } label: {
                Text("Account Number: ")
            }
            LabeledContent {
                Text(zelle)
            } label: {
                Text("Zelle: ")
            }
            LabeledContent {
                Text(venmo)
            } label: {
                Text("Venmo: ")
            }
        }
        .font(.caption)

    }
}

#Preview {
    BankingInfoView()
}
