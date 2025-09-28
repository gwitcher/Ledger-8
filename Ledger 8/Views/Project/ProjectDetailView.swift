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
    @State private var selectedTemplateProject: Project?
    @State private var showProjectSuggestions = false
    
    @FocusState private var focusField: ProjectField?
    
    // Helper function to sort projects by frequency and then alphabetically
    private func sortedProjectsByFrequency(_ projects: [Project]) -> [Project] {
        // Filter out projects with empty names first
        let projectsWithNames = projects.filter { !$0.projectName.isEmpty }
        
        // Group projects by name and count occurrences
        let projectCounts = Dictionary(grouping: projectsWithNames, by: { $0.projectName })
            .mapValues { $0.count }
        
        // Get unique projects (one per project name) using the most recent one for each name
        let uniqueProjects = Dictionary(grouping: projectsWithNames, by: { $0.projectName })
            .compactMapValues { projectsWithSameName in
                // Return the most recent project for each name
                projectsWithSameName.max(by: { $0.startDate < $1.startDate })
            }
            .values
        
        // Sort first by frequency (descending), then alphabetically (ascending)
        return Array(uniqueProjects).sorted { project1, project2 in
            let count1 = projectCounts[project1.projectName] ?? 0
            let count2 = projectCounts[project2.projectName] ?? 0
            
            // If counts are different, sort by count (higher first)
            if count1 != count2 {
                return count1 > count2
            }
            
            // If counts are the same, sort alphabetically
            return project1.projectName.localizedStandardCompare(project2.projectName) == .orderedAscending
        }
    }
    
    // Helper function to get system icons for media types
    private func getMediaIcon(for mediaType: MediaType) -> String {
        switch mediaType {
        case .film:
            return "film"
        case .tv:
            return "tv"
        case .recording:
            return "mic"
        case .concert:
            return "person.3"
        case .tour:
            return "bus"
        case .lesson:
            return "graduationcap"
        case .other:
            return "questionmark.circle"
        }
    }
    
    
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
                        HStack {
                            TextField("", text: $projectName)
                                .autocorrectionDisabled()
                                .submitLabel(.next)
                                .focused($focusField, equals: .project)
                                .onSubmit {
                                    focusField = .artist
                                }
                                .onChange(of: focusField) {
                                    // Auto-expand suggestions when project field is focused
                                    if focusField == .project, 
                                       let client = selectedClient, 
                                       let clientProjects = client.project, 
                                       !clientProjects.isEmpty {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            showProjectSuggestions = true
                                        }
                                    } else if focusField != .project {
                                        // Auto-collapse when focus moves away from project field
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            showProjectSuggestions = false
                                        }
                                    }
                                }
                            
                            // MARK: PROJECT SUGGESTIONS TOGGLE BUTTON
                            if let client = selectedClient, let clientProjects = client.project, !clientProjects.isEmpty {
                                Button {
                                    // Toggle suggestions or focus the text field if collapsed
                                    if showProjectSuggestions {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            showProjectSuggestions = false
                                        }
                                        focusField = nil
                                    } else {
                                        focusField = .project
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            showProjectSuggestions = true
                                        }
                                    }
                                } label: {
                                    Image(systemName: showProjectSuggestions ? "chevron.up.circle.fill" : "chevron.down.circle")
                                        .foregroundStyle(.blue)
                                        .font(.system(size: 16))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    } label: {
                        Text("Project").foregroundStyle(.secondary)
                        
                    }
                    
                    // MARK: PROJECT SUGGESTIONS LIST
                    if showProjectSuggestions, let client = selectedClient, let clientProjects = client.project, !clientProjects.isEmpty {
                        let suggestions = sortedProjectsByFrequency(clientProjects)
                        
                        ScrollView {
                            LazyVStack(spacing: 8) {
                                ForEach(suggestions) { project in
                                    Button {
                                        selectedTemplateProject = project
                                        focusField = nil // Remove focus when selecting a template
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            showProjectSuggestions = false
                                        }
                                    } label: {
                                        HStack {
                                            // MARK: MEDIA TYPE ICON
                                            Image(systemName: getMediaIcon(for: project.mediaType))
                                                .font(.subheadline)
                                                .foregroundStyle(.blue)
                                                .frame(width: 20)
                                            
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(project.projectName)
                                                    .font(.subheadline)
                                                    .foregroundStyle(.primary)
                                                    .multilineTextAlignment(.leading)
                                                
                                                Text(project.mediaType.rawValue)
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                            }
                                            
                                            Spacer()
                                            
                                            Image(systemName: "arrow.up.left")
                                                .font(.caption)
                                                .foregroundStyle(.blue)
                                        }
                                        .padding(.vertical, 4)
                                        .padding(.horizontal, 8)
                                        .background(.quaternary.opacity(0.3))
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .frame(maxHeight: 200) // Limit height to make it scrollable
                    }
                    
                    LabeledContent {
                        TextField("", text: $artist)
                            .autocorrectionDisabled()
                            .focused($focusField, equals: .artist)
                            .onSubmit {
                                focusField = nil
                            }
                    } label: {
                        Text("Artist").foregroundStyle(.secondary)
                        
                    }
                    
                    LabeledContent {
                        DatePicker("", selection: $startDate)
                            .datePickerStyle(.compact)
                    }   label: {
                        Text("Start").foregroundStyle(.secondary)
                    }
                    LabeledContent {
                        DatePicker("", selection: $endDate)
                            .datePickerStyle(.compact)
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
            .onChange(of: selectedTemplateProject) {
                if let templateProject = selectedTemplateProject {
                    // Pre-fill form fields with template project data
                    projectName = templateProject.projectName
                    artist = templateProject.artist
                    mediaType = templateProject.mediaType
                    notes = templateProject.notes
                    
                    // Reset the picker selection after use
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        selectedTemplateProject = nil
                    }
                }
            }
            .onChange(of: selectedClient) {
                // Collapse suggestions when client changes
                showProjectSuggestions = false
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
