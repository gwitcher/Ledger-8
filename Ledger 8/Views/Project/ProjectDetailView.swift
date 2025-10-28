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
import MapKit

struct ProjectDetailView: View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    var project: Project
    
    // MARK: - ViewModel
    @State private var viewModel: ProjectDetailViewModel?
    
    // MARK: - Initialization
    init(project: Project) {
        self.project = project
        // ViewModel will be initialized in onAppear when modelContext is available
    }
    
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
    // Migrated to ViewModel: statusChange will be handled through computed property
    @State private var endDateSelected = false
    @State private var selectedTemplateProject: Project?
    @State private var showProjectSuggestions = false
    @State private var showStartDatePicker = false
    @State private var showStartTimePicker = false
    @State private var showEndDatePicker = false
    @State private var showEndTimePicker = false
    @State private var scrollProxy: ScrollViewProxy?
    @State var selectedLocation = Place(mapItem: MKMapItem())
    
    // Debounced saving
    @State private var saveWorkItem: DispatchWorkItem?
    
    @FocusState private var focusField: ProjectField?
    
    // MARK: - Computed Properties
    private var showAlert: Bool {
        get { viewModel?.showAlert ?? false }
        nonmutating set { viewModel?.showAlert = newValue }
    }
    
    private var statusChange: Bool {
        viewModel?.statusChange ?? false
    }
    
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
                    // Initialize ViewModel with proper modelContext
                    if viewModel == nil {
                        viewModel = ProjectDetailViewModel(project: project, modelContext: modelContext)
                    }
                    scrollProxy = proxy
                    loadProjectData()
                }
            }
            .alert(isPresented: Binding(
                get: { viewModel?.showAlert ?? false },
                set: { viewModel?.showAlert = $0 }
            )) {
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
                autoSaveProjectChanges()
            }
        }
    }
    
    // MARK: - View Components
    
    @ViewBuilder
    private var clientSection: some View {
        Section("Client") {
            Button {
                clientSelectSheetIsPresented.toggle()
            } label: {
                HStack {
                    Image(systemName: "person.circle")
                        .foregroundStyle(.primary)
                        .font(.title3)
                    
                    if let client = selectedClient {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(client.fullName)
                                .foregroundStyle(.primary)
                            if !client.email.isEmpty {
                                Text(client.email)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    } else {
                        Text("Select Client")
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .buttonStyle(.plain)
            
            LocationView(project: project)
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
                    .onChange(of: projectName) { _, newValue in
                        debouncedAutoSave() // Use debounced for project name to avoid saving while typing
                    }
                projectSuggestionsToggleButton
            }
        } label: {
            Text("Project").foregroundStyle(.primary)
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
                .onChange(of: artist) { _, newValue in
                    debouncedAutoSave() // Use debounced for artist to avoid saving while typing
                }
        } label: {
            Text("Artist").foregroundStyle(.primary)
        }
    }
    
    
    @ViewBuilder
    private var expandingDateFields: some View {
        let datePickerExpandDuration = 0.2
        let datePickerExpandDelay = 0.001
        Group {
            
            HStack {
                
                Text("Starts")
                    .foregroundStyle(.primary)
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
                Text("Ends")
                    .foregroundStyle(.primary)
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
            .onChange(of: mediaType) { _, newValue in
                autoSaveProjectChanges()
            }
        }
    }
    
    @ViewBuilder
    private var itemsSection: some View {
        Section {
            if let items = project.items, !items.isEmpty {
                NavigationLink {
                    EnhancedProjectItemListView(project: project)
                } label: {
                    HStack {
                        Image(systemName: "list.bullet")
                            .foregroundStyle(.blue)
                        Text("Items: \(items.count)")
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            Text(project.calculateFeeTotal(items: items).formatted(.currency(code: "USD")))
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                    }
                }
            }
            
            Button {
                itemSheetIsPresented.toggle()
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(.green)
                    Text("Add Item")
                        .foregroundColor(.primary)
                }
            }
        } header: {
            Text("Items & Fees")
        }
    }
    
    @ViewBuilder
    private var invoiceSection: some View {
        if statusChange {
            Section("Invoice") {
                if project.invoice != nil {
                    VStack(alignment: .leading, spacing: 8) {
                        InvoiceLinkView(project: project)
                        
                        invoiceWarningAlert
                        
                    }
                } else {
                    AddInvoiceView(project: project)
                }
            }
        }
    }
    
    @ViewBuilder
    private var invoiceWarningAlert: some View {
        
        // Warning message when invoice needs update
        if project.invoiceNeedsUpdate {
            Divider()
            Text("⚠️ Warning: Project info has changed. Please delete invoice and create new.")
                .font(.caption)
                .foregroundColor(.orange)
                .padding(.top, 4)
        }
        
    }
    
    @ViewBuilder
    private var notesSection: some View {
        Section("Notes") {
            TextField("", text: $notes, axis: .vertical)
                .focused($focusField, equals: .notes)
                .onChange(of: notes) { _, newValue in
                    debouncedAutoSave() // Use debounced for notes to avoid saving while typing
                }
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
            viewModel?.handleStatusChange()
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
    //MARK: - Toolbar Content Builder
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .foregroundStyle(.primary)
            }
        }
        
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Button(role: .destructive) {
                    let generator = UINotificationFeedbackGenerator()
                    deleteProject()
                    generator.notificationOccurred(.success)
                } label: {
                    Label("Delete Project", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .foregroundStyle(.primary)
            }
        }
        
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                if endDate < startDate {
                    viewModel?.showAlert.toggle()
                } else {
                    saveProject()
                    clearTextFields()
                    dismiss()
                }
            } label: {
                Image(systemName: "checkmark")
                    .foregroundStyle(.primary)
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
        
        // Ensure new projects are immediately persisted
        // In SwiftData, we can't check if an object is registered like in Core Data
        // Instead, we'll use a simple check based on whether the project has default values
        if project.projectName.isEmpty && project.artist.isEmpty {
            // This appears to be a new project, ensure it's inserted
            modelContext.insert(project)
            try? modelContext.save()
        }
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
        if delivered && dateDelivered == Date.distantPast {
              dateDelivered = Date.now
          }
        updateProjectStatus()
        saveProject()
    }
    
    private func handlePaidChange() {
        if paid && dateClosed == Date.distantFuture {
            dateClosed = Date.now
        }
        
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
    
    private func deleteProject() {
        modelContext.delete(project)
        try? modelContext.save()
        dismiss()
    }
    
    func saveProject() {
        let generator = UINotificationFeedbackGenerator()
        
        print("Save before: Project Client: \(project.client?.fullName ?? "NIL"), SelectedClient: \(selectedClient?.fullName ?? "NIL")")
        
        // Check for changes that would affect an invoice
        let projectNameChanged = project.projectName != projectName
        let clientChanged = project.client != selectedClient
        
        // Apply the changes
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
        
        // Flag invoice for update if invoice-relevant changes occurred
        if projectNameChanged || clientChanged {
            project.flagInvoiceForUpdate()
        }
        
        modelContext.insert(project)
        
        guard let _ = try? modelContext.save() else{
            print("😡 ERROR: Cannot save")
            return
        }
        generator.notificationOccurred(.success)
    }
    
    /// Auto-save project changes without feedback or validation - Apple's recommended approach
    private func autoSaveProjectChanges() {
        // Apply current field values to the project
        project.client = selectedClient
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
        
        // Ensure project is in context and save
        // In SwiftData, we don't need to check if object is registered
        // The insert operation is safe to call multiple times
        modelContext.insert(project)
        
        // Save quietly without feedback
        try? modelContext.save()
    }
    
    /// Debounced auto-save to reduce frequent saves (Apple's recommended performance optimization)
    private func debouncedAutoSave() {
        // Cancel previous save work item
        saveWorkItem?.cancel()
        
        // Create new work item with delay
        saveWorkItem = DispatchWorkItem {
            self.autoSaveProjectChanges()
        }
        
        // Execute after delay (0.5 seconds is Apple's suggested debounce time)
        if let workItem = saveWorkItem {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: workItem)
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
