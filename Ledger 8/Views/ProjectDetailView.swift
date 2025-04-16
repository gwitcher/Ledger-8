//
//  ProjectItemView.swift
//  Ledger 8
//
//  Created by Gabe Witcher on 4/15/25.
//

import SwiftUI
import SwiftData

struct ProjectDetailView: View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss
    
    var project: Project
    
    @State private var client = ""
    @State private var projectName = ""
    @State private var jobDate = Date()
    @State private var sheetIsPresented = false
    
    var body: some View {
        
        NavigationStack {
            Form {
                Section("Project Info") {
                    LabeledContent {
                        TextField("", text: $client)
                        
                    }   label: {
                        Text("Client").foregroundStyle(.secondary)
                            .textContentType(.name)
                    }
                    LabeledContent {
                        TextField("", text: $projectName)
                        
                    }   label: {
                        Text("Project").foregroundStyle(.secondary)
                            .textContentType(.name)
                    }
                    LabeledContent {
                        DatePicker("", selection: $jobDate)
                        
                    }   label: {
                        Text("Job Date").foregroundStyle(.secondary)
                            .textContentType(.name)
                    }
                }
                .textFieldStyle(.plain)
                Section {
                    NavigationLink {
                        ItemListView(project: project)
                    } label: {
                        Text("Items: \(project.items?.count ?? 0)")
                    }

                    Button {
                        sheetIsPresented.toggle()
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Item")
                        }
                    }
                    
                }
            }
            .onAppear {
                client = project.client
                projectName = project.projectName
                jobDate = project.jobDate
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel", role: .cancel) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        saveProject()
                        dismiss()
                    }
                }
                
                
            }
            .navigationTitle("Project Details")
            .navigationBarTitleDisplayMode(.automatic)
            .navigationBarBackButtonHidden()
            .sheet(isPresented: $sheetIsPresented) {
                ItemDetailView(project: project)
            }
            
            
            
        }
    }
    func saveProject() {
        project.client = client
        project.projectName = projectName
        project.jobDate = jobDate
        
        modelContext.insert(project)
        guard let _ = try? modelContext.save() else{
            print("😡 ERROR: Cannot save")
            return
        }
        
        client = ""
        projectName = ""
        jobDate = Date()
    }
}

#Preview {
    ProjectDetailView(project: Project(client: "test1", projectName: "test1", jobDate: Date.now, items: [Item]()))
        .modelContainer(for: Project.self, inMemory: true)
}
