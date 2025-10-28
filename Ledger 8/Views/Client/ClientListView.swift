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
    @State private var viewModel = ClientListViewModel()
    
    // Computed properties using ViewModel
    private var sortedClients: [Client] {
        viewModel.sortedClients(from: allClients)
    }
    
    private var filteredClients: [Client] {
        viewModel.filteredClients(from: sortedClients)
    }
    
    private var groupedClients: [String: [Client]] {
        viewModel.groupedClients(from: filteredClients)
    }
    
    private var sortedSectionKeys: [String] {
        viewModel.sortedSectionKeys(from: groupedClients)
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
                                            viewModel.deleteClient(contact, from: modelContext)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .searchable(text: $viewModel.searchText)
                    
                    
                } else {
                    ContentUnavailableView("Add Clients", systemImage: "person.crop.circle.badge.questionmark")
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("", systemImage: "plus") {
                        viewModel.showNewClientSheet()
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
        .sheet(isPresented: $viewModel.clientSheetIsPresented) {
            NewClientView()
        }
    }
}

#Preview {
    NavigationStack {
        ClientListView()
    }
}
