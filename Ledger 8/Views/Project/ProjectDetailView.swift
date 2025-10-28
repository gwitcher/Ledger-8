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
    @Environment(NavigationCoordinator.self) private var navigationCoordinator
    
    @State private var viewModel: ProjectDetailViewModel
    var customDismissAction: (() -> Void)? = nil
    
    // UI-only state that doesn't belong in ViewModel
    @State private var clientSelectSheetIsPresented = false
    @State private var scrollProxy: ScrollViewProxy?
    
    @FocusState private var focusField: ProjectField?
    
    init(project: Project) {
        self._viewModel = State(initialValue: ProjectDetailViewModel(project: project))
    }
    
    // Helper function to get system icons for media types
    private func getMediaIcon(for mediaType: MediaType) -> String {
        return viewModel.getMediaIcon(for: mediaType)
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
                    // Data is already loaded in ViewModel init
                }
            }
            .alert(isPresented: $viewModel.showAlert) {
                Alert(
                    title: Text("Cannot Save Project"),
                    message: Text(viewModel.dateAlertMessage),
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
                ClientSelectView(selectedClient: $viewModel.selectedClient)
            }
            .onChange(of: viewModel.startDate) { _, _ in
                viewModel.handleStartDateChange()
            }
            .onChange(of: viewModel.endDate) { _, _ in
                viewModel.handleEndDateChange()
            }
            .onChange(of: viewModel.selectedTemplateProject) { _, _ in
                viewModel.handleTemplateProjectChange()
            }
            .onChange(of: viewModel.selectedClient) { _, _ in
                viewModel.handleClientChange()
            }
            // Sync FocusState with ViewModel
            .onChange(of: focusField) { _, newValue in
                viewModel.focusField = newValue
                viewModel.handleProjectFieldFocusChange()
            }
            .onChange(of: viewModel.focusField) { _, newValue in
                focusField = newValue
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
                    
                    if let client = viewModel.selectedClient {
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
            
            LocationView(selectedLocation: $viewModel.selectedLocation)
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
                TextField("", text: $viewModel.projectName)
                    .autocorrectionDisabled()
                    .submitLabel(.next)
                    .focused($focusField, equals: .project)
                    .onSubmit {
                        focusField = .artist
                    }
                    .onChange(of: focusField) { _, _ in
                        viewModel.focusField = focusField
                        viewModel.handleProjectFieldFocusChange()
                    }
                projectSuggestionsToggleButton
            }
        } label: {
            Text("Project").foregroundStyle(.primary)
        }
    }
    
    @ViewBuilder
    private var projectSuggestionsToggleButton: some View {
        if let client = viewModel.selectedClient,
           let clientProjects = client.project,
           !clientProjects.isEmpty {
            Button {
                viewModel.toggleProjectSuggestions()
            } label: {
                Image(systemName: viewModel.showProjectSuggestions ? "chevron.up.circle.fill" : "chevron.down.circle")
                    .foregroundStyle(.blue)
                    .font(.system(size: 16))
            }
            .buttonStyle(.plain)
        }
    }
    
    @ViewBuilder
    private var projectSuggestionsList: some View {
        if viewModel.showProjectSuggestions,
           let client = viewModel.selectedClient,
           let clientProjects = client.project,
           !clientProjects.isEmpty {
            let suggestions = viewModel.sortedProjectsByFrequency(clientProjects)
            
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(suggestions) { project in
                        ProjectSuggestionRow(project: project) {
                            viewModel.selectedTemplateProject = project
                            focusField = nil
                            withAnimation(.easeInOut(duration: 0.2)) {
                                viewModel.showProjectSuggestions = false
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
            TextField("", text: $viewModel.artist)
                .autocorrectionDisabled()
                .focused($focusField, equals: .artist)
                .onSubmit {
                    focusField = nil
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
                            viewModel.showEndTimePicker = false
                            viewModel.showEndDatePicker = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + datePickerExpandDelay) {
                                if viewModel.showStartTimePicker && !viewModel.showStartDatePicker {
                                    viewModel.showStartTimePicker = false
                                    viewModel.showStartDatePicker = false
                                } else {
                                    viewModel.showStartDatePicker.toggle()
                                }
                            }
                        }
                    }
                
                Spacer()
                
                Button("\(viewModel.startDate.formatted(date: .abbreviated, time: .omitted))") {
                    focusField = nil // Dismiss keyboard
                    DispatchQueue.main.asyncAfter(deadline: .now() + datePickerExpandDelay) {
                        withAnimation(.easeInOut(duration: datePickerExpandDuration)){
                            viewModel.showEndTimePicker = false
                            viewModel.showEndDatePicker = false
                            if viewModel.showStartTimePicker {
                                viewModel.showStartTimePicker = false
                            }
                            viewModel.showStartDatePicker.toggle()
                        }
                    }
                }
                .buttonStyle(.bordered)
                .foregroundStyle(.primary)
                
                Button("\(viewModel.startDate.formatted(date: .omitted, time: .shortened))") {
                    focusField = nil // Dismiss keyboard
                    DispatchQueue.main.asyncAfter(deadline: .now() + datePickerExpandDelay) {
                        withAnimation(.easeInOut(duration: datePickerExpandDuration)){
                            viewModel.showEndTimePicker = false
                            viewModel.showEndDatePicker = false
                            if viewModel.showStartDatePicker {
                                viewModel.showStartDatePicker = false
                            }
                            viewModel.showStartTimePicker.toggle()
                        }
                    }
                }
                .buttonStyle(.bordered)
                .foregroundStyle(.primary)
            }
            
            if viewModel.showStartDatePicker {
                VStack {
                    DatePicker("", selection: $viewModel.startDate, displayedComponents: .date)
                        .datePickerStyle(.graphical)
                        .focused($focusField, equals: .startDate)
                }
                .padding(.vertical, 12)
                .id("startDatePicker")
            }
            
            if viewModel.showStartTimePicker {
                VStack {
                    DatePicker("", selection: $viewModel.startDate, displayedComponents: .hourAndMinute)
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
                            viewModel.showStartTimePicker = false
                            viewModel.showStartDatePicker = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + datePickerExpandDelay) {
                                if viewModel.showEndTimePicker && !viewModel.showEndDatePicker {
                                    viewModel.showEndTimePicker = false
                                    viewModel.showEndDatePicker = false
                                } else {
                                    viewModel.showEndDatePicker.toggle()
                                }
                            }
                        }
                    }
                
                Spacer()
                
                Button("\(viewModel.endDate.formatted(date: .abbreviated, time: .omitted))") {
                    focusField = nil // Dismiss keyboard
                    DispatchQueue.main.asyncAfter(deadline: .now() + datePickerExpandDelay) {
                        withAnimation(.easeInOut(duration: datePickerExpandDuration)){
                            viewModel.showStartTimePicker = false
                            viewModel.showStartDatePicker = false
                            if viewModel.showEndTimePicker {
                                viewModel.showEndTimePicker = false
                            }
                            viewModel.showEndDatePicker.toggle()
                        }
                    }
                }
                .buttonStyle(.bordered)
                .foregroundStyle(.primary)
                
                Button("\(viewModel.endDate.formatted(date: .omitted, time: .shortened))") {
                    focusField = nil // Dismiss keyboard
                    DispatchQueue.main.asyncAfter(deadline: .now() + datePickerExpandDelay) {
                        withAnimation(.easeInOut(duration: datePickerExpandDuration)){
                            viewModel.showStartTimePicker = false
                            viewModel.showStartDatePicker = false
                            if viewModel.showEndDatePicker {
                                viewModel.showEndDatePicker = false
                            }
                            viewModel.showEndTimePicker.toggle()
                        }
                    }
                }
                .buttonStyle(.bordered)
                .foregroundStyle(.primary)
            }
            
            if viewModel.showEndDatePicker {
                VStack {
                    DatePicker("", selection: $viewModel.endDate, displayedComponents: .date)
                        .datePickerStyle(.graphical)
                        .focused($focusField, equals: .endDate)
                }
                .padding(.vertical, 12)
                .id("endDatePicker")
            }
            
            if viewModel.showEndTimePicker {
                VStack {
                    DatePicker("", selection: $viewModel.endDate, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.wheel)
                        .focused($focusField, equals: .endDate)
                }
                .padding(.vertical, 12)
                .id("endTimePicker")
            }
            
            
        }
        .onChange(of: focusField) { oldValue, newValue in
            if newValue != .endDate && newValue != .startDate {
                viewModel.showStartDatePicker = false
                viewModel.showStartTimePicker = false
                viewModel.showEndDatePicker = false
                viewModel.showEndTimePicker = false
                
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
        .onChange(of: viewModel.showStartDatePicker) { _, isShowing in
            if isShowing {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    scrollToProjectInfo()
                }
            } else {
                checkAndScrollToTopIfAllPickersClosed()
            }
        }
        .onChange(of: viewModel.showStartTimePicker) { _, isShowing in
            if isShowing {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    scrollToProjectInfo()
                }
            } else {
                checkAndScrollToTopIfAllPickersClosed()
            }
        }
        .onChange(of: viewModel.showEndDatePicker) { _, isShowing in
            if isShowing {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    scrollToProjectInfo()
                }
            } else {
                checkAndScrollToTopIfAllPickersClosed()
            }
        }
        .onChange(of: viewModel.showEndTimePicker) { _, isShowing in
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
            Picker("Media", selection: $viewModel.mediaType) {
                ForEach(MediaType.allCases) { type in
                    Text(type.rawValue)
                }
            }
        }
    }
    
    @ViewBuilder
    private var itemsSection: some View {
        Section {
            if let items = viewModel.project.items, !items.isEmpty {
                NavigationLink {
                    EnhancedProjectItemListView(project: viewModel.project)
                } label: {
                    HStack {
                        Image(systemName: "list.bullet")
                            .foregroundStyle(.blue)
                        Text("Items: \(items.count)")
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            Text(viewModel.project.calculateFeeTotal(items: items).formatted(.currency(code: "USD")))
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                    }
                }
            }
            
            NavigationLink {
                ItemDetailView(project: viewModel.project)
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
        if viewModel.statusChange {
            Section("Invoice") {
                if viewModel.project.invoice != nil {
                    VStack(alignment: .leading, spacing: 8) {
                        InvoiceLinkView(project: viewModel.project)
                        
                        invoiceWarningAlert
                        
                    }
                } else {
                    AddInvoiceView(project: viewModel.project)
                }
            }
        }
    }
    
    @ViewBuilder
    private var invoiceWarningAlert: some View {
        
        // Warning message when invoice needs update
        if viewModel.project.invoiceNeedsUpdate {
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
            TextField("", text: $viewModel.notes, axis: .vertical)
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
        .onChange(of: viewModel.delivered) { _, _ in
            viewModel.handleDeliveredChange()
        }
        .onChange(of: viewModel.paid) { _, _ in
            viewModel.handlePaidChange()
        }
    }
    
    @ViewBuilder
    private var deliveredToggle: some View {
        Toggle(isOn: $viewModel.delivered) {
            if !viewModel.delivered {
                Text("Delivered")
            } else {
                HStack {
                    Text("Delivered")
                    DatePicker("", selection: $viewModel.dateDelivered, displayedComponents: [.date])
                        .datePickerStyle(.automatic)
                        .padding(.horizontal)
                }
            }
        }
        .tint(viewModel.paid ? .green : .red)
    }
    
    @ViewBuilder
    private var paidToggle: some View {
        Toggle(isOn: $viewModel.paid) {
            if !viewModel.paid {
                Text("Paid")
            } else {
                HStack {
                    Text("Paid")
                    DatePicker("", selection: $viewModel.dateClosed, displayedComponents: [.date])
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
            Button {
                if viewModel.validateAndPrepareForSave() {
                    viewModel.saveProject(to: modelContext, withFeedback: true)
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
    
    // MARK: - Helper Methods (UI-focused)
    
    private func checkAndScrollToTopIfAllPickersClosed() {
        // Check if all date pickers are closed
        if !viewModel.showStartDatePicker && !viewModel.showStartTimePicker && !viewModel.showEndDatePicker && !viewModel.showEndTimePicker {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                scrollToTop()
            }
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
    
    func clearTextFields() {
        viewModel.clearTextFields()
    }
    
}


#Preview {
    ProjectDetailView(project: Project(projectName: "", startDate: Date.now, items: [Item]()))
        .modelContainer(for: Project.self, inMemory: true)
}

