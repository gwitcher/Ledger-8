//
//  ContactSelectorView.swift
//  Ledger 8
//
//  Created by Gabe Witcher on 4/23/25.
//

import SwiftUI
import SwiftData


struct ClientListView: View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss
    
    @Query(sort: \Client.name) var allClients: [Client]
    
    @State private var selectedContact =  Client()
    @State private var searchText = ""
    @State private var clientSheetIsPresented = false
    
    var filteredClient: [Client] {
        if searchText.isEmpty {
            allClients
        } else {
            allClients.filter {
                $0.name.localizedStandardContains(searchText)
            }
        }
    }
    
    var body: some View {
        
        NavigationStack {
            List {
                ForEach(filteredClient) {contact in
                    NavigationLink(destination: {
                        ClientEditView(contact: contact)
                    }, label: {
                        Text(contact.name)
                    })
                }
            }
            .listStyle(.plain)
            .searchable(text: $searchText)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("", systemImage: "plus") {
                        clientSheetIsPresented.toggle()
                    }
                }
                
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $clientSheetIsPresented) {
            ClientDetailView(client: Client())
        }
    }
}

#Preview {
    NavigationStack {
        ClientListView()
    }
}
