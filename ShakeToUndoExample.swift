//
//  ShakeToUndoExample.swift
//  Ledger 8
//
//  Created by Gabe Witcher on [Date]
//

import SwiftUI
import SwiftData

// MARK: - Example: Client List with Shake-to-Undo
struct ClientListViewWithUndo: View {
    @Environment(\.modelContext) var modelContext
    @EnvironmentObject var undoManager: AppUndoManager
    @Query var clients: [Client]
    
    var body: some View {
        NavigationView {
            List {
                ForEach(clients) { client in
                    ClientRowView(client: client)
                }
                .onDelete(perform: deleteClients)
            }
            .navigationTitle("Clients")
            .toolbar {
                if undoManager.canUndo {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                            undoManager.performUndo(in: modelContext)
                        }) {
                            HStack {
                                Image(systemName: "arrow.uturn.backward")
                                Text("Undo")
                            }
                        }
                        .foregroundColor(.blue)
                    }
                }
            }
        }
    }
    
    private func deleteClients(offsets: IndexSet) {
        for index in offsets {
            let client = clients[index]
            // Register for undo before deleting
            undoManager.registerDelete(client, context: modelContext)
            modelContext.delete(client)
        }
        // Save context after all deletions
        try? modelContext.save()
    }
}

struct ClientRowView: View {
    let client: Client
    @Environment(\.modelContext) var modelContext
    @EnvironmentObject var undoManager: AppUndoManager
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(client.fullName)
                    .font(.headline)
                if !client.email.isEmpty {
                    Text(client.email)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Manual delete button
            Button(action: {
                undoManager.registerDelete(client, context: modelContext)
                modelContext.delete(client)
                try? modelContext.save()
            }) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Example: Item List with Shake-to-Undo
struct ItemListViewWithUndo: View {
    @Environment(\.modelContext) var modelContext
    @EnvironmentObject var undoManager: AppUndoManager
    
    let project: Project
    
    var body: some View {
        List {
            if let items = project.items {
                ForEach(items) { item in
                    ItemRowView(item: item)
                }
                .onDelete(perform: deleteItems)
            }
        }
        .navigationTitle("Items")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func deleteItems(offsets: IndexSet) {
        guard let items = project.items else { return }
        
        for index in offsets {
            let item = items[index]
            undoManager.registerDelete(item, context: modelContext)
            modelContext.delete(item)
        }
        try? modelContext.save()
    }
}

struct ItemRowView: View {
    let item: Item
    @Environment(\.modelContext) var modelContext
    @EnvironmentObject var undoManager: AppUndoManager
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(item.name.isEmpty ? "Unnamed Item" : item.name)
                    .font(.headline)
                Text("$\(item.fee, specifier: "%.2f")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: {
                undoManager.registerDelete(item, context: modelContext)
                modelContext.delete(item)
                try? modelContext.save()
            }) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Usage in Your Main View
struct MainViewWithShakeToUndo: View {
    @Environment(\.modelContext) var modelContext
    @StateObject private var undoManager = AppUndoManager()
    
    var body: some View {
        TabView {
            ContentView()
                .tabItem {
                    Label("Projects", systemImage: "folder")
                }
            
            ClientListViewWithUndo()
                .tabItem {
                    Label("Clients", systemImage: "person.2")
                }
        }
        .environmentObject(undoManager)
        .onShake {
            if undoManager.canUndo {
                undoManager.performUndo(in: modelContext)
            }
        }
        .alert("Undo Successful", isPresented: $undoManager.showingUndoAlert) {
            Button("OK") { }
        } message: {
            if let description = undoManager.lastActionDescription {
                Text("Undid: \(description)")
            } else {
                Text("The last delete action has been undone.")
            }
        }
    }
}