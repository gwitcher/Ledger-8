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
    
    //@Query var projects: [Project]
    
    let projects = [Project(projectName: "Butthead", artist: "Beavis", startDate: Date(), endDate: Date(), status: .open, mediaType: .tv, notes: "", delivered: false, paid: false, dateOpened: Date(), dateDelivered: Date(), dateClosed: Date(), endDateSelected: false, items: [Item(name: "Song 1", fee: 200, itemType: .rental, notes: "", project: nil)])]
    
    @State private var projectSheetIsPresented = false
    @State private var clientListIsPresented = false
    @State private var userInfoSheetIsPresented = false
    @State private var settingsSheetIsPresented = false
    @State private var sortSelection: Status = Status.open
    @State var selectedIndex: Int?
    
    init() {
        // Large Navigation Title
        UINavigationBar.appearance().largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        // Inline Navigation Title
        UINavigationBar.appearance().titleTextAttributes = [.foregroundColor: UIColor.purple]
    }
    
    var body: some View {
        
        NavigationStack {
            ZStack{
                RadialGradient(
                    gradient: Gradient(colors: [Color.stormyMorning4, Color.stormyMorning1]),
                    center: .top,
                    startRadius: 1,
                    endRadius: UIScreen.main.bounds.height)
                .ignoresSafeArea()
                
                
                Group {
                    if !projects.isEmpty {
                        VStack {
                            FeeTotalsView(sortSelection: sortSelection)
                            
                            SortedProjectView(sortSelection: sortSelection)
                                .padding(4)
                            
                            CustomPickerView(sortSelection: $sortSelection)
                        }
                    } else {
                        ContentUnavailableView("Enter your first project", systemImage: "music.note.list" )
                        
                    }
                    
                }
            }
            .navigationTitle("Project Ledger")
            .foregroundStyle(.white)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        clientListIsPresented.toggle()
                    } label: {
                        Image(systemName: "person.circle")
                            .foregroundStyle(.white)
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        projectSheetIsPresented.toggle()
                    } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(.white)
                    }
                }
                
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        settingsSheetIsPresented.toggle()
                    } label: {
                        Image(systemName: "gear")
                            .foregroundStyle(.white)
                    }
                }
            }
            .fullScreenCover(isPresented: $projectSheetIsPresented, content: {
                ProjectDetailView(project: Project())
            })
            
//            .sheet(isPresented: $projectSheetIsPresented) {
//                ProjectDetailView(project: Project())
//            }
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
