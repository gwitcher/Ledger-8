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
    
    @Query var allClients: [Client]
    
    var sortedClients: [Client] {
        allClients.sorted { client1, client2 in
            // Function to get the sort key for a client
            func getSortKey(for client: Client) -> String {
                if !client.lastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    return client.lastName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                } else if !client.firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    return client.firstName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                } else if !client.company.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    return client.company.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                } else {
                    return "" // Empty string sorts last
                }
            }
            
            return getSortKey(for: client1) < getSortKey(for: client2)
        }
    }
    

    @State private var searchText = ""
    @State private var clientSheetIsPresented = false
    
    var filteredClient: [Client] {
        if searchText.isEmpty {
            sortedClients
        } else {
            sortedClients.filter {
                $0.firstName.localizedStandardContains(searchText) ||
                $0.lastName.localizedStandardContains(searchText) ||
                $0.company.localizedStandardContains(searchText)
            }
        }
    }
    
    var groupedClients: [String: [Client]] {
        Dictionary(grouping: filteredClient) { client in
            // Get the first letter for grouping based on the same logic as sorting
            func getFirstLetter(for client: Client) -> String {
                if !client.lastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    return String(client.lastName.trimmingCharacters(in: .whitespacesAndNewlines).prefix(1)).uppercased()
                } else if !client.firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    return String(client.firstName.trimmingCharacters(in: .whitespacesAndNewlines).prefix(1)).uppercased()
                } else if !client.company.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    return String(client.company.trimmingCharacters(in: .whitespacesAndNewlines).prefix(1)).uppercased()
                } else {
                    return "#" // For clients with no name/company
                }
            }
            
            let letter = getFirstLetter(for: client)
            // Handle non-alphabetic characters
            return letter.rangeOfCharacter(from: CharacterSet.letters) != nil ? letter : "#"
        }
    }
    
    var sortedSectionKeys: [String] {
        groupedClients.keys.sorted { key1, key2 in
            // Put # section at the end
            if key1 == "#" && key2 != "#" {
                return false
            } else if key1 != "#" && key2 == "#" {
                return true
            } else {
                return key1 < key2
            }
        }
    }
    
    var body: some View {
        
        NavigationStack {
            Group {
                if !sortedClients.isEmpty {
                    List {
                        ForEach(sortedSectionKeys, id: \.self) { sectionKey in
                            Section(header: Text(sectionKey).font(.headline).foregroundColor(.primary)) {
                                ForEach(groupedClients[sectionKey] ?? []) { contact in
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
