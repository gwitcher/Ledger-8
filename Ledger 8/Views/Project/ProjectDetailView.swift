//
//  ProjectItemView.swift
//  Ledger 8
//
//  Created by Gabe Witcher on 4/15/25.
//

import SwiftUI
import SwiftData
import ContactsUI

struct ProjectDetailView: View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss
    
    var project: Project
    
    @State private var projectName = ""
    @State private var artist = ""
    @State private var jobDate = Date()
    @State private var mediaType = MediaType.recording
    @State private var notes = ""
    @State private var delivered = false
    @State private var paid = false
    @State private var dateDelivered = Date()
    @State private var dateClosed = Date()
    @State private var status = Status.open
    @State private var sheetIsPresented = false
    @State private var clientSheetIsPresented = false
    @State private var selectedClient: Client? = nil
    
    
    
    var body: some View {
        
        NavigationStack {
            Form {
                Section("Client") {
                    if selectedClient != nil {
                        Text(selectedClient!.name)
                            .onTapGesture {
                                print("Shown Client: \(selectedClient?.name ?? "NIL")")
                                clientSheetIsPresented.toggle()
                            }

                    } else {
                        Button {
                            clientSheetIsPresented.toggle()
                        } label: {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .tint(.green)
                                Text("Add Client")
                            }
                        }
                    }
                    
                }
                
                Section("Project Info") {
                                        
                    LabeledContent {
                        TextField("", text: $projectName)
                            .autocorrectionDisabled()
                    }   label: {
                        Text("Project").foregroundStyle(.secondary)
                            
                    }
                    
                    LabeledContent {
                        TextField("", text: $artist)
                            .autocorrectionDisabled()
                    }   label: {
                        Text("Artist").foregroundStyle(.secondary)
                            
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
                            HStack{
                                Text("Items: \(project.items?.count ?? 0)")
                                
                                Spacer()
                                
                                Text("\(project.calculateFeeTotal(items: project.items!).formatted(.currency(code: "USD")))")
                            }
                        }
                    }
                    Button {
                        sheetIsPresented.toggle()
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(.green)
                            Text("Add Item")
                                .tint(.primary)
                        }
                    }
                }
                
                //AddInvoiceView(project: project)
                
                Section("Notes") {
                    TextField("", text: $notes, axis: .vertical)
                }
                
                
                Section {
                    Toggle(isOn: $delivered) {
                        if !delivered {
                            Text("Delivered")
                        } else {
                            HStack{
                                Text("Delivered")
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
                .onChange(of: delivered) {
                    dateDelivered = Date.now
                    if delivered && paid {
                        status = .closed
                    } else if delivered && !paid {
                        status = .delivered
                    } else if !delivered && paid {
                        status = .closed
                    } else {
                        status = .open
                    }
                }
                .onChange(of: paid) {
                    dateClosed = Date.now
                    if delivered && paid {
                        status = .closed
                    } else if delivered && !paid {
                        status = .delivered
                    } else if !delivered && paid {
                        status = .closed
                    } else {
                        status = .open
                    }
                }
            }
            .onAppear {
                print("ON APPEAR: \nProject Client: \(project.client?.name ?? "NIL"), selectedClient: \(selectedClient?.name ?? "NIL")")
                selectedClient = project.client
                projectName = project.projectName
                artist = project.artist
                jobDate = project.jobDate
                mediaType = project.mediaType
                notes = project.notes
                delivered = project.delivered
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
            .sheet(isPresented: $clientSheetIsPresented) {
                ClientSelectView(selectedClient: $selectedClient)
            }
            .sheet(isPresented: $sheetIsPresented) {
                ItemDetailView(project: project)
            }
        }
    }
    
    func saveProject() {
        print("Save before: Project Client: \(project.client?.name ?? "NIL"), SelectedClient: \(selectedClient?.name ?? "NIL")")
        project.client = selectedClient
        print("Save after: Project Client: \(project.client?.name ?? "NIL"), SelectedClient: \(selectedClient?.name ?? "NIL")")
        project.projectName = projectName
        project.artist = artist
        project.jobDate = jobDate
        project.mediaType = mediaType
        project.notes = notes
        project.delivered = delivered
        project.paid = paid
        project.dateDelivered = dateDelivered
        project.dateClosed = dateClosed
        project.status = status
        
        modelContext.insert(project)
        guard let _ = try? modelContext.save() else{
            print("😡 ERROR: Cannot save")
            return
        }

        projectName = ""
        artist = ""
        notes = ""
        jobDate = Date()
    }
}

#Preview {
    ProjectDetailView(project: Project(projectName: "", jobDate: Date.now, items: [Item]()))
        .modelContainer(for: Project.self, inMemory: true)
}
