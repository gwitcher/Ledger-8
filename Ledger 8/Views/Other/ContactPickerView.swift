//
//  ContactPickerView.swift
//  Ledger 8
//
//  Created by Gabe Witcher on 4/18/25.
//

import SwiftUI
import ContactsUI

struct ContactPickerView: View {
    
    @State private var selectedContact: CNContact?
    @State private var contactSheetIsPresented = false
    
    var body: some View {
        
        VStack {
            
            if selectedContact != nil{
                
                HStack {
                    Text("\(selectedContact?.givenName ?? "") \(selectedContact?.familyName ?? "")")
                        .fontWeight(.semibold)
                        .padding(5)
                        .background(.ultraThinMaterial)
                        
                    
                        
                    Spacer()
                    
                    Button {
                        selectedContact = nil
                    } label: {
                        Image(systemName: "xmark.octagon.fill")
                            .tint(.gray)
                    }

                }
            } else {
                Button("", systemImage: "person.crop.circle.badge.plus") {
                    contactSheetIsPresented.toggle()
                }
            }
            
            
            
        }
        .sheet(isPresented: $contactSheetIsPresented) {
            ContactPicker(selectedContact: self.$selectedContact)
            
        }
    }
    
    func printContact(contact: CNContact) {
        print(contact)
    }
}

#Preview {
    ContactPickerView()
}
