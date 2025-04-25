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
                name = contact.name
                email = contact.email
                phone = contact.phone
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        contact.name = name
                        contact.email = email
                        contact.phone = phone
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
