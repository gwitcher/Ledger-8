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
    @Environment(\.colorScheme) var colorScheme
    
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
    @State private var itemSheetIsPresented = false
    @State private var clientSelectSheetIsPresented = false
    @State private var selectedClient: Client?
    @State private var statusChange = false
    @State private var showAlert = false
    @State private var endDateSelected = false
    @State private var selectedTemplateProject: Project?
    @State private var showProjectSuggestions = false
    @State private var showStartDatePicker = false
    @State private var showStartTimePicker = false
    @State private var showEndDatePicker = false
    @State private var showEndTimePicker = false
    @State private var scrollProxy: ScrollViewProxy?
    
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
        case .game:
            return "gamecontroller"
        }
    }
    
    
    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                List {
                    clientSection
                    projectInfoSection
                    mediaSection
                    itemsSection
                    invoiceSection
                    notesSection
                    statusSection
                }
                .listStyle(.insetGrouped)
                .onAppear {
                    scrollProxy = proxy
                    loadProjectData()
                }
            }
//            .onTapGesture {
//                hideKeyboard()
//            }
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Cannot Save Project"),
                    message: Text(dateAlertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            .toolbar {
                toolbarContent
            }
            .navigationTitle("Project Details")
            .navigationBarTitleDisplayMode(.automatic)
            .navigationBarBackButtonHidden()
            .sheet(isPresented: $clientSelectSheetIsPresented) {
                ClientSelectView(selectedClient: $selectedClient)
            }
            .sheet(isPresented: $itemSheetIsPresented) {
                ItemDetailView(project: project)
            }
            .onChange(of: startDate) {
                handleStartDateChange()
            }
            .onChange(of: endDate) {
                handleEndDateChange()
            }
            .onChange(of: selectedTemplateProject) {
                handleTemplateProjectChange()
            }
            .onChange(of: selectedClient) {
                showProjectSuggestions = false
            }
        }
    }
    
    // MARK: - View Components
    
    @ViewBuilder
    private var clientSection: some View {
        Section("Client") {
            if let client = selectedClient {
                Text(client.fullName)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        print("Shown Client: \(client.fullName)")
                        clientSelectSheetIsPresented.toggle()
                    }
            } else {
                Button {
                    clientSelectSheetIsPresented.toggle()
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.green)
                        Text("Add Client")
                            .foregroundColor(.addClient)
                    }
                }
            }
        }
        .id("clientSection")
    }
    
    @ViewBuilder
    private var projectInfoSection: some View {
        Section("Project Info") {
            projectNameField
            projectSuggestionsList
            artistField
            expandingDateFields
        }
        .textFieldStyle(.plain)
        .id("projectInfoSection")
    }
    
    @ViewBuilder
    private var projectNameField: some View {
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
                        handleProjectFieldFocusChange()
                    }
                projectSuggestionsToggleButton
            }
        } label: {
            Text("Project").foregroundStyle(.secondary)
        }
    }
    
    @ViewBuilder
    private var projectSuggestionsToggleButton: some View {
        if let client = selectedClient, 
           let clientProjects = client.project, 
           !clientProjects.isEmpty {
            Button {
                toggleProjectSuggestions()
            } label: {
                Image(systemName: showProjectSuggestions ? "chevron.up.circle.fill" : "chevron.down.circle")
                    .foregroundStyle(.blue)
                    .font(.system(size: 16))
            }
            .buttonStyle(.plain)
        }
    }
    
    @ViewBuilder
    private var projectSuggestionsList: some View {
        if showProjectSuggestions,
           let client = selectedClient,
           let clientProjects = client.project,
           !clientProjects.isEmpty {
            let suggestions = sortedProjectsByFrequency(clientProjects)
            
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(suggestions) { project in
                        ProjectSuggestionRow(project: project) {
                            selectedTemplateProject = project
                            focusField = nil
                            withAnimation(.easeInOut(duration: 0.2)) {
                                showProjectSuggestions = false
                            }
                        }
                    }
                }
                .padding(.vertical, 4)
            }
            .frame(maxHeight: 200)
        }
    }
    
    @ViewBuilder
    private var artistField: some View {
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
    }

    
    @ViewBuilder
    private var expandingDateFields: some View {
        let datePickerExpandDuration = 0.2
        let datePickerExpandDelay = 0.001
        Group {
              
            HStack {
              
                Text("Start")
                    .foregroundStyle(.secondary)
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: datePickerExpandDuration)){
                            focusField = nil // Dismiss keyboard
                            showEndTimePicker = false
                            showEndDatePicker = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + datePickerExpandDelay) {
                             if showStartTimePicker && !showStartDatePicker {
                                showStartTimePicker = false
                                showStartDatePicker = false
                            } else {
                                showStartDatePicker.toggle()
                            }
                         }
                        }
                    }
                
                Spacer()
                
                Button("\(startDate.formatted(date: .abbreviated, time: .omitted))") {
                    focusField = nil // Dismiss keyboard
                    DispatchQueue.main.asyncAfter(deadline: .now() + datePickerExpandDelay) {
                        withAnimation(.easeInOut(duration: datePickerExpandDuration)){
                            showEndTimePicker = false
                            showEndDatePicker = false
                            if showStartTimePicker {
                                showStartTimePicker = false
                            }
                            showStartDatePicker.toggle()
                        }
                    }
                }
                .buttonStyle(.bordered)
                .foregroundStyle(.primary)
                
                Button("\(startDate.formatted(date: .omitted, time: .shortened))") {
                    focusField = nil // Dismiss keyboard
                    DispatchQueue.main.asyncAfter(deadline: .now() + datePickerExpandDelay) {
                        withAnimation(.easeInOut(duration: datePickerExpandDuration)){
                            showEndTimePicker = false
                            showEndDatePicker = false
                            if showStartDatePicker {
                                showStartDatePicker = false
                            }
                            showStartTimePicker.toggle()
                        }
                    }
                }
                .buttonStyle(.bordered)
                .foregroundStyle(.primary)
            }
            
            if showStartDatePicker {
                VStack {
                    DatePicker("", selection: $startDate, displayedComponents: .date)
                        .datePickerStyle(.graphical)
                        .focused($focusField, equals: .startDate)
                }
                .padding(.vertical, 12)
                .id("startDatePicker")
            }
            
            if showStartTimePicker {
                VStack {
                    DatePicker("", selection: $startDate, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.wheel)
                        .focused($focusField, equals: .startDate)
                }
                .padding(.vertical, 12)
                .id("startTimePicker")
            }
            
            HStack {
                //Spacer()
                Text("End")
                    .foregroundStyle(.secondary)
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: datePickerExpandDuration)){
                            focusField = nil // Dismiss keyboard
                            showStartTimePicker = false
                            showStartDatePicker = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + datePickerExpandDelay) {
                                 if showEndTimePicker && !showEndDatePicker {
                                    showEndTimePicker = false
                                    showEndDatePicker = false
                                } else {
                                    showEndDatePicker.toggle()
                                }
                             }
                        }
                    }
                
                Spacer()
                
                Button("\(endDate.formatted(date: .abbreviated, time: .omitted))") {
                    focusField = nil // Dismiss keyboard
                    DispatchQueue.main.asyncAfter(deadline: .now() + datePickerExpandDelay) {
                        withAnimation(.easeInOut(duration: datePickerExpandDuration)){
                            showStartTimePicker = false
                            showStartDatePicker = false
                            if showEndTimePicker {
                                showEndTimePicker = false
                            }
                            showEndDatePicker.toggle()
                        }
                    }
                }
                .buttonStyle(.bordered)
                .foregroundStyle(.primary)
                
                Button("\(endDate.formatted(date: .omitted, time: .shortened))") {
                    focusField = nil // Dismiss keyboard
                    DispatchQueue.main.asyncAfter(deadline: .now() + datePickerExpandDelay) {
                        withAnimation(.easeInOut(duration: datePickerExpandDuration)){
                            showStartTimePicker = false
                            showStartDatePicker = false
                            if showEndDatePicker {
                                showEndDatePicker = false
                            }
                            showEndTimePicker.toggle()
                        }
                    }
                }
                .buttonStyle(.bordered)
                .foregroundStyle(.primary)
            }
            
            if showEndDatePicker {
                VStack {
                    DatePicker("", selection: $endDate, displayedComponents: .date)
                        .datePickerStyle(.graphical)
                        .focused($focusField, equals: .endDate)
                }
                .padding(.vertical, 12)
                .id("endDatePicker")
            }
            
            if showEndTimePicker {
                VStack {
                    DatePicker("", selection: $endDate, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.wheel)
                        .focused($focusField, equals: .endDate)
                }
                .padding(.vertical, 12)
                .id("endTimePicker")
            }

            
        }
        .onChange(of: focusField) { oldValue, newValue in
            if newValue != .endDate && newValue != .startDate {
                showStartDatePicker = false
                showStartTimePicker = false
                showEndDatePicker = false
                showEndTimePicker = false
                
                // Scroll to top when all date pickers are closed, unless focusing notes
                if newValue != .notes {
                    scrollToTop()
                }
            }
            
            // Handle notes field focus for keyboard avoidance
            if newValue == .notes {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    scrollToNotes()
                }
            }
        }
        .onChange(of: showStartDatePicker) { _, isShowing in
            if isShowing {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    scrollToProjectInfo()
                }
            } else {
                checkAndScrollToTopIfAllPickersClosed()
            }
        }
        .onChange(of: showStartTimePicker) { _, isShowing in
            if isShowing {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    scrollToProjectInfo()
                }
            } else {
                checkAndScrollToTopIfAllPickersClosed()
            }
        }
        .onChange(of: showEndDatePicker) { _, isShowing in
            if isShowing {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    scrollToProjectInfo()
                }
            } else {
                checkAndScrollToTopIfAllPickersClosed()
            }
        }
        .onChange(of: showEndTimePicker) { _, isShowing in
            if isShowing {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    scrollToProjectInfo()
                }
            } else {
                checkAndScrollToTopIfAllPickersClosed()
            }
        }
        
    }
    
    
    @ViewBuilder
    private var mediaSection: some View {
        Section {
            Picker("Media", selection: $mediaType) {
                ForEach(MediaType.allCases) { type in
                    Text(type.rawValue)
                }
            }
        }
    }
    
    @ViewBuilder
    private var itemsSection: some View {
        Section {
            if project.items?.count != 0 {
                NavigationLink {
                    ItemListView2(project: project)
                } label: {
                    HStack {
                        Text("Items: \(project.items?.count ?? 0)")
                        Spacer()
                        Text("\(project.calculateFeeTotal(items: project.items!).formatted(.currency(code: "USD")))")
                    }
                }
            }
            
            Button {
                //saveProject()
                itemSheetIsPresented.toggle()
                print("🫑 sheet is presented: \(itemSheetIsPresented)")
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(.green)
                    Text("Add Item")
                        .foregroundColor(.addClient)
                }
            }
        }
    }
    
    @ViewBuilder
    private var invoiceSection: some View {
        if statusChange {
            Section("Invoice") {
                if project.invoice != nil {
                    InvoiceLinkView(project: project)
                } else {
                    AddInvoiceView(project: project)
                }
            }
        }
    }
    
    @ViewBuilder
    private var notesSection: some View {
        Section("Notes") {
            TextField("", text: $notes, axis: .vertical)
                .focused($focusField, equals: .notes)
        }
        .id("notesSection")
    }
    
    @ViewBuilder
    private var statusSection: some View {
        Section {
            deliveredToggle
            paidToggle
        }
        .onChange(of: delivered) {
            handleDeliveredChange()
        }
        .onChange(of: paid) {
            handlePaidChange()
        }
        .onChange(of: status) {
            handleStatusChange()
        }
    }
    
    @ViewBuilder
    private var deliveredToggle: some View {
        Toggle(isOn: $delivered) {
            if !delivered {
                Text("Delivered")
            } else {
                HStack {
                    Text("Delivered")
                    DatePicker("", selection: $dateDelivered, displayedComponents: [.date])
                        .datePickerStyle(.automatic)
                        .padding(.horizontal)
                }
            }
        }
        .tint(paid ? .green : .red)
    }
    
    @ViewBuilder
    private var paidToggle: some View {
        Toggle(isOn: $paid) {
            if !paid {
                Text("Paid")
            } else {
                HStack {
                    Text("Paid")
                    DatePicker("", selection: $dateClosed, displayedComponents: [.date])
                        .datePickerStyle(.automatic)
                        .padding(.horizontal)
                }
            }
        }
        .tint(.green)
    }
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button("Cancel", systemImage: "xmark", role: .cancel) {
                dismiss()
            }
        }
        
        ToolbarItem(placement: .topBarTrailing) {
            Button("Done", systemImage: "checkmark.circle.fill") {
                if endDate < startDate {
                    showAlert.toggle()
                } else {
                    saveProject()
                    clearTextFields()
                    dismiss()
                }
            }
        }
    }
    
    // MARK: - Helper Views
    
    private struct ProjectSuggestionRow: View {
        let project: Project
        let action: () -> Void
        
        var body: some View {
            Button(action: action) {
                HStack {
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
        
        private func getMediaIcon(for mediaType: MediaType) -> String {
            switch mediaType {
            case .film: return "film"
            case .tv: return "tv"
            case .recording: return "mic"
            case .concert: return "person.3"
            case .tour: return "bus"
            case .lesson: return "graduationcap"
            case .other: return "questionmark.circle"
            case .game: return "gamecontroller"
                
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func loadProjectData() {
        selectedClient = project.client
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
    
    private func handleProjectFieldFocusChange() {
        if focusField == .project,
           let client = selectedClient,
           let clientProjects = client.project,
           !clientProjects.isEmpty {
            withAnimation(.easeInOut(duration: 0.2)) {
                showProjectSuggestions = true
            }
        } else if focusField != .project {
            withAnimation(.easeInOut(duration: 0.2)) {
                showProjectSuggestions = false
            }
        }
    }
    
    private func toggleProjectSuggestions() {
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
    }
    
    private func handleStartDateChange() {
        if !endDateSelected {
            print("🟢 On Change initialized")
            print("End Date selected: \(endDateSelected)")
            endDate = startDate.adding(hours: 1)
        }
    }
    
    private func handleEndDateChange() {
        if endDate != startDate.adding(hours: 1) {
            endDateSelected = true
            print("End Date selected: \(endDateSelected)")
        }
    }
    
    private func handleTemplateProjectChange() {
        if let templateProject = selectedTemplateProject {
            projectName = templateProject.projectName
            artist = templateProject.artist
            mediaType = templateProject.mediaType
            notes = templateProject.notes
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                selectedTemplateProject = nil
            }
        }
    }
    
    private func handleDeliveredChange() {
        dateDelivered = Date.now
        updateProjectStatus()
        saveProject()
    }
    
    private func handlePaidChange() {
        dateClosed = Date.now
        if !delivered {
            delivered = true
        }
        updateProjectStatus()
        saveProject()
    }
    
    private func updateProjectStatus() {
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
    
    private func handleStatusChange() {
        switch status {
        case .open:
            statusChange = false
        case .delivered:
            statusChange = true
        case .closed:
            statusChange = true
        }
    }
    
    private func scrollToTop() {
        guard let scrollProxy = scrollProxy else { return }
        
        withAnimation(.easeInOut(duration: 0.3)) {
            scrollProxy.scrollTo("clientSection", anchor: .top)
        }
    }
    
    private func scrollToProjectInfo() {
        guard let scrollProxy = scrollProxy else { return }
        
        withAnimation(.easeInOut(duration: 0.3)) {
            scrollProxy.scrollTo("projectInfoSection", anchor: .top)
        }
    }
    
    private func scrollToNotes() {
        guard let scrollProxy = scrollProxy else { return }
        
        withAnimation(.easeInOut(duration: 0.3)) {
            scrollProxy.scrollTo("notesSection", anchor: .bottom)
        }
    }
    
    private func checkAndScrollToTopIfAllPickersClosed() {
        // Check if all date pickers are closed
        if !showStartDatePicker && !showStartTimePicker && !showEndDatePicker && !showEndTimePicker {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                scrollToTop()
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
