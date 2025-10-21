//
//  CSVImportIntegration.swift
//  Ledger 8
//
//  Example integration for CSV Import functionality
//

import SwiftUI
import SwiftData

// MARK: - Example: Adding CSV Import to Your Main Menu/Settings

struct ExampleSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var showingCSVImport = false
    
    var body: some View {
        NavigationView {
            List {
                Section("Data Management") {
                    Button {
                        showingCSVImport = true
                    } label: {
                        HStack {
                            Image(systemName: "square.and.arrow.down")
                                .foregroundColor(.blue)
                            Text("Import CSV Data")
                        }
                    }
                    
                    // Add other settings here...
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showingCSVImport) {
                CSVImportView(modelContext: modelContext)
            }
        }
    }
}

// MARK: - Example: Adding CSV Import as a Toolbar Button

struct ExampleProjectsListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var projects: [Project]
    @State private var showingCSVImport = false
    
    var body: some View {
        NavigationView {
            List(projects) { project in
                // Your project list items here
                Text(project.projectName)
            }
            .navigationTitle("Projects")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            showingCSVImport = true
                        } label: {
                            Label("Import CSV", systemImage: "square.and.arrow.down")
                        }
                        
                        // Add other menu items...
                        
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showingCSVImport) {
                CSVImportView(modelContext: modelContext)
            }
        }
    }
}

// MARK: - Example: CSV Import as Part of Onboarding

struct ExampleOnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var showingCSVImport = false
    @Binding var onboardingComplete: Bool
    
    var body: some View {
        VStack(spacing: 30) {
            Text("Welcome to Ledger 8")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Get started by importing your existing data or create new projects")
                .font(.body)
                .multilineTextAlignment(.center)
            
            VStack(spacing: 16) {
                Button {
                    showingCSVImport = true
                } label: {
                    HStack {
                        Image(systemName: "square.and.arrow.down")
                        Text("Import from CSV")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
                }
                
                Button {
                    onboardingComplete = true
                } label: {
                    Text("Start Fresh")
                        .font(.headline)
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.blue, lineWidth: 2)
                        )
                }
            }
            .padding(.horizontal)
        }
        .padding()
        .sheet(isPresented: $showingCSVImport) {
            CSVImportView(modelContext: modelContext)
                .onDisappear {
                    // Optionally complete onboarding after import
                    onboardingComplete = true
                }
        }
    }
}

// MARK: - Quick Integration Example
// Add this to your existing SettingsView or wherever you want the import button

extension View {
    func addCSVImportButton(modelContext: ModelContext) -> some View {
        @State var showingCSVImport = false
        
        return self
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingCSVImport = true
                    } label: {
                        Image(systemName: "square.and.arrow.down")
                    }
                }
            }
            .sheet(isPresented: $showingCSVImport) {
                CSVImportView(modelContext: modelContext)
            }
    }
}