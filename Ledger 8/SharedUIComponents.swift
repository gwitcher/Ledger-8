//
//  SharedUIComponents.swift
//  Ledger 8
//
//  Created by Assistant on 10/27/25.
//

import SwiftUI
import SwiftData

// MARK: - Button Style Extensions for Semantic Hierarchy
extension ButtonStyle where Self == LedgerButtonStyle {
    static var primary: LedgerButtonStyle { LedgerButtonStyle(priority: .primary) }
    static var secondary: LedgerButtonStyle { LedgerButtonStyle(priority: .secondary) }
    static var destructive: LedgerButtonStyle { LedgerButtonStyle(priority: .destructive) }
}

struct LedgerButtonStyle: ButtonStyle {
    enum Priority {
        case primary, secondary, destructive
        
        var tintColor: Color {
            switch self {
            case .primary: return .accentColor
            case .secondary: return .primary
            case .destructive: return .red
            }
        }
    }
    
    let priority: Priority
    
    func makeBody(configuration: Configuration) -> some View {
        Group {
            if priority == .primary {
                configuration.label
                    .buttonStyle(.borderedProminent)
            } else {
                configuration.label
                    .buttonStyle(.bordered)
            }
        }
        .tint(priority.tintColor)
        .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Shared Views
struct PaywallView: View {
    let trigger: PaywallTrigger
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Premium Features")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Unlock premium features")
                .font(.title2)
                .foregroundStyle(.secondary)
            
            Button("Subscribe") {
                // Handle subscription
                dismiss()
            }
            .buttonStyle(LedgerButtonStyle(priority: .primary))
            
            Button("Cancel") {
                dismiss()
            }
            .buttonStyle(LedgerButtonStyle(priority: .secondary))
        }
        .padding()
    }
}

// MARK: - Placeholder Views (replace these with your actual views)





//struct ProjectItemsView: View {
//    let project: Project
//    @Environment(NavigationCoordinator.self) private var coordinator
//    
//    var body: some View {
//        List {
//            ForEach(project.items) { item in
//                VStack(alignment: .leading) {
//                    Text(item.name ?? "Unnamed Item")
//                        .font(.headline)
//                    if let details = item.details, !details.isEmpty {
//                        Text(details)
//                            .font(.caption)
//                            .foregroundStyle(.secondary)
//                    }
//                }
//            }
//        }
//        .navigationTitle("Project Items")
//        .navigationBarTitleDisplayMode(.inline)
//        .toolbar {
//            ToolbarItem(placement: .topBarTrailing) {
//                Button("Add Item") {
//                    coordinator.navigateToItemEditor(for: project)
//                }
//                .buttonStyle(LedgerButtonStyle(priority: .primary))
//            }
//        }
//    }
//}
//
//struct ItemEditorView: View {
//    let project: Project
//    let item: Item?
//    @Environment(\.dismiss) private var dismiss
//    
//    var body: some View {
//        Form {
//            Section("Item Details") {
//                TextField("Item Name", text: .constant(""))
//                TextField("Details", text: .constant(""), axis: .vertical)
//            }
//        }
//        .navigationTitle(item == nil ? "New Item" : "Edit Item")
//        .navigationBarTitleDisplayMode(.inline)
//        .toolbar {
//            ToolbarItem(placement: .topBarLeading) {
//                Button("Cancel") {
//                    dismiss()
//                }
//                .buttonStyle(LedgerButtonStyle(priority: .secondary))
//            }
//            
//            ToolbarItem(placement: .topBarTrailing) {
//                Button("Save") {
//                    // Save logic would go here
//                    dismiss()
//                }
//            }
//        }
//    }
//}
//
//struct SettingsView: View {
//    @Environment(\.dismiss) private var dismiss
//    
//    var body: some View {
//        Form {
//            Section("Settings") {
//                Text("Settings content goes here")
//            }
//        }
//        .navigationTitle("Settings")
//        .toolbar {
//            ToolbarItem(placement: .topBarTrailing) {
//                Button("Done") {
//                    dismiss()
//                }
//                .buttonStyle(LedgerButtonStyle(priority: .primary))
//            }
//        }
//    }
//}
//
//struct AnalyticsDashboardView: View {
//    @Environment(\.dismiss) private var dismiss
//    
//    var body: some View {
//        Form {
//            Section("Analytics") {
//                Text("Analytics dashboard goes here")
//            }
//        }
//        .navigationTitle("Analytics")
//        .toolbar {
//            ToolbarItem(placement: .topBarTrailing) {
//                Button("Done") {
//                    dismiss()
//                }
//                .buttonStyle(LedgerButtonStyle(priority: .primary))
//            }
//        }
//    }
//}
//
//struct ClientListView: View {
//    @Environment(\.dismiss) private var dismiss
//    
//    var body: some View {
//        Form {
//            Section("Clients") {
//                Text("Client list goes here")
//            }
//        }
//        .navigationTitle("Clients")
//        .toolbar {
//            ToolbarItem(placement: .topBarTrailing) {
//                Button("Done") {
//                    dismiss()
//                }
//                .buttonStyle(LedgerButtonStyle(priority: .primary))
//            }
//        }
//    }
//}
//
//// MARK: - Simple Project Row View (replace with your actual implementation)
//struct ProjectRowView: View {
//    let project: Project
//    
//    var body: some View {
//        VStack(alignment: .leading, spacing: 4) {
//            Text(project.projectName ?? "Untitled Project")
//                .font(.headline)
//            
//            if let startDate = project.startDate {
//                Text(startDate.formatted(date: .abbreviated, time: .omitted))
//                    .font(.caption)
//                    .foregroundStyle(.secondary)
//            }
//        }
//        .padding(.vertical, 2)
//    }
//}