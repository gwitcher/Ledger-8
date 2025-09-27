//
//  ProjectItemView.swift
//  Ledger 8
//
//  Created by Gabe Witcher on 4/15/25.
//

//THIS IS A COMMIT TEST

import SwiftUI
import SwiftData
import ContactsUI

struct ProjectDetailView: View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss
    
    var project: Project
    
    let dateAlertMessage = "The start date must be before the end date"
    
    @State private var projectName = ""
    @State private var artist = ""
    @State private var startDate = Date()
    @State private var endDate = Date()
    @State private var mediaType = MediaType.recording
    @State private var notes = ""
    @State private var delivered = false
    @State private var paid = false
    @State private var dateDelivered = Date()
    @State private var dateClosed = Date()
    @State private var status = Status.open
    @State private var sheetIsPresented = false
    @State private var clientSelectSheetIsPresented = false
    @State private var selectedClient: Client?
    @State private var statusChange = false
    @State private var showAlert = false
    @State private var endDateSelected = false
    
    @FocusState private var focusField: ProjectField?
    
    
    var body: some View {
        
        NavigationStack {
            Form {
                
                //MARK: CLIENT
                
                Section("Client") {
                    if selectedClient != nil {
                        Text(selectedClient!.fullName)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                print("Shown Client: \(selectedClient?.fullName ?? "NIL")")
                                clientSelectSheetIsPresented.toggle()
                            }
                        
                    } else {
                        Button {
                            clientSelectSheetIsPresented.toggle()
                        } label: {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .tint(.green)
                                Text("Add Client")
                                    .foregroundStyle(.black)
                            }
                        }
                    }
                    
                }
                
                //MARK: PROJECT INFO
                
                Section("Project Info") {
                    
                    LabeledContent {
                        TextField("", text: $projectName)
                            .autocorrectionDisabled()
                            .submitLabel(.next)
                            .focused($focusField, equals: .project)
                            .onSubmit {
                                focusField = .artist
                            }
                    }   label: {
                        Text("Project").foregroundStyle(.secondary)
                        
                    }
                    
                    LabeledContent {
                        TextField("", text: $artist)
                            .autocorrectionDisabled()
                            .focused($focusField, equals: .artist)
                            .onSubmit {
                                focusField = nil
                            }
                    }   label: {
                        Text("Artist").foregroundStyle(.secondary)
                        
                    }
                    
                    LabeledContent {
                        DatePicker("", selection: $startDate)
                    }   label: {
                        Text("Start").foregroundStyle(.secondary)
                    }
                    LabeledContent {
                        DatePicker("", selection: $endDate)
                    }
                    label: {
                        Text("End").foregroundStyle(.secondary)
                    }
                }
                .textFieldStyle(.plain)
                
                //MARK: MEDIA
                
                Section {
                    Picker("Media", selection: $mediaType) {
                        ForEach(MediaType.allCases) {type in
                            Text(type.rawValue)
                        }
                    }
                }
                
                //MARK: ITEMS SECTION
                
                Section {
                    if project.items?.count != 0 {
                        NavigationLink {
                            ItemListView2(project: project)
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
                
                
                
                //MARK: invoice stuff
                
                if (statusChange) {
                    Section("Invoice"){
                        if (project.invoice) != nil {
                            InvoiceLinkView(project: project)
                        } else {
                            AddInvoiceView(project: project)
                        }
                    }
                }
                
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
                    saveProject()
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
                    saveProject()
                }
                .onChange(of: status) {
                    
                    switch status {
                    case .open:
                        statusChange = false
                    case .delivered:
                        statusChange = true
                    case .closed:
                        statusChange = true
                    }
                }
            }
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Cannot Save Project"),
                    message: Text(dateAlertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            .onAppear {
                //                print("ON APPEAR Before: \nProject Client: \(project.client?.name ?? "NIL"), selectedClient: \(selectedClient?.name ?? "NIL")")
                
                selectedClient = project.client
                
                //                print("ON APPEAR After: \nProject Client: \(project.client?.name ?? "NIL"), selectedClient: \(selectedClient?.name ?? "NIL")")
                
                projectName = project.projectName
                artist = project.artist
                startDate = project.startDate
                endDate = project.endDate
                mediaType = project.mediaType
                notes = project.notes
                delivered = project.delivered
                paid = project.paid
                dateDelivered = project.dateDelivered
                dateClosed = project.dateClosed
                status = project.status
                endDateSelected = project.endDateSelected
                
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel", role: .cancel) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        if endDate < startDate {
                            showAlert.toggle()
                        }else {
                            saveProject()
                            clearTextFields()
                            dismiss()
                        }
                        
                    }
                }
            }
            .navigationTitle("Project Details")
            .navigationBarTitleDisplayMode(.automatic)
            .navigationBarBackButtonHidden()
            .sheet(isPresented: $clientSelectSheetIsPresented) {
                ClientSelectView(selectedClient: $selectedClient)
            }
            .sheet(isPresented: $sheetIsPresented) {
                ItemDetailView(project: project)
            }
            .onChange(of: startDate) {
                if !endDateSelected {
                    print("🟢 On Change initialized")
                    print("End Date selected: \(endDateSelected)")
                    endDate = startDate.adding(hours: 1)
                }
            }
            .onChange(of: endDate) {
                if endDate != startDate.adding(hours: 1) {
                    endDateSelected = true
                    print("End Date selected: \(endDateSelected)")
                }
                
            }
        }
        
    }
    
    func saveProject() {
        print("Save before: Project Client: \(project.client?.fullName ?? "NIL"), SelectedClient: \(selectedClient?.fullName ?? "NIL")")
        
        project.client = selectedClient
        
        print("Save after: Project Client: \(project.client?.fullName ?? "NIL"), SelectedClient: \(selectedClient?.fullName ?? "NIL")")
        
        project.projectName = projectName
        project.artist = artist
        project.startDate = startDate
        project.endDate = endDate
        project.mediaType = mediaType
        project.notes = notes
        project.delivered = delivered
        project.paid = paid
        project.dateDelivered = dateDelivered
        project.dateClosed = dateClosed
        project.status = status
        project.endDateSelected = endDateSelected
        
        modelContext.insert(project)
        
        guard let _ = try? modelContext.save() else{
            print("😡 ERROR: Cannot save")
            return
        }
    }
    
    func clearTextFields() {
        projectName = ""
        artist = ""
        notes = ""
        startDate = Date()
    }
}

#Preview {
    ProjectDetailView(project: Project(projectName: "", startDate: Date.now, items: [Item]()))
        .modelContainer(for: Project.self, inMemory: true)
}
