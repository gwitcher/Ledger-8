//
//  ContactDetailView.swift
//  Ledger 8
//
//  Created by Gabe Witcher on 4/22/25.
//

import SwiftUI
import SwiftData

struct ClientDetailView: View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss
    
    //var project: Project
    var client: Client
    
    @State private var name = ""
    @State private var email = ""
    @State private var phone = ""
    
    var body: some View {
        NavigationStack {
            Form {
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
            .onAppear {
                name = client.name
                email = client.email
                phone = client.phone
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel", role: .cancel) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        saveClient(name: name, email: email, phone: phone)
                        
                        name = ""
                        email = ""
                        phone = ""
                        dismiss()
                        
                    }
                }
            }
        }
        
    }
    
    func saveClient(name: String, email: String, phone: String) {
        client.name = name
        client.email = email
        client.phone = phone
        
        
        modelContext.insert(client)
        guard let _ = try? modelContext.save() else{
            print("😡 ERROR: Cannot save")
            return
        }

    }
}

#Preview {
    NavigationStack {
        ClientDetailView(client: Client())
    }
}
