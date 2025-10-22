////
////  ExampleListView.swift
////  Ledger 8
////
////  Created by Gabe Witcher on [Date]
////
//
//import SwiftUI
//import SwiftData
//
//struct ExampleProjectListView: View {
//    @Environment(\.modelContext) var modelContext
//    @EnvironmentObject var undoManager: AppUndoManager
//    @Query var projects: [Project]
//    
//    var body: some View {
//        List {
//            ForEach(projects) { project in
//                ProjectRowView(project: project)
//            }
//            .onDelete(perform: deleteProjects)
//        }
//        .toolbar {
//            ToolbarItem(placement: .navigationBarTrailing) {
//                if undoManager.canUndo {
//                    Button("Undo Available") {
//                        // Optional: Show what can be undone
//                    }
//                    .foregroundColor(.blue)
//                    .font(.caption)
//                }
//            }
//        }
//    }
//    
//    private func deleteProjects(offsets: IndexSet) {
//        for index in offsets {
//            let project = projects[index]
//            // Use the helper function for undo-aware deletion
//            deleteWithUndo(project, from: modelContext, undoManager: undoManager)
//        }
//    }
//}
//
//struct ProjectRowView: View {
//    let project: Project
//    @Environment(\.modelContext) var modelContext
//    @EnvironmentObject var undoManager: AppUndoManager
//    
//    var body: some View {
//        HStack {
//            VStack(alignment: .leading) {
//                Text(project.name ?? "Unnamed Project")
//                    .font(.headline)
//                Text("Start: \(project.startDate, format: .dateTime)")
//                    .font(.caption)
//                    .foregroundColor(.secondary)
//            }
//            
//            Spacer()
//            
//            // Example: Delete button with undo support
//            Button(action: {
//                deleteWithUndo(project, from: modelContext, undoManager: undoManager)
//            }) {
//                Image(systemName: "trash")
//                    .foregroundColor(.red)
//            }
//        }
//        .padding(.vertical, 4)
//    }
//}
