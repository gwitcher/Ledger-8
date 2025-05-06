//
//  ContactEditView.swift
//  Ledger 8
//
//  Created by Gabe Witcher on 4/22/25.
//

import SwiftUI

struct ClientEditView: View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss
    
    var contact: Client
    
    @State private var name = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var attention = ""
    @State private var address = ""
    @State private var address2 = ""
    @State private var city = ""
    @State private var state = ""
    @State private var zip = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Client Info"){
                    LabeledContent {
                        TextField("", text: $name)
                            .autocorrectionDisabled()
                    }   label: {
                        Text("Contact").foregroundStyle(.secondary)
                    }
                    LabeledContent {
                        TextField("", text: $email)
                            .autocorrectionDisabled()
                    }   label: {
                        Text("Email").foregroundStyle(.secondary)
                    }
                    LabeledContent {
                        TextField("", text: $phone)
                            .autocorrectionDisabled()
                    }   label: {
                        Text("Phone").foregroundStyle(.secondary)
                    }
                }
                
                Section("Billing Info") {
                    LabeledContent {
                        TextField("", text: $attention)
                            .autocorrectionDisabled()
                    }   label: {
                        Text("Attn:").foregroundStyle(.secondary)
                    }
                    LabeledContent {
                        TextField("", text: $address)
                            .autocorrectionDisabled()
                            .textContentType(.streetAddressLine1)
                    }   label: {
                        Text("Address").foregroundStyle(.secondary)
                    }
                    LabeledContent {
                        TextField("", text: $address2)
                            .autocorrectionDisabled()
                            .textContentType(.streetAddressLine2)
                    }   label: {
                        Text("Address 2").foregroundStyle(.secondary)
                    }
                    LabeledContent {
                        TextField("", text: $city)
                            .autocorrectionDisabled()
                            .textContentType(.addressCity)
                    }   label: {
                        Text("City").foregroundStyle(.secondary)
                    }
                    LabeledContent {
                        TextField("", text: $state)
                            .autocorrectionDisabled()
                            .textContentType(.addressState)
                    }   label: {
                        Text("State").foregroundStyle(.secondary)
                    }
                    LabeledContent {
                        TextField("", text: $zip)
                            .autocorrectionDisabled()
                            .textContentType(.postalCode)
                    }   label: {
                        Text("Zip").foregroundStyle(.secondary)
                    }
                }
            }
            .onAppear {
                name = contact.name
                email = contact.email
                phone = contact.phone
                attention = contact.attention
                address = contact.address
                address2 = contact.address2
                city = contact.city
                state = contact.state
                zip = contact.zip
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        contact.name = name
                        contact.email = email
                        contact.phone = phone
                        contact.attention = attention
                        contact.address = address
                        contact.address2 = address2
                        contact.city = city
                        contact.state = state
                        contact.zip = zip
                        
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    ClientEditView(contact: Client())
}
