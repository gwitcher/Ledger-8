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
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var undoManager: AppUndoManager
    
    @Query(sort: \Project.startDate) var projects: [Project]
    
    @State private var projectSheetIsPresented = false
    @State private var clientListIsPresented = false
    @State private var userInfoSheetIsPresented = false
    @State private var settingsSheetIsPresented = false
    @State private var chartSheetIsPresented = false
    @State private var sortSelection: Status = Status.open
    @State private var searchText = ""
    @State private var isSearching = false
    @FocusState private var searchFieldFocused: Bool
    
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
                        VStack(spacing: 0) {
                            FeeTotalsView(sortSelection: sortSelection)
                            
                            SortedProjectView(
                                sortSelection: sortSelection,
                                searchText: searchText
                            )
                            .padding(4)
                            
                            Picker("", selection: $sortSelection) {
                                ForEach(Status.allCases) {status in
                                    Text(status.rawValue)
                                }
                            }
                            .pickerStyle(.palette)
                            .padding()
                        }
                    } else {
                        ContentUnavailableView("Enter your first project", systemImage: "music.note.list")
                    }
                }
            }
            .navigationTitle(isSearching ? "" : "Project Ledger")  // Hide title when searching
            .navigationBarTitleDisplayMode(.automatic)  // Back to large
            .toolbar {
                // Custom search bar in the toolbar
                ToolbarItem(placement: .topBarTrailing) {
                    if isSearching {
                        HStack(spacing: 8) {
                            HStack(spacing: 8) {
                                Image(systemName: "magnifyingglass")
                                    .foregroundStyle(.secondary)
                                    .font(.system(size: 16))
                                
                                TextField("Search projects, artists, or clients", text: $searchText)
                                    .focused($searchFieldFocused)
                                    .autocorrectionDisabled()
                                    .textInputAutocapitalization(.never)
                                    .textFieldStyle(.plain)
                                
                                if !searchText.isEmpty {
                                    Button {
                                        searchText = ""
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            //.background(Color(.systemGray5))
                            .cornerRadius(10)
                            
                            Button("Cancel") {
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    isSearching = false
                                    searchText = ""
                                    searchFieldFocused = false
                                }
                            }
                            .foregroundStyle(.blue)
                        }
                        .transition(.opacity)
                    }
                }
                
                // Top leading - settings and charts (hidden when searching)
                if !isSearching {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            settingsSheetIsPresented.toggle()
                        } label: {
                            Image(systemName: "gear")
                                .foregroundStyle(.primary)
                        }
                    }
                    
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            chartSheetIsPresented.toggle()
                        } label: {
                            Image(systemName: "chart.bar.xaxis")
                                .foregroundStyle(.primary)
                        }
                    }
                }
                
                // Top trailing - search, plus, and person icons (hidden when searching)
                if !isSearching {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                isSearching = true
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                searchFieldFocused = true
                            }
                        } label: {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(.primary)
                        }
                    }
                    
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            clientListIsPresented.toggle()
                        } label: {
                            Image(systemName: "person.circle")
                                .foregroundStyle(.primary)
                        }
                    }
                    
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            projectSheetIsPresented.toggle()
                        } label: {
                            Image(systemName: "plus")
                                .foregroundStyle(.primary)
                        }
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
            .fullScreenCover(isPresented: $chartSheetIsPresented, content: {
                AnalyticsDashboardView()
            })
        }
    }
}

#Preview {
    ProjectListView()
}
