//
//  ProjectItemsView.swift
//  Ledger 8
//
//  Created by Assistant on 10/27/25.
//

import SwiftUI
import SwiftData

struct ProjectItemsView: View {
    @Environment(NavigationCoordinator.self) private var coordinator
    @Environment(\.modelContext) var modelContext
    
    let project: Project
    
    var body: some View {
        VStack(spacing: 0) {
            // Use the existing EnhancedItemListView
            EnhancedItemListView(
                items: project.items ?? [],
                onItemTap: { item in
                    // Navigate to item editor using coordinator
                    coordinator.navigateToItemEditor(for: project, item: item)
                }
            )
        }
        .navigationTitle(project.projectName.isEmpty ? "Untitled Project" : project.projectName)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Add Item", systemImage: "plus") {
                    // Use coordinator for consistent navigation
                    coordinator.navigateToItemEditor(for: project)
                }
            }
        }
        .sheet(isPresented: Binding(
            get: { coordinator.showingItemEditor && coordinator.selectedProject?.id == project.id },
            set: { _ in coordinator.showingItemEditor = false }
        )) {
            AddItemView(project: project)
        }
    }
}

// MARK: - Add Item View
struct AddItemView: View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss
    
    let project: Project
    
    @State private var name = ""
    @State private var itemType = ItemType.session
    @State private var fee = 0.0
    @State private var notes = ""
    
    @FocusState private var focusField: ItemField?
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Item Details") {
                    TextField("Item Name", text: $name)
                        .textContentType(.name)
                        .submitLabel(.next)
                        .focused($focusField, equals: .itemName)
                        .onSubmit {
                            focusField = .fee
                        }
                    
                    Picker("Type", selection: $itemType) {
                        ForEach(ItemType.allCases, id: \.self) { type in
                            Text(type.rawValue)
                                .tag(type)
                        }
                    }
                    
                    HStack {
                        Text("Fee")
                        Spacer()
                        TextField("$0.00", value: $fee, format: .currency(code: "USD"))
                            .keyboardType(.decimalPad)
                            .focused($focusField, equals: .fee)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                Section("Notes") {
                    TextField("Additional notes...", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("New Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add") {
                        addItem()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
    
    private func addItem() {
        let newItem = Item(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            fee: fee,
            itemType: itemType,
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        
        // Add to project's items
        if project.items == nil {
            project.items = []
        }
        project.items?.append(newItem)
        
        // Set the relationship
        newItem.project = project
        
        // Insert into model context
        modelContext.insert(newItem)
        
        // Flag project invoice for update
        project.flagInvoiceForUpdate()
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Error saving new item: \(error)")
        }
    }
}

// ItemField enum is already defined in Enums.swift

// MARK: - Preview
#Preview("Project Items View") {
    NavigationStack {
        ProjectItemsView(project: {
            let project = Project(projectName: "Sample Project")
            project.items = Item.mockItems
            return project
        }())
    }
    .environment(NavigationCoordinator())
    .modelContainer(for: [Item.self, Project.self], inMemory: true)
}

#Preview("Add Item View") {
    AddItemView(project: Project(projectName: "Sample Project"))
        .modelContainer(for: [Item.self, Project.self], inMemory: true)
}