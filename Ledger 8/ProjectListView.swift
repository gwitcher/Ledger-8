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
                        Text(project.client)
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
