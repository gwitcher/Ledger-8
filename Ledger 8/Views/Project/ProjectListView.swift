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
    
    @Query var projects: [Project]
    
    @State private var sheetIsPresented = false
    @State private var sortSelection: Status = Status.open
    
    var body: some View {
        
        NavigationStack {
            Group {
                if !projects.isEmpty {
                    VStack {
                        PrimaryTotalsView(sortSelection: sortSelection)
                        SortedProjectView(sortSelection: sortSelection)
                    }
                } else {
                    ContentUnavailableView("Enter your first project", systemImage: "music.note.list" )
                }
                
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("", systemImage: "plus") {
                        sheetIsPresented.toggle()
                    }
                }
                
                if !projects.isEmpty {
                    ToolbarItem(placement: .bottomBar) {
                        Picker(selection: $sortSelection) {
                            ForEach(Status.allCases) { selection in
                                Text(selection.rawValue)
                            }
                        } label: {
                            Text("")
                        }
                        .pickerStyle(.palette)
                        .animation(.easeIn, value: sortSelection)
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
    ProjectListView()
}
