//
//  CompanyInfoView.swift
//  Ledger 8
//
//  Created by Gabe Witcher on 5/10/25.
//

import SwiftUI

struct CompanyInfoView: View {
    
    @AppStorage("userData") var userData = UserData()
    
    var body: some View {
        Form {
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
                    TextField("", text: $userData.company.email)
                        .autocorrectionDisabled()
                    
                }   label: {
                    Text("Email:").foregroundStyle(.secondary)
                    
                }
                LabeledContent {
                    TextField("", text: $userData.company.phone)
                        .autocorrectionDisabled()
                    
                }   label: {
                    Text("Phone:").foregroundStyle(.secondary)
                    
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
        }
    }
}

#Preview {
    CompanyInfoView(userData: UserData())
}
