//
//  ClientSelectView.swift
//  Ledger 8
//
//  Created by Gabe Witcher on 4/24/25.
//  Refactored to MVVM Architecture
//

import SwiftUI
import SwiftData

struct ClientSelectView: View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss
    
    @Binding var selectedClient: Client?
    @State private var viewModel = ClientSelectViewModel()
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    loadingView
                } else if viewModel.hasClients {
                    clientListView
                } else {
                    emptyStateView
                }
            }
            .searchable(
                text: viewModel.searchTextBinding(),
                prompt: "Search clients..."
            )
            .searchSuggestions {
                searchSuggestionsView
            }
            .navigationTitle("Select Client")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                toolbarContent
            }
            .sheet(isPresented: $viewModel.showingNewClientSheet) {
                NewClientView()
                    .onDisappear {
                        viewModel.hideNewClientSheet()
                    }
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK") { }
            } message: {
                Text(viewModel.errorMessage)
            }
            .onAppear {
                viewModel.setModelContext(modelContext)
            }
            .onChange(of: viewModel.selectedClient) { _, newClient in
                selectedClient = newClient
                if newClient != nil {
                    dismiss()
                }
            }
        }
    }
    
    // MARK: - View Components
    
    @ViewBuilder
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Loading clients...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    @ViewBuilder
    private var clientListView: some View {
        List {
            if viewModel.isSearching {
                searchResultsHeader
            }
            
            ForEach(viewModel.groupedClients, id: \.key) { group in
                Section {
                    ForEach(group.value) { client in
                        ClientRowView(
                            client: client,
                            searchText: viewModel.searchText
                        ) {
                            viewModel.selectClient(client)
                        }
                    }
                } header: {
                    Text(group.key)
                        .font(.headline)
                        .foregroundStyle(.primary)
                }
            }
        }
        .listStyle(.plain)
    }
    
    @ViewBuilder
    private var searchResultsHeader: some View {
        if viewModel.searchResultsCount > 0 {
            Section {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    Text("\(viewModel.searchResultsCount) result\(viewModel.searchResultsCount == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("Clear") {
                        viewModel.clearSearch()
                    }
                    .font(.caption)
                }
                .padding(.vertical, 4)
            }
        }
    }
    
    @ViewBuilder
    private var searchSuggestionsView: some View {
        ForEach(viewModel.searchSuggestions, id: \.self) { suggestion in
            Button {
                viewModel.updateSearch(suggestion)
            } label: {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    Text(suggestion)
                        .foregroundStyle(.primary)
                    Spacer()
                }
            }
        }
    }
    
    @ViewBuilder
    private var emptyStateView: some View {
        ContentUnavailableView {
            Label("No Clients", systemImage: "person.crop.circle.badge.questionmark")
        } description: {
            Text("Add your first client to get started")
        } actions: {
            Button("Add Client") {
                viewModel.showNewClientSheet()
            }
            .buttonStyle(.borderedProminent)
        }
    }
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button("Cancel") {
                dismiss()
            }
        }
        
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                viewModel.showNewClientSheet()
            } label: {
                Image(systemName: "plus")
            }
            .accessibilityLabel("Add new client")
        }
    }
}

// MARK: - Supporting Views

struct ClientRowView: View {
    let client: Client
    let searchText: String
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 4) {
                // Main name with search highlighting
                Text(highlightedText(client.fullName, searchText: searchText))
                    .font(.body)
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // Company and email as secondary info
                if !client.company.isEmpty || !client.email.isEmpty {
                    HStack {
                        if !client.company.isEmpty {
                            Text(highlightedText(client.company, searchText: searchText))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        if !client.company.isEmpty && !client.email.isEmpty {
                            Text("•")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                        
                        if !client.email.isEmpty {
                            Text(client.email)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                    }
                }
                
                // Project count if available
                if let projectCount = client.project?.count, projectCount > 0 {
                    HStack {
                        Image(systemName: "folder")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                        Text("\(projectCount) project\(projectCount == 1 ? "" : "s")")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                        Spacer()
                    }
                }
            }
            .padding(.vertical, 2)
        }
        .buttonStyle(.plain)
    }
    
    /// Highlights search text within the given string
    private func highlightedText(_ text: String, searchText: String) -> AttributedString {
        guard !searchText.isEmpty else {
            return AttributedString(text)
        }
        
        var attributed = AttributedString(text)
        
        if let range = attributed.range(of: searchText, options: [.caseInsensitive, .diacriticInsensitive]) {
            attributed[range].backgroundColor = .yellow.opacity(0.3)
            attributed[range].foregroundColor = .primary
        }
        
        return attributed
    }
}

// MARK: - Preview
#Preview {
    @Previewable @State var selectedClient: Client? = nil
    
    return ClientSelectView(selectedClient: $selectedClient)
        .modelContainer(for: [Client.self, Project.self], inMemory: true)
}

