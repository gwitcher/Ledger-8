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
    
    
    
    @Query(sort: \Client.name) var allClients: [Client]
    
    @Binding var selectedClient:  Client?
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
            
            Group {
                if !allClients.isEmpty {
                    List {
                        ForEach(filteredClient) {client in
                            Text(client.name)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedClient = client
                                    print("Client Select View Selected Client on tap: \(selectedClient?.name ?? "NIL")")
                                    dismiss()
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
            ClientDetailView(client: Client())
    }
}

}

//#Preview {
//    ClientSelectView(project: Project())
//}
