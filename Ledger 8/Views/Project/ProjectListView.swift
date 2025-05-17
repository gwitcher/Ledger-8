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
    
    
    @State private var projectSheetIsPresented = false
    @State private var clientListIsPresented = false
    @State private var userInfoSheetIsPresented = false
    @State private var settingsSheetIsPresented = false
    @State private var sortSelection: Status = Status.open
    
    
    init() {
        // Large Navigation Title
        UINavigationBar.appearance().largeTitleTextAttributes = [.foregroundColor: UIColor.black]
        // Inline Navigation Title
        UINavigationBar.appearance().titleTextAttributes = [.foregroundColor: UIColor.black]
    }
    
    var body: some View {
        
        NavigationStack {
            ZStack{
                RadialGradient(
                    gradient: Gradient(colors: [Color.quiteClear1, Color.quiteClear4.opacity(0.2)]),
                    center: .top,
                    startRadius: 100,
                    endRadius: UIScreen.main.bounds.height)
                .ignoresSafeArea()
                
                
                Group {
                    if !projects.isEmpty {
                        VStack {
                            FeeTotalsView(sortSelection: sortSelection)
                            
                            SortedProjectView(sortSelection: sortSelection)
                                .padding(4)
                            
                            //CustomPickerView(sortSelection: $sortSelection)
                            
                            Picker("", selection: $sortSelection) {
                                ForEach(Status.allCases) {status in
                                    Text(status.rawValue)}
                            }
                            .pickerStyle(.palette)
                            .padding()
                        }
                    } else {
                        ContentUnavailableView("Enter your first project", systemImage: "music.note.list" )
                        
                    }
                    
                }
            }
            .navigationTitle("Project Ledger")
            .foregroundStyle(.black)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        clientListIsPresented.toggle()
                    } label: {
                        Image(systemName: "person.circle")
                            //.foregroundStyle(.blue)
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        projectSheetIsPresented.toggle()
                    } label: {
                        Image(systemName: "plus")
                            //.foregroundStyle(.blue)
                    }
                }
                
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        settingsSheetIsPresented.toggle()
                    } label: {
                        Image(systemName: "gear")
                            //.foregroundStyle(.gray)
                    }
                }
            }
            .fullScreenCover(isPresented: $projectSheetIsPresented, content: {
                ProjectDetailView(project: Project())
            })
            
            .sheet(isPresented: $clientListIsPresented) {
                ClientListView()
            }
            .fullScreenCover(isPresented: $settingsSheetIsPresented, content: {
                SettingsView()
            })
            
        }
    }
}

#Preview {
    ProjectListView()
}
