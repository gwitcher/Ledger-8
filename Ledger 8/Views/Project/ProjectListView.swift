//
//  ProjectListView.swift
//  Ledger 8
//
//  Created by Gabe Witcher on 4/15/25.
//

import SwiftUI
import SwiftData

struct ProjectListView: View {
    // MARK: - Environment Properties
    @Environment(\.modelContext) var modelContext
    @Environment(\.colorScheme) var colorScheme
    
    // MARK: - SwiftData Query
    /// SwiftData query to fetch all projects sorted by start date
    @Query(sort: \Project.startDate) var projects: [Project]
    
    // MARK: - ViewModel
    /// The ViewModel that handles all business logic and state management
    @State private var viewModel = ProjectListViewModel()
    
    // MARK: - Focus State
    /// FocusState remains in the View since it's UI-specific and needs to work with SwiftUI's focus system
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
                    if viewModel.hasProjects(projects) {
                        VStack(spacing: 0) {
                            FeeTotalsView(sortSelection: viewModel.sortSelection)
                            
                            SortedProjectView(
                                sortSelection: viewModel.sortSelection,
                                searchText: viewModel.searchText
                            )
                            .padding(4)
                            
                            Picker("", selection: $viewModel.sortSelection) {
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
            .navigationTitle(viewModel.navigationTitle)  // Using ViewModel computed property
            .navigationBarTitleDisplayMode(.automatic)  // Back to large
            .toolbar {
                // Custom search bar in the toolbar
                ToolbarItem(placement: .topBarTrailing) {
                    if viewModel.isSearching {
                        HStack(spacing: 8) {
                            HStack(spacing: 8) {
                                Image(systemName: "magnifyingglass")
                                    .foregroundStyle(.secondary)
                                    .font(.system(size: 16))
                                
                                TextField("Search projects, artists, or clients", text: $viewModel.searchText)
                                    .focused($searchFieldFocused)
                                    .autocorrectionDisabled()
                                    .textInputAutocapitalization(.never)
                                    .textFieldStyle(.plain)
                                
                                if !viewModel.searchText.isEmpty {
                                    Button {
                                        viewModel.clearSearchText()
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .cornerRadius(10)
                            
                            Button("Cancel") {
                                viewModel.cancelSearching()
                            }
                            .foregroundStyle(.blue)
                        }
                        .transition(.opacity)
                    }
                }
                
                // Top leading - settings and charts (hidden when searching)
                if !viewModel.isSearching {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            viewModel.showSettings()
                        } label: {
                            Image(systemName: "gear")
                                .foregroundStyle(.primary)
                        }
                    }
                    
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            viewModel.showChart()
                        } label: {
                            Image(systemName: "chart.bar.xaxis")
                                .foregroundStyle(.primary)
                        }
                    }
                }
                
                // Top trailing - search, plus, and person icons (hidden when searching)
                if !viewModel.isSearching {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            viewModel.startSearching()
                        } label: {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(.primary)
                        }
                    }
                    
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            viewModel.showClientList()
                        } label: {
                            Image(systemName: "person.circle")
                                .foregroundStyle(.primary)
                        }
                    }
                    
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            viewModel.showProjectSheet()
                        } label: {
                            Image(systemName: "plus")
                                .foregroundStyle(.primary)
                        }
                    }
                }
            }
            .fullScreenCover(isPresented: $viewModel.projectSheetIsPresented, content: {
                ProjectDetailView(project: Project())
            })
            .sheet(isPresented: $viewModel.clientListIsPresented) {
                ClientListView()
            }
            .fullScreenCover(isPresented: $viewModel.settingsSheetIsPresented, content: {
                SettingsView()
            })
            .fullScreenCover(isPresented: $viewModel.chartSheetIsPresented, content: {
                AnalyticsDashboardView()
            })
            // MARK: - Focus State Synchronization
            // This keeps the SwiftUI FocusState in sync with the ViewModel
            .onChange(of: searchFieldFocused) { _, newValue in
                viewModel.searchFieldFocused = newValue
            }
            .onChange(of: viewModel.searchFieldFocused) { _, newValue in
                searchFieldFocused = newValue
            }
        }
    }
}

#Preview {
    ProjectListView()
}
