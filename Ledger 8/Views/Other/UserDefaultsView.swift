//
//  UserDefaultsView.swift
//  Ledger 8
//
//  Created by Gabe Witcher on 5/7/25.
//

import SwiftUI
import SwiftData

struct UserDefaultsView: View {

    let saveKey = "userData"
   @State private var userData = UserData()
    
    
    
    var body: some View {
        NavigationStack {
            Form {
                Section(""){
                    LabeledContent {
                        TextField("", text: $userData.userName)
                            .autocorrectionDisabled()
                        
                    }   label: {
                        Text("Name:").foregroundStyle(.secondary)
                        
                    }
                }
                
                Section("Company Info"){
                    LabeledContent {
                        TextField("", text: $userData.company.name)
                            .autocorrectionDisabled()
                        
                    }   label: {
                        Text("Company:").foregroundStyle(.secondary)
                        
                    }
                    
                    LabeledContent {
                        TextField("", text: $userData.company.contact)
                            .autocorrectionDisabled()
                        
                    }   label: {
                        Text("Contact:").foregroundStyle(.secondary)
                        
                    }
                    
                    LabeledContent {
                        TextField("", text: $userData.company.address)
                            .autocorrectionDisabled()
                        
                    }   label: {
                        Text("Address:").foregroundStyle(.secondary)
                        
                    }
                    
                    LabeledContent {
                        TextField("", text: $userData.company.address2)
                            .autocorrectionDisabled()
                        
                    }   label: {
                        Text("Address2:").foregroundStyle(.secondary)
                        
                    }
                    
                    LabeledContent {
                        TextField("", text: $userData.company.city)
                            .autocorrectionDisabled()
                        
                    }   label: {
                        Text("City:").foregroundStyle(.secondary)
                        
                    }
                    LabeledContent {
                        TextField("", text: $userData.company.state)
                            .autocorrectionDisabled()
                        
                    }   label: {
                        Text("State:").foregroundStyle(.secondary)
                        
                    }
                    LabeledContent {
                        TextField("", text: $userData.company.zip)
                            .autocorrectionDisabled()
                        
                    }   label: {
                        Text("Zip:").foregroundStyle(.secondary)
                        
                    }
                }
                
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
            .navigationTitle("User Info")
            .toolbar {
                ToolbarItem(placement: .bottomBar) {
                    Button("Save") {
                        UserDefaults.standard.set(userData, forKey: saveKey)
                    }
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.roundedRectangle)
                }
            }
            .onAppear {
                
                
            }
            
        }
    }
}

#Preview {
    UserDefaultsView()
}
