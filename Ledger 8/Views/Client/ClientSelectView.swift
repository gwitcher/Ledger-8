//
//  ClientSelectView.swift
//  Ledger 8
//
//  Created by Gabe Witcher on 4/24/25.
//

import SwiftUI
import SwiftData

struct ClientSelectView: View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss
    
    
    
    @Query(sort: \Client.firstName) var allClients: [Client]
    
    @Binding var selectedClient:  Client?
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
    
    var groupedClients: [(key: String, value: [Client])] {
        let grouped = Dictionary(grouping: filteredClient) { client in
            if !client.lastName.isEmpty {
                return String(client.lastName.prefix(1)).uppercased()
            } else if !client.firstName.isEmpty {
                return String(client.firstName.prefix(1)).uppercased()
            } else if !client.company.isEmpty {
                return String(client.company.prefix(1)).uppercased()
            } else {
                return "#"
            }
        }
        return grouped.sorted { $0.key < $1.key }
    }
    
    var body: some View {
        NavigationStack {
            
            Group {
                if !allClients.isEmpty {
                    List {
                        ForEach(groupedClients, id: \.key) { group in
                            Section(header: Text(group.key).font(.headline)) {
                                ForEach(group.value) { client in
                                    Text(client.fullName)
                                        .onTapGesture {
                                            selectedClient = client
                                            print("Client Select View Selected Client on tap: \(selectedClient?.fullName ?? "NIL")")
                                            dismiss()
                                        }
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .searchable(text: $searchText)
                } else {
                    ContentUnavailableView("Add Client", systemImage: "person.crop.circle.badge.questionmark")
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("", systemImage: "plus") {
                        clientSheetIsPresented.toggle()
                    }
                }
            }
        }
        .sheet(isPresented: $clientSheetIsPresented) {
            NewClientView()
        }
    }
    
}

//#Preview {
//    ClientSelectView(project: Project())
//}

