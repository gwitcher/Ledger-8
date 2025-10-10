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
    
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var attention = ""
    @State private var address = ""
    @State private var address2 = ""
    @State private var city = ""
    @State private var state = ""
    @State private var zip = ""
    @State private var notes = ""
    @State private var company = ""
    
    @FocusState private var focusField: clientField?
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Client Info") {
                    LabeledContent {
                        TextField("", text: $firstName)
                            .autocorrectionDisabled()
                            .textContentType(.name)
                            .focused($focusField, equals: .firstName)
                            .submitLabel(.next)
                            .onSubmit {
                                focusField = .lastName
                            }
                        
                    }   label: {
                        Text("First Name").foregroundStyle(.secondary)
                            
                    }
                    
                    LabeledContent {
                        TextField("", text: $lastName)
                            .autocorrectionDisabled()
                            .textContentType(.name)
                            .focused($focusField, equals: .lastName)
                            .submitLabel(.next)
                            .onSubmit {
                                focusField = .email
                            }
                        
                    }   label: {
                        Text("Last Name").foregroundStyle(.secondary)
                            
                    }
                    
                    LabeledContent {
                        TextField("", text: $email)
                            .autocorrectionDisabled()
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .focused($focusField, equals: .email)
                            .submitLabel(.next)
                            .onSubmit {
                                focusField = .phone
                            }
                        
                    }   label: {
                        Text("Email").foregroundStyle(.secondary)
                            
                    }
                    
                    LabeledContent {
                        TextField("", text: $phone)
                            .autocorrectionDisabled()
                            .textContentType(.telephoneNumber)
                            .focused($focusField, equals: .phone)
                            .submitLabel(.next)
                            .onSubmit {
                                focusField = .company
                            }
                    }   label: {
                        Text("Phone").foregroundStyle(.secondary)
                            
                    }
                }
                
                Section("Company"){
                    LabeledContent {
                        TextField("", text: $company)
                            .autocorrectionDisabled()
                            .textContentType(.telephoneNumber)
                            .focused($focusField, equals: .company)
                            .submitLabel(.next)
                            .onSubmit {
                                focusField = .attn
                            }
                    }   label: {
                        Text("Company").foregroundStyle(.secondary)
                            
                    }
                }
                
                
                Section("Billing Info") {
                    LabeledContent {
                        TextField("", text: $attention)
                            .autocorrectionDisabled()
                            .textContentType(.name)
                            .focused($focusField, equals: .attn)
                            .submitLabel(.next)
                            .onSubmit {
                                focusField = .address
                            }
                        
                    }   label: {
                        Text("Attn:").foregroundStyle(.secondary)
                            
                    }
                    LabeledContent {
                        TextField("", text: $address)
                            .autocorrectionDisabled()
                            .textContentType(.streetAddressLine1)
                            .focused($focusField, equals: .address)
                            .submitLabel(.next)
                            .onSubmit {
                                focusField = .address2
                            }
                        
                    }   label: {
                        Text("Address").foregroundStyle(.secondary)
                            
                    }
                    LabeledContent {
                        TextField("", text: $address2)
                            .autocorrectionDisabled()
                            .textContentType(.streetAddressLine2)
                            .focused($focusField, equals: .address2)
                            .submitLabel(.next)
                            .onSubmit {
                                focusField = .city
                            }
                        
                    }   label: {
                        Text("Address 2").foregroundStyle(.secondary)
                            
                    }
                    LabeledContent {
                        TextField("", text: $city)
                            .autocorrectionDisabled()
                            .textContentType(.addressCity)
                            .focused($focusField, equals: .city)
                            .submitLabel(.next)
                            .onSubmit {
                                focusField = .state
                            }
                        
                    }   label: {
                        Text("City").foregroundStyle(.secondary)
                            
                    }
                    LabeledContent {
                        TextField("", text: $state)
                            .autocorrectionDisabled()
                            .textContentType(.addressState)
                            .focused($focusField, equals: .state)
                            .submitLabel(.next)
                            .onSubmit {
                                focusField = .zip
                            }
                    }   label: {
                        Text("State").foregroundStyle(.secondary)
                            
                    }
                    LabeledContent {
                        TextField("", text: $zip)
                            .autocorrectionDisabled()
                            .textContentType(.postalCode)
                            .focused($focusField, equals: .zip)
                            .submitLabel(.next)
                            .onSubmit {
                                focusField = .notes
                            }
                        
                    }   label: {
                        Text("Zip").foregroundStyle(.secondary)
                            
                    }
                }
                Section("Notes") {
                    TextField("Notes", text: $notes, axis: .vertical)
                }
                
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel", systemImage: "xmark", role: .cancel) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done", systemImage: "checkmark.circle.fill") {
                        saveClient(firstName: firstName, lastName: lastName, email: email, phone: phone,attention: attention, address: address, address2: address2, city: city, state: state, zip: zip, notes: notes, company: company)
                        
                        firstName = ""
                        lastName = ""
                        email = ""
                        phone = ""
                        attention = ""
                        address = ""
                        address2 = ""
                        city = ""
                        state = ""
                        zip = ""
                        notes = ""
                        company = ""
                        
                        dismiss()
                        
                    }
                }
            }
        }
        
    }
    
    func saveClient(firstName: String, lastName: String, email: String, phone: String, attention: String, address: String, address2: String, city: String, state: String, zip: String, notes: String, company: String ) {
        client.firstName = firstName
        client.lastName = lastName
        client.email = email
        client.phone = phone
        client.attention = attention
        client.address = address
        client.address2 = address2
        client.city = city
        client.state = state
        client.zip = zip
        client.notes = notes
        client.company = company
        
        
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
