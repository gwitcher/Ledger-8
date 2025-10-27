//
//  EnhancedItemListView.swift
//  Ledger 8
//
//  Created by Assistant on 10/26/25.
//

import SwiftUI
import SwiftUIFontIcon
import SwiftData

// MARK: - Enhanced ItemListView

struct EnhancedItemListView: View {
    @Environment(\.modelContext) var modelContext
    let items: [Item]
    let onItemTap: ((Item) -> Void)?
    
    @State private var selectedItemForEditing: Item?
    
    var body: some View {
        VStack(spacing: 0) {
            if !items.isEmpty {
                // Total fee header
                HStack {
                    Spacer()
                    Text("Total: \(totalFee, format: .currency(code: "USD"))")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color(.systemGroupedBackground))
            }
            
            if items.isEmpty {
                EmptyItemsView()
            } else {
                List {
                    ForEach(items) { item in
                        EnhancedItemRowView(
                            item: item,
                            onTap: { 
                                selectedItemForEditing = item
                            }
                        )
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                    }
                    .onDelete(perform: deleteItems)
                }
                .listStyle(.plain)
                .sheet(item: $selectedItemForEditing) { item in
                    ItemEditView(item: item)
                }
            }
        }
    }
    
    private var totalFee: Double {
        items.reduce(0) { $0 + $1.fee }
    }
    
    private func deleteItems(offsets: IndexSet) {
        for index in offsets {
            let item = items[index]
            modelContext.delete(item)
        }
        
        do {
            try modelContext.save()
        } catch {
            print("😡 ERROR: Could not save after delete - \(error)")
        }
    }
}

// ENHANCED: Much better visual design with swipe actions
struct EnhancedItemRowView: View {
    let item: Item
    let onTap: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Left: Icon with colored background
            ZStack {
                Circle()
                    .fill(item.itemType.color.opacity(0.15))
                    .frame(width: 48, height: 48)
                
                Image(systemName: item.icon.systemName)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(item.itemType.color)
            }
            
            // Center: Item details
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name.isEmpty ? "Untitled Item" : item.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text(item.itemType.rawValue)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if !item.notes.isEmpty {
                    Text(item.notes)
                        .font(.caption)
                        .foregroundColor(Color(.tertiaryLabel))
                        .lineLimit(2)
                        .padding(.top, 2)
                }
            }
            
            Spacer()
            
            // Right: Fee
            Text(item.fee, format: .currency(code: "USD"))
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(backgroundColor)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .onTapGesture {
            onTap()
        }
    }
    
    private var backgroundColor: some View {
        // Modern Liquid Glass approach
        ZStack {
            // Base glass effect
            .regularMaterial
            
            // Subtle color accent
            LinearGradient(
                colors: [item.itemType.color.opacity(0.08), Color.clear],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }
}

// MARK: - Empty State View
struct EmptyItemsView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "music.note.list")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No Items Yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Add items to track fees and services for this project")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
    }
}

// MARK: - Extensions for ItemType Colors

extension ItemType {
    var color: Color {
        switch self {
        case .session, .overdub, .demo:
            return .blue
        case .rehearsal:
            return .orange
        case .concert, .tour:
            return .purple
        case .perDiem, .reimbursement:
            return .green
        case .arrangement, .score:
            return .indigo
        case .production:
            return .pink
        case .rental:
            return .brown
        case .lesson:
            return .teal
        case .other:
            return .gray
        }
    }
}

extension FontAwesomeCode {
    var systemName: String {
        switch self {
        case .music: return "music.note"
        case .ticket_alt: return "ticket"
        case .bus: return "bus"
        case .dollar_sign: return "dollarsign.circle"
        case .book_open: return "book"
        case .wave_square: return "waveform"
        case .clock: return "clock"
        case .receipt: return "receipt"
        case .graduation_cap: return "graduationcap"
        case .question: return "questionmark"
        default: return "questionmark"
        }
    }
}

// MARK: - Mock Data for Previews

extension Item {
    static var mockItems: [Item] {
        [
            Item(
                name: "Lead Guitar Recording",
                fee: 500.0,
                itemType: .session,
                notes: "3-hour recording session with multiple takes"
            ),
            Item(
                name: "String Arrangement",
                fee: 1200.0,
                itemType: .arrangement,
                notes: "Full orchestra arrangement for 5 songs"
            ),
            Item(
                name: "Concert Performance",
                fee: 750.0,
                itemType: .concert,
                notes: "Evening performance at the Blue Note"
            ),
            Item(
                name: "Travel Per Diem",
                fee: 75.0,
                itemType: .perDiem,
                notes: "Daily meal allowance for tour dates"
            ),
            Item(
                name: "Piano Lesson",
                fee: 65.0,
                itemType: .lesson,
                notes: "Advanced jazz piano techniques"
            ),
            Item(
                name: "Demo Recording",
                fee: 300.0,
                itemType: .demo,
                notes: ""
            )
        ]
    }
}

// MARK: - Preview

#Preview("Enhanced Item List - With Items") {
    NavigationStack {
        EnhancedItemListView(
            items: Item.mockItems,
            onItemTap: { item in
                print("Tapped item: \(item.name)")
            }
        )
        .navigationTitle("Project Items")
        .background(Color(.systemGroupedBackground))
        .toolbar {
            ToolbarItem(placement: .bottomBar) {
                Button("Add Item") {
                    print("Add item tapped")
                }
            }
        }
    }
    .modelContainer(for: [Item.self, Project.self], inMemory: true)
}

#Preview("Enhanced Item List - Empty State") {
    NavigationStack {
        EnhancedItemListView(
            items: [],
            onItemTap: nil
        )
        .navigationTitle("Project Items")
        .background(Color(.systemGroupedBackground))
    }
    .modelContainer(for: [Item.self, Project.self], inMemory: true)
}

#Preview("Single Item Row") {
    VStack(spacing: 16) {
        EnhancedItemRowView(
            item: Item.mockItems[0],
            onTap: { print("Tapped") }
        )
        
        EnhancedItemRowView(
            item: Item.mockItems[1],
            onTap: { print("Tapped") }
        )
        
        EnhancedItemRowView(
            item: Item.mockItems[2],
            onTap: { print("Tapped") }
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
