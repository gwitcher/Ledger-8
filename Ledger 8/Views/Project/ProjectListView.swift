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
    @State private var clientListIsPresented = false
    @State private var userInfoSheetIsPresented = false
    @State private var settingsSheetIsPresented = false
    @State private var sortSelection: Status = Status.open
    
    var body: some View {
        
        NavigationStack {
            Group {
                if !projects.isEmpty {
                    VStack {
                        FeeTotalsView(sortSelection: sortSelection)
                        
                        SortedProjectView(sortSelection: sortSelection)
                            .padding(4)
                        
                        Picker(selection: $sortSelection) {
                            ForEach(Status.allCases) { selection in
                                Text(selection.rawValue)
                            }
                        } label: {
                            Text("")
                        }
                        .padding(4)
                        .pickerStyle(.palette)
                        .animation(.easeIn, value: sortSelection)
                    }
                    .animation(.easeInOut(duration: 0.25), value: sortSelection)
                } else {
                    ContentUnavailableView("Enter your first project", systemImage: "music.note.list" )
                }
                
            }
            .navigationTitle("Project Ledger")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("", systemImage: "person.circle") {
                        clientListIsPresented.toggle()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("", systemImage: "plus") {
                        sheetIsPresented.toggle()
                    }
                }
                
                ToolbarItem(placement: .topBarLeading) {
                    Button("", systemImage: "ellipsis.circle") {
                        settingsSheetIsPresented.toggle()
                    }
                }
            }
            .sheet(isPresented: $sheetIsPresented) {
                ProjectDetailView(project: Project())
            }
            .sheet(isPresented: $clientListIsPresented) {
                ClientListView()
            }
            .sheet(isPresented: $settingsSheetIsPresented) {
                SettingsView()
            }
        }
    }
}

#Preview {
    ProjectListView()
}
