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
    
    @Query(sort: \Client.firstName) var allClients: [Client]
    

    @State private var searchText = ""
    @State private var clientSheetIsPresented = false
    
    var filteredClient: [Client] {
        if searchText.isEmpty {
            allClients
        } else {
            allClients.filter {
                $0.firstName.localizedStandardContains(searchText)
            }
        }
    }
    
    var body: some View {
        
        NavigationStack {
            Group {
                if !allClients.isEmpty {
                    List {
                        ForEach(filteredClient) {contact in
                            NavigationLink(destination: {
                                ClientEditView(client: contact)
                            }, label: {
                                Text(contact.fullName)
                            })
                            .swipeActions {
                                Button("Delete", role: .destructive) {
                                    modelContext.delete(contact)
                                    
                                    guard let _ = try? modelContext.save() else {
                                        print("😡 ERROR: Could not save after delete")
                                        return
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .searchable(text: $searchText)
                    
                    
                } else {
                    ContentUnavailableView("Add Clients", systemImage: "person.crop.circle.badge.questionmark")
                }
            }
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
            .navigationTitle("Clients")

        }
        .sheet(isPresented: $clientSheetIsPresented) {
            NewClientView()
        }
    }
}

#Preview {
    NavigationStack {
        ClientListView()
    }
}
