//
//  ContactDetailView.swift
//  Ledger 8
//
//  Created by Gabe Witcher on 4/22/25.
//

import SwiftUI
import SwiftData

struct NewClientView: View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss
    
    @State private var client = Client()
    
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
                Section("Client Info") {
                    LabeledContent {
                        TextField("", text: $name)
                            .autocorrectionDisabled()
                        
                    }   label: {
                        Text("Contact").foregroundStyle(.secondary)
                            
                    }
                    
                    LabeledContent {
                        TextField("", text: $email)
                            .autocorrectionDisabled()
                            .textContentType(.emailAddress)
                        
                    }   label: {
                        Text("Email").foregroundStyle(.secondary)
                            
                    }
                    
                    LabeledContent {
                        TextField("", text: $phone)
                            .autocorrectionDisabled()
                            .textContentType(.telephoneNumber)
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
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel", role: .cancel) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        saveClient(name: name, email: email, phone: phone, attention: attention, address: address, address2: address2, city: city, state: state, zip: zip)
                        
                        name = ""
                        email = ""
                        phone = ""
                        attention = ""
                        address = ""
                        address2 = ""
                        city = ""
                        state = ""
                        zip = ""
                        
                        dismiss()
                        
                    }
                }
            }
        }
        
    }
    
    func saveClient(name: String, email: String, phone: String, attention: String, address: String, address2: String, city: String, state: String, zip: String ) {
        client.name = name
        client.email = email
        client.phone = phone
        client.attention = attention
        client.address = address
        client.address2 = address2
        client.city = city
        client.state = state
        client.zip = zip
        
        
        modelContext.insert(client)
        guard let _ = try? modelContext.save() else{
            print("😡 ERROR: Cannot save")
            return
        }

    }
}

#Preview {
    NavigationStack {
        NewClientView()
    }
}
