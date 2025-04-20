//
//  ClientDetailView.swift
//  Ledger 8
//
//  Created by Gabe Witcher on 4/19/25.
//

import SwiftUI
import SwiftData

struct ClientDetailView: View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss
    
    var project: Project
    
    @State private var givenName = ""
    @State private var familyName = ""
    @State private var companyName = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var address = ""
    @State private var city = ""
    @State private var state = ""
    @State private var zip = ""
    
    var body: some View {
        
        NavigationStack {
            Form {
                Section {
                    LabeledContent {
                        TextField("", text: $givenName)
                    } label: {
                        Text("First Name").foregroundStyle(.secondary)
                            .autocorrectionDisabled()
                            .textContentType(.givenName)
                    }
                    
                    LabeledContent {
                        TextField("", text: $familyName)
                    } label: {
                        Text("Last Name").foregroundStyle(.secondary)
                            .autocorrectionDisabled()
                            .textContentType(.familyName)
                    }
                    
                    LabeledContent {
                        TextField("", text: $companyName)
                    } label: {
                        Text("Company").foregroundStyle(.secondary)
                            .autocorrectionDisabled()
                            .textContentType(.organizationName)
                    }
                }
                
                Section {
                    LabeledContent {
                        TextField("", text: $email)
                    } label: {
                        Text("Email").foregroundStyle(.secondary)
                            .autocorrectionDisabled()
                            .textContentType(.emailAddress)
                    }
                    .keyboardType(.emailAddress)
                    
                    LabeledContent {
                        TextField("", text: $phone)
                    } label: {
                        Text("Phone").foregroundStyle(.secondary)
                            .autocorrectionDisabled()
                            .textContentType(.telephoneNumber)
                    }
                    .keyboardType(.namePhonePad)
                }
                
                Section {
                    LabeledContent {
                        TextField("", text: $address)
                    } label: {
                        Text("Address").foregroundStyle(.secondary)
                            .autocorrectionDisabled()
                            .textContentType(.streetAddressLine1)
                    }
                    LabeledContent {
                        TextField("", text: $city)
                    } label: {
                        Text("City").foregroundStyle(.secondary)
                            .autocorrectionDisabled()
                            .textContentType(.addressCity)
                    }
                    
                    HStack {
                        LabeledContent {
                            TextField("", text: $state)
                        } label: {
                            Text("State").foregroundStyle(.secondary)
                                .autocorrectionDisabled()
                                .textContentType(.addressState)
                        }
                        
                        LabeledContent {
                            TextField("", text: $zip)
                        } label: {
                            Text("Zip").foregroundStyle(.secondary)
                                .autocorrectionDisabled()
                                .textContentType(.postalCode)
                        }
                        .keyboardType(.numberPad)
                    }
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button("Cancel", role: .cancel) {
                                dismiss()
                            }
                        }
                        
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Done") {
                                saveClient(givenName: givenName, familyName: familyName, companyName: companyName, email: email, phone: phone, address: address, city: city, state: state, zip: zip)
                                dismiss()
                            }
                        }
                    }
                    
                }
                .onAppear {
                    givenName = project.client?.givenName ?? ""
                    familyName = project.client?.familyName ?? ""
                    companyName = project.client?.companyName ?? ""
                    email = project.client?.email ?? ""
                    phone = project.client?.phone ?? ""
                    address = project.client?.address ?? ""
                    city = project.client?.city ?? ""
                    state = project.client?.state ?? ""
                    zip = project.client?.zip ?? ""
    
                }
                .navigationTitle("Client Info")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
    }
    
    func saveClient(givenName: String , familyName: String, companyName: String, email: String, phone: String, address: String, city: String, state: String, zip: String  ) {
        let newClient = Client(givenName: givenName, familyName: familyName, email: email, phone: phone, address: address, city: city, state: state, zip: zip, companyName: companyName)
        
        //TODO: Save Client here
        project.client = newClient
        
        guard let _ = try? modelContext.save() else{
            print("😡 ERROR: Cannot save")
            return
        }
    }
}

#Preview {
    NavigationStack {
        ClientDetailView(project: Project())
    }
}
