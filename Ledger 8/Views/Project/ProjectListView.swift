//
//  ProjectListView.swift
//  Ledger 8
//
//  Created by Gabe Witcher on 4/15/25.
//

import SwiftUI
import SwiftData

struct ProjectListView: View {
    @Environment(\.modelContext) var modelContext
    
    var projects: [Project]
    
    @State private var sheetIsPresented = false
    
    var body: some View {
        
        NavigationStack {
            List {
                ForEach(projects) { project in
                    NavigationLink {
                        ProjectDetailView(project: project)
                    } label: {
                        ProjectView(project: project)
                    }
                    .swipeActions {
                        Button("Delete", role: .destructive) {
                            modelContext.delete(project)
                            
                            guard let _ = try? modelContext.save() else {
                                print("😡 ERROR: Could not save after delete")
                                return
                            }
                        }
                    }

                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("", systemImage: "plus") {
                        sheetIsPresented.toggle()
                    }
                }
            }
            .sheet(isPresented: $sheetIsPresented) {
                ProjectDetailView(project: Project())
            }
        }
        .navigationTitle("Projects")
        
        
    }
}

#Preview {
    ProjectListView(projects: [Project]())
}
