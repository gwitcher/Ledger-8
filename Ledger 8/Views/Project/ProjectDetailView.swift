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
    @State private var artist = ""
    @State private var jobDate = Date()
    @State private var mediaType = MediaType.recording
    @State private var notes = ""
    @State private var invoiced = false
    @State private var paid = false
    @State private var dateDelivered = Date()
    @State private var dateClosed = Date()
    @State private var status = Status.open
    @State private var sheetIsPresented = false
    
    var body: some View {
        
        NavigationStack {
            Form {
                Section("Project Info") {
                    LabeledContent {
                        TextField("", text: $client)
                        
                    }   label: {
                        Text("Client").foregroundStyle(.secondary)
                            .autocorrectionDisabled()
                    }
                    
                    LabeledContent {
                        TextField("", text: $projectName)
                        
                    }   label: {
                        Text("Project").foregroundStyle(.secondary)
                            .autocorrectionDisabled()
                    }
                    
                    LabeledContent {
                        TextField("", text: $artist)
                        
                    }   label: {
                        Text("Artist").foregroundStyle(.secondary)
                            .autocorrectionDisabled()
                    }
                    
                    LabeledContent {
                        DatePicker("", selection: $jobDate)
                        
                    }   label: {
                        Text("Job Date").foregroundStyle(.secondary)
                    }
                }
                .textFieldStyle(.plain)
                
                Section {
                    Picker("Media", selection: $mediaType) {
                        ForEach(MediaType.allCases) {type in
                            Text(type.rawValue)
                        }
                    }
                }
                
                Section {
                    if project.items?.count != 0 {
                        NavigationLink {
                            ItemListView(project: project)
                        } label: {
                            Text("Items: \(project.items?.count ?? 0)")
                        }
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
                
                Section("Notes") {
                    TextField("", text: $notes, axis: .vertical)
                }
                
                Section {
                    Toggle(isOn: $invoiced) {
                        if !invoiced {
                            Text("Invoiced")
                        } else {
                            HStack{
                                Text("Invoiced")
                                DatePicker("", selection: $dateDelivered, displayedComponents: [.date])
                                    .datePickerStyle(.automatic)
                                    .padding(.horizontal)
                            }
                            
                        }
                        
                    }
                    .tint(paid ? .green : .red)
                    
                    Toggle(isOn: $paid) {
                        if !paid {
                            Text("Paid")
                        } else {
                            HStack{
                                Text("Paid")
                                DatePicker("", selection: $dateClosed, displayedComponents: [.date])
                                    .datePickerStyle(.automatic)
                                    .padding(.horizontal)
                            }
                        }
                    }
                }
                .onChange(of: invoiced) {
                    dateDelivered = Date.now
                    if invoiced && paid {
                        status = .closed
                    } else if invoiced && !paid {
                        status = .invoiced
                    } else if !invoiced && paid {
                        status = .closed
                    } else {
                        status = .open
                    }
                }
                .onChange(of: paid) {
                    dateClosed = Date.now
                    if invoiced && paid {
                        status = .closed
                    } else if invoiced && !paid {
                        status = .invoiced
                    } else if !invoiced && paid {
                        status = .closed
                    } else {
                        status = .open
                    }
                }
            }
            .onAppear {
                client = project.client
                projectName = project.projectName
                artist = project.artist
                jobDate = project.jobDate
                mediaType = project.mediaType
                notes = project.notes
                invoiced = project.invoiced
                paid = project.paid
                dateDelivered = project.dateDelivered
                dateClosed = project.dateClosed
                status = project.status
                
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
        project.artist = artist
        project.jobDate = jobDate
        project.mediaType = mediaType
        project.notes = notes
        project.invoiced = invoiced
        project.paid = paid
        project.dateDelivered = dateDelivered
        project.dateClosed = dateClosed
        project.status = status
        
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
