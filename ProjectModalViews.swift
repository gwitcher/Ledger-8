//
//  ProjectModalViews.swift
//  Ledger 8
//
//  Created by Gabe Witcher on 10/24/25.
//

import SwiftUI
import SwiftData
import MapKit
import SwiftUIFontIcon

/*
 MODAL DESIGN ANALYSIS FOR LONG-PRESS CONTEXT
 
 Since these modals will be triggered by long-pressing on ProjectViews in sorted lists,
 we need to minimize redundant information that's already visible.
 
 INFORMATION ALREADY VISIBLE IN ProjectView:
 • Client name (or "Add Client" placeholder)
 • Project name
 • Start date (abbreviated format)
 • Total fee amount (in status color)
 • Media type
 • Items count OR invoice status (when delivered/closed)
 • Project icon (FontAwesome based on media type)
 
 INFORMATION NOT VISIBLE IN ProjectView:
 • Artist name ← PRIORITY
 • Status as text (only color is shown) ← PRIORITY  
 • Location with Maps integration ← PRIORITY
 • End date/duration ← HELPFUL
 • Detailed item breakdown ← MAIN PURPOSE
 • Notes ← OPTIONAL
 
 RECOMMENDED STYLE: Style 4 (Compact Summary)
 • Fixed header shows only NEW information (artist, status text, location)
 • Main content area focuses on detailed item breakdown
 • Avoids redundancy with ProjectView information
 • Optimal for quick glance during long-press interaction
 */

// MARK: - Project Modal Card Views

/// Modal card for open projects - shows additional details not visible in ProjectView
struct OpenProjectModalView: View {
    @Environment(\.dismiss) var dismiss
    let project: Project
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Compact Header - Only show NEW information not in ProjectView
                VStack(spacing: 12) {
                    HStack {
//                        RoundedRectangle(cornerRadius: 20, style: .continuous)
//                            .fill(Color.mintyFresh3.opacity(0.6))
//                            .frame(width: 44, height: 44)
//                            .overlay {
//                                FontIcon.text(.awesome5Solid(code: project.icon), fontsize: 24, color: Color.quiteClear2)
//                            }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            // Show artist if it exists (NOT visible in ProjectView)
                            if !project.projectName.isEmpty {
                                Text(project.projectName)
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .lineLimit(2)
                            } else {
                                Text(project.projectName.isEmpty ? "Untitled Project" : project.projectName)
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .lineLimit(2)
                            }
                            
                            if project.client != nil {
                                Text(project.client?.fullName ?? "")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .lineLimit(2)
                            } else {
                                Text("Add Client")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .lineLimit(2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        // Show location if available (NOT visible in ProjectView)
                        if let location = project.location {
                            Button(action: { openInMaps(location: location) }) {
                                VStack(spacing: 2) {
                                    Image(systemName: "location.fill")
                                        .font(.title2)
                                        .foregroundStyle(.blue)
                                    Text("Maps")
                                        .font(.caption2)
                                        .foregroundStyle(.blue)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                        
                        // Show status as TEXT (only color visible in ProjectView)
                        Text(project.status.rawValue.uppercased())
                            .font(.caption)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(project.status.statusColor.opacity(0.2))
                            .foregroundStyle(project.status.statusColor)
                            .clipShape(Capsule())
                    }
                    
                    // Show additional timing info if available
                    if project.endDateSelected && !Calendar.current.isDate(project.startDate, inSameDayAs: project.endDate) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("END DATE")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                                Text(project.endDate.formatted(date: .abbreviated, time: .omitted))
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("DURATION")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                                Text(formatDuration(from: project.startDate, to: project.endDate))
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                        }
                    }
                }
                .padding()
                .background(.regularMaterial)
                
                Divider()
                
                // Items List - The main content users want to see
                if let items = project.items, !items.isEmpty {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(items) { item in
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(item.name.isEmpty ? "Unnamed Item" : item.name)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                        Text(item.itemType.rawValue)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Text(item.fee.formatted(.currency(code: "USD")))
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .frame(width: 80, alignment: .trailing)
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                                
                                if item != items.last {
                                    Divider()
                                        .padding(.leading)
                                }
                            }
                        }
                    }
                } else {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "tray")
                            .font(.title2)
                            .foregroundStyle(.tertiary)
                        Text("No items added")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
    
    private func openInMaps(location: Spot) {
        let coordinate = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
        mapItem.name = location.name.isEmpty ? "Project Location" : location.name
        mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
    }
    
    private func formatDuration(from start: Date, to end: Date) -> String {
        let duration = end.timeIntervalSince(start)
        let hours = Int(duration) / 3600
        let minutes = Int(duration.truncatingRemainder(dividingBy: 3600)) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

/// Modal card for delivered projects without invoice - shows client info and create invoice option
struct DeliveredProjectModalView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext
    let project: Project
    @State private var isCreatingInvoice = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Project Header
                    projectHeader
                    
                    // Client Information
                    if let client = project.client {
                        clientInformation(client: client)
                    } else {
                        noClientView
                    }
                    
                    // Project Summary
                    projectSummary
                    
                    // Items Summary
                    if let items = project.items, !items.isEmpty {
                        itemsSummary(items: items)
                    }
                    
                    // Create Invoice Button
                    createInvoiceButton
                }
                .padding()
            }
            .navigationTitle("Ready to Invoice")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    @ViewBuilder
    private var projectHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title)
                    .foregroundStyle(.green)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Project Delivered")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.green)
                    
                    Text(project.projectName.isEmpty ? "Untitled Project" : project.projectName)
                        .font(.title2)
                        .fontWeight(.semibold)
                }
                
                Spacer()
            }
            
            Text("Delivered on \(project.dateDelivered.formatted(date: .abbreviated, time: .omitted))")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.green.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.green.opacity(0.3), lineWidth: 1)
        )
    }
    
    @ViewBuilder
    private func clientInformation(client: Client) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Client Information")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "person.circle")
                        .foregroundStyle(.blue)
                    Text(client.fullName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                if !client.attention.isEmpty {
                    HStack {
                        Image(systemName: "at")
                            .foregroundStyle(.secondary)
                        Text("Attn: \(client.attention)")
                            .font(.subheadline)
                    }
                }
                
                if hasValidBillingAddress(client: client) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: "location")
                                .foregroundStyle(.secondary)
                            Text("Billing Address")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            if !client.address.isEmpty {
                                Text(client.address)
                                    .font(.subheadline)
                            }
                            if !client.address2.isEmpty {
                                Text(client.address2)
                                    .font(.subheadline)
                            }
                            if !client.city.isEmpty || !client.state.isEmpty || !client.zip.isEmpty {
                                Text("\(client.city), \(client.state) \(client.zip)")
                                    .font(.subheadline)
                            }
                        }
                        .padding(.leading, 20)
                    }
                }
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
    
    @ViewBuilder
    private var noClientView: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.crop.circle.badge.exclamationmark")
                .font(.largeTitle)
                .foregroundStyle(.orange)
            
            Text("No Client Assigned")
                .font(.headline)
                .foregroundStyle(.orange)
            
            Text("Assign a client to generate an invoice")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.orange.opacity(0.3), lineWidth: 1)
        )
    }
    
    @ViewBuilder
    private var projectSummary: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Project Summary")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack {
                Image(systemName: "calendar.badge.clock")
                    .foregroundStyle(.secondary)
                Text("Started: \(project.startDate.formatted(date: .abbreviated, time: .omitted))")
                    .font(.subheadline)
            }
            
            if !project.artist.isEmpty {
                HStack {
                    Image(systemName: "music.mic")
                        .foregroundStyle(.secondary)
                    Text("Artist: \(project.artist)")
                        .font(.subheadline)
                }
            }
            
            HStack {
                Image(systemName: getMediaIcon(for: project.mediaType))
                    .foregroundStyle(.secondary)
                Text("Type: \(project.mediaType.rawValue)")
                    .font(.subheadline)
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
    
    @ViewBuilder
    private func itemsSummary(items: [Item]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Items Summary")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(items.count) item\(items.count == 1 ? "" : "s")")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            // Top 3 items or all if 3 or fewer
            let displayItems = Array(items.prefix(3))
            ForEach(displayItems) { item in
                HStack {
                    Text(item.name.isEmpty ? "Unnamed Item" : item.name)
                        .font(.subheadline)
                    
                    Spacer()
                    
                    Text(item.fee.formatted(.currency(code: "USD")))
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }
            
            if items.count > 3 {
                Text("+ \(items.count - 3) more item\(items.count - 3 == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Divider()
            
            HStack {
                Text("Total Fee")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text(project.calculateFeeTotal(items: items).formatted(.currency(code: "USD")))
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(.blue)
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
    
    @ViewBuilder
    private var createInvoiceButton: some View {
        Button(action: createInvoice) {
            HStack {
                if isCreatingInvoice {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "doc.text.fill")
                }
                
                Text(isCreatingInvoice ? "Creating Invoice..." : "Create Invoice")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(.blue)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(isCreatingInvoice || project.client == nil)
    }
    
    private func createInvoice() {
        guard let client = project.client else {
            errorMessage = "Please assign a client to this project before creating an invoice."
            showError = true
            return
        }
        
        guard let items = project.items, !items.isEmpty else {
            errorMessage = "Cannot create an invoice for a project with no items."
            showError = true
            return
        }
        
        isCreatingInvoice = true
        
        Task {
            do {
                // You would replace this with your actual invoice creation logic
                // For now, just simulating the process
                try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                
                await MainActor.run {
                    isCreatingInvoice = false
                    dismiss()
                    // Handle successful invoice creation
                }
            } catch {
                await MainActor.run {
                    isCreatingInvoice = false
                    errorMessage = "Failed to create invoice: \(error.localizedDescription)"
                    showError = true
                }
            }
        }
    }
    
    private func hasValidBillingAddress(client: Client) -> Bool {
        !client.address.isEmpty || !client.city.isEmpty || !client.state.isEmpty
    }
}

/// Modal card for delivered/paid projects with invoice - shows PDF preview
struct InvoicedProjectModalView: View {
    @Environment(\.dismiss) var dismiss
    let project: Project
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if let invoice = project.invoice {
                    invoiceContent(invoice: invoice)
                } else {
                    noInvoiceView
                }
            }
            .navigationTitle("Invoice")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                if let invoice = project.invoice, let pdfURL = invoice.url {
                    ToolbarItem(placement: .topBarTrailing) {
                        ShareLink(item: pdfURL) {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
    
    @ViewBuilder
    private func invoiceContent(invoice: Invoice) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Invoice Header Info
            invoiceHeader(invoice: invoice)
            
            // PDF Preview or Content
            if let pdfURL = invoice.url {
                pdfPreview(url: pdfURL)
            } else {
                noPDFView(invoice: invoice)
            }
        }
    }
    
    @ViewBuilder
    private func invoiceHeader(invoice: Invoice) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Invoice #\(invoice.number)")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text(project.projectName.isEmpty ? "Untitled Project" : project.projectName)
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // Status Badge
                HStack(spacing: 8) {
                    Circle()
                        .fill(project.status == .closed ? .green : .orange)
                        .frame(width: 8, height: 8)
                    
                    Text(project.status.rawValue)
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.regularMaterial, in: Capsule())
            }
            
            if let client = project.client {
                HStack {
                    Image(systemName: "person.circle")
                        .foregroundStyle(.blue)
                    Text(client.fullName)
                        .font(.subheadline)
                }
            }
            
            if let items = project.items, !items.isEmpty {
                HStack {
                    Image(systemName: "dollarsign.circle")
                        .foregroundStyle(.green)
                    Text(project.calculateFeeTotal(items: items).formatted(.currency(code: "USD")))
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
    
    @ViewBuilder
    private func pdfPreview(url: URL) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Invoice Preview")
                .font(.headline)
                .fontWeight(.medium)
                .padding(.horizontal)
            
            // Use the existing PDFKit view from ShowInvoice.swift
            PDFKitView(url: url)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
    }
    
    @ViewBuilder
    private func noPDFView(invoice: Invoice) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.questionmark")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            
            Text("PDF Not Available")
                .font(.headline)
                .foregroundStyle(.secondary)
            
            VStack(spacing: 8) {
                Text("Invoice #\(invoice.number)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("The PDF file may have been moved or deleted.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
    
    @ViewBuilder
    private var noInvoiceView: some View {
        ContentUnavailableView(
            "No Invoice",
            systemImage: "doc.badge.plus",
            description: Text("This project doesn't have an associated invoice.")
        )
    }
}

// MARK: - Supporting Views

/// Minimal item row view for clean display
struct MinimalItemRowView: View {
    let item: Item
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name.isEmpty ? "Unnamed Item" : item.name)
                    .font(.subheadline)
                
                Text(item.itemType.rawValue)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Text(item.fee.formatted(.currency(code: "USD")))
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

/// Reusable item row view for displaying items in lists
struct ItemRowView: View {
    let item: Item
    
    var body: some View {
        HStack {
            Image(systemName: getItemIcon(for: item.itemType))
                .font(.subheadline)
                .foregroundStyle(.blue)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name.isEmpty ? "Unnamed Item" : item.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(item.itemType.rawValue)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Text(item.fee.formatted(.currency(code: "USD")))
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 8))
    }
    
    private func getItemIcon(for itemType: ItemType) -> String {
        switch itemType {
        case .session: return "music.note"
        case .overdub: return "waveform"
        case .demo: return "music.note"
        case .rehearsal: return "clock"
        case .concert: return "person.3"
        case .tour: return "bus"
        case .perDiem: return "dollarsign.circle"
        case .reimbursement: return "arrow.triangle.2.circlepath.circle"
        case .arrangement: return "book.pages"
        case .score: return "music.quarternote.3"
        case .production: return "slider.horizontal.3"
        case .rental: return "doc.text"
        case .lesson: return "graduationcap"
        case .other: return "questionmark.circle"
        }
    }
}

// MARK: - Helper Functions

/// Gets the appropriate system icon for media types
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

// MARK: - Preview Wrapper View

/// Main view to demonstrate and test all three modal configurations
struct ProjectModalDemo: View {
    @State private var showOpenModal = false
    @State private var showDeliveredModal = false
    @State private var showInvoicedModal = false
    
    // Sample projects for preview
    private let openProject = Project(
        projectName: "Album Recording Session",
        artist: "The Sample Band",
        startDate: Date(),
        endDate: Calendar.current.date(byAdding: .hour, value: 4, to: Date())!,
        status: .open,
        mediaType: .recording,
        delivered: false,
        paid: false
    )
    
    private let deliveredProject = Project(
        projectName: "Commercial Jingle",
        artist: "Brand X",
        startDate: Calendar.current.date(byAdding: .day, value: -5, to: Date())!,
        endDate: Calendar.current.date(byAdding: .day, value: -5, to: Date())!,
        status: .delivered,
        mediaType: .recording,
        delivered: true,
        paid: false,
        dateDelivered: Calendar.current.date(byAdding: .day, value: -1, to: Date())!
    )
    
    private let invoicedProject = Project(
        projectName: "Film Score",
        artist: "Movie Studio",
        startDate: Calendar.current.date(byAdding: .day, value: -10, to: Date())!,
        endDate: Calendar.current.date(byAdding: .day, value: -8, to: Date())!,
        status: .closed,
        mediaType: .film,
        delivered: true,
        paid: true,
        dateDelivered: Calendar.current.date(byAdding: .day, value: -3, to: Date())!,
        dateClosed: Date()
    )
    
    var body: some View {
        NavigationView {
            List {
                Section("Project Modal Examples") {
                    Button("Open Project Modal") {
                        showOpenModal = true
                    }
                    
                    Button("Delivered Project Modal") {
                        showDeliveredModal = true
                    }
                    
                    Button("Invoiced Project Modal") {
                        showInvoicedModal = true
                    }
                }
            }
            .navigationTitle("Modal Demo")
        }
        .sheet(isPresented: $showOpenModal) {
            OpenProjectModalView(project: openProject)
        }
        .sheet(isPresented: $showDeliveredModal) {
            DeliveredProjectModalView(project: deliveredProject)
        }
        .sheet(isPresented: $showInvoicedModal) {
            InvoicedProjectModalView(project: invoicedProject)
        }
    }
}

// MARK: - Style Variant 1: App-Consistent (Matches ProjectView and ProjectDetailView)
struct Style1_OpenProjectModalView: View {
    @Environment(\.dismiss) var dismiss
    let project: Project
    
    var body: some View {
        NavigationStack {
            Form {
                // Project Header Section
                Section {
                    HStack(spacing: 16) {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.mintyFresh3.opacity(0.6))
                            .frame(width: 60, height: 60)
                            .overlay {
                                FontIcon.text(.awesome5Solid(code: project.icon), fontsize: 28, color: Color.quiteClear2)
                            }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(project.projectName.isEmpty ? "Untitled Project" : project.projectName)
                                .font(.headline)
                                .fontWeight(.bold)
                                .lineLimit(2)
                            
                            if !project.artist.isEmpty {
                                Text(project.artist)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
                
                // Project Info Section  
                Section("Project Details") {
                    if let client = project.client {
                        LabeledContent("Client") {
                            Text(client.fullName)
                                .foregroundStyle(.primary)
                        }
                    }
                    
                    LabeledContent("Status") {
                        Text(project.status.rawValue)
                            .font(.subheadline)
                            .foregroundStyle(project.status.statusColor)
                            .fontWeight(.medium)
                    }
                    
                    LabeledContent("Media Type") {
                        Text(project.mediaType.rawValue)
                    }
                    
                    LabeledContent("Start Date") {
                        Text(project.startDate.formatted(date: .abbreviated, time: .shortened))
                    }
                    
                    if let location = project.location {
                        Button(action: { openInMaps(location: location) }) {
                            LabeledContent("Location") {
                                HStack {
                                    Text(locationDisplayName(location: location))
                                        .foregroundStyle(.blue)
                                    Image(systemName: "arrow.up.right.square")
                                        .font(.caption)
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                // Items Section
                if let items = project.items, !items.isEmpty {
                    Section("Items (\(items.count))") {
                        ForEach(items) { item in
                            Style1_ItemRow(item: item)
                        }
                        
                        LabeledContent("Total") {
                            Text(project.calculateFeeTotal(items: items).formatted(.currency(code: "USD")))
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundStyle(project.status.statusColor)
                        }
                    }
                } else {
                    Section("Items") {
                        Text("No items added")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
    
    private func locationDisplayName(location: Spot) -> String {
        if !location.name.isEmpty {
            return location.name
        } else if !location.address.isEmpty {
            return location.address
        }
        return "Location"
    }
    
    private func openInMaps(location: Spot) {
        let coordinate = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
        mapItem.name = location.name.isEmpty ? "Project Location" : location.name
        mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
    }
}

struct Style1_ItemRow: View {
    let item: Item
    
    var body: some View {
        LabeledContent {
            Text(item.fee.formatted(.currency(code: "USD")))
                .fontWeight(.medium)
        } label: {
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name.isEmpty ? "Unnamed Item" : item.name)
                    .font(.subheadline)
                Text(item.itemType.rawValue)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Style Variant 2: Card-Based Design
struct Style2_OpenProjectModalView: View {
    @Environment(\.dismiss) var dismiss
    let project: Project
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Project Header Card
                    VStack(spacing: 12) {
                        HStack {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.mintyFresh3.opacity(0.6))
                                .frame(width: 50, height: 50)
                                .overlay {
                                    FontIcon.text(.awesome5Solid(code: project.icon), fontsize: 24, color: Color.quiteClear2)
                                }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(project.projectName.isEmpty ? "Untitled Project" : project.projectName)
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                if !project.artist.isEmpty {
                                    Text(project.artist)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            Text(project.status.rawValue)
                                .font(.caption)
                                .fontWeight(.medium)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(project.status.statusColor.opacity(0.2))
                                .foregroundStyle(project.status.statusColor)
                                .clipShape(Capsule())
                        }
                        
                        if let client = project.client {
                            HStack {
                                Image(systemName: "person.circle")
                                    .foregroundStyle(.blue)
                                Text(client.fullName)
                                    .font(.subheadline)
                                Spacer()
                            }
                        }
                        
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundStyle(.secondary)
                            Text(project.startDate.formatted(date: .abbreviated, time: .shortened))
                                .font(.subheadline)
                            Spacer()
                            Text(project.mediaType.rawValue)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                    
                    // Items Card
                    if let items = project.items, !items.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Items")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            ForEach(items) { item in
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(item.name.isEmpty ? "Unnamed Item" : item.name)
                                            .font(.subheadline)
                                        Text(item.itemType.rawValue)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Text(item.fee.formatted(.currency(code: "USD")))
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                }
                                .padding(.vertical, 2)
                            }
                            
                            Divider()
                            
                            HStack {
                                Text("Total")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                Spacer()
                                Text(project.calculateFeeTotal(items: items).formatted(.currency(code: "USD")))
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundStyle(project.status.statusColor)
                            }
                        }
                        .padding()
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                    }
                }
                .padding()
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Style Variant 3: Minimal List Style
struct Style3_OpenProjectModalView: View {
    @Environment(\.dismiss) var dismiss
    let project: Project
    
    var body: some View {
        NavigationStack {
            List {
                // Header
                HStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.mintyFresh3.opacity(0.6))
                        .frame(width: 36, height: 36)
                        .overlay {
                            FontIcon.text(.awesome5Solid(code: project.icon), fontsize: 18, color: Color.quiteClear2)
                        }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(project.projectName.isEmpty ? "Untitled Project" : project.projectName)
                            .font(.headline)
                            .fontWeight(.semibold)
                        if !project.artist.isEmpty {
                            Text(project.artist)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Spacer()
                }
                .listRowSeparator(.hidden)
                
                // Quick Info
                if let client = project.client {
                    HStack {
                        Text("Client")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(client.fullName)
                    }
                }
                
                HStack {
                    Text("Status")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(project.status.rawValue)
                        .foregroundStyle(project.status.statusColor)
                        .fontWeight(.medium)
                }
                
                HStack {
                    Text("Started")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(project.startDate.formatted(date: .abbreviated, time: .omitted))
                }
                
                // Items
                if let items = project.items, !items.isEmpty {
                    Section("Items") {
                        ForEach(items) { item in
                            HStack {
                                Text(item.name.isEmpty ? "Unnamed Item" : item.name)
                                    .font(.subheadline)
                                Spacer()
                                Text(item.fee.formatted(.currency(code: "USD")))
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                        }
                        
                        HStack {
                            Text("Total")
                                .fontWeight(.semibold)
                            Spacer()
                            Text(project.calculateFeeTotal(items: items).formatted(.currency(code: "USD")))
                                .fontWeight(.bold)
                                .foregroundStyle(project.status.statusColor)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Style Variant 4: Compact Summary Style (Optimized for Long-Press)
struct Style4_OpenProjectModalView: View {
    @Environment(\.dismiss) var dismiss
    let project: Project
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Compact Header - Only show NEW information
                VStack(spacing: 12) {
                    HStack {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(Color.mintyFresh3.opacity(0.6))
                            .frame(width: 44, height: 44)
                            .overlay {
                                FontIcon.text(.awesome5Solid(code: project.icon), fontsize: 24, color: Color.quiteClear2)
                            }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            // Only show artist if it exists (NOT visible in ProjectView)
                            if !project.artist.isEmpty {
                                Text(project.artist)
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .lineLimit(2)
                            } else {
                                Text(project.projectName.isEmpty ? "Untitled Project" : project.projectName)
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .lineLimit(2)
                            }
                            
                            // Show status as TEXT (only color visible in ProjectView)
                            Text(project.status.rawValue.uppercased())
                                .font(.caption)
                                .fontWeight(.semibold)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(project.status.statusColor.opacity(0.2))
                                .foregroundStyle(project.status.statusColor)
                                .clipShape(Capsule())
                        }
                        
                        Spacer()
                        
                        // Show location if available (NOT visible in ProjectView)
                        if let location = project.location {
                            Button(action: { openInMaps(location: location) }) {
                                VStack(spacing: 2) {
                                    Image(systemName: "location.fill")
                                        .font(.title2)
                                        .foregroundStyle(.blue)
                                    Text("Maps")
                                        .font(.caption2)
                                        .foregroundStyle(.blue)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    
                    // Timing info (show end date if different from start, show duration)
                    HStack(spacing: 20) {
                        if project.endDateSelected && !Calendar.current.isDate(project.startDate, inSameDayAs: project.endDate) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("END DATE")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                                Text(project.endDate.formatted(date: .abbreviated, time: .omitted))
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                        }
                        
                        if project.endDateSelected {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("DURATION")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                                Text(formatDuration(from: project.startDate, to: project.endDate))
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                        }
                        
                        Spacer()
                    }
                }
                .padding()
                .background(.regularMaterial)
                
                Divider()
                
                // Items List - The main content users want to see
                if let items = project.items, !items.isEmpty {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(items) { item in
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(item.name.isEmpty ? "Unnamed Item" : item.name)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                        Text(item.itemType.rawValue)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Text(item.fee.formatted(.currency(code: "USD")))
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .frame(width: 80, alignment: .trailing)
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                                
                                if item != items.last {
                                    Divider()
                                        .padding(.leading)
                                }
                            }
                        }
                    }
                } else {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "tray")
                            .font(.title2)
                            .foregroundStyle(.tertiary)
                        Text("No items added")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
    
    private func openInMaps(location: Spot) {
        let coordinate = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
        mapItem.name = location.name.isEmpty ? "Project Location" : location.name
        mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
    }
    
    private func formatDuration(from start: Date, to end: Date) -> String {
        let duration = end.timeIntervalSince(start)
        let hours = Int(duration) / 3600
        let minutes = Int(duration.truncatingRemainder(dividingBy: 3600)) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - Style Variant 5: Visual Hierarchy Style
struct Style5_OpenProjectModalView: View {
    @Environment(\.dismiss) var dismiss
    let project: Project
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Hero Section
                    HStack(spacing: 16) {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.mintyFresh3.opacity(0.6))
                            .frame(width: 64, height: 64)
                            .overlay {
                                FontIcon.text(.awesome5Solid(code: project.icon), fontsize: 32, color: Color.quiteClear2)
                            }
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text(project.projectName.isEmpty ? "Untitled Project" : project.projectName)
                                .font(.title2)
                                .fontWeight(.bold)
                                .lineLimit(2)
                            
                            if !project.artist.isEmpty {
                                Text(project.artist)
                                    .font(.headline)
                                    .foregroundStyle(.secondary)
                                    .fontWeight(.medium)
                            }
                            
                            HStack(spacing: 12) {
                                Text(project.status.rawValue.uppercased())
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(project.status.statusColor.opacity(0.2))
                                    .foregroundStyle(project.status.statusColor)
                                    .clipShape(Capsule())
                                
                                Text(project.mediaType.rawValue.uppercased())
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(.quaternary)
                                    .foregroundStyle(.secondary)
                                    .clipShape(Capsule())
                            }
                        }
                        
                        Spacer()
                    }
                    
                    // Project Details Grid
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        if let client = project.client {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("CLIENT")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.tertiary)
                                Text(client.fullName)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .lineLimit(2)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 12))
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("START DATE")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(.tertiary)
                            Text(project.startDate.formatted(date: .abbreviated, time: .shortened))
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 12))
                    }
                    
                    // Items Section
                    if let items = project.items, !items.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("ITEMS")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.tertiary)
                                
                                Spacer()
                                
                                Text("\(items.count) item\(items.count == 1 ? "" : "s")")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            VStack(spacing: 8) {
                                ForEach(items) { item in
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(item.name.isEmpty ? "Unnamed Item" : item.name)
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                            Text(item.itemType.rawValue)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        
                                        Spacer()
                                        
                                        Text(item.fee.formatted(.currency(code: "USD")))
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 8))
                                }
                            }
                            
                            HStack {
                                Text("TOTAL")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                
                                Spacer()
                                
                                Text(project.calculateFeeTotal(items: items).formatted(.currency(code: "USD")))
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundStyle(project.status.statusColor)
                            }
                            .padding()
                            .background(project.status.statusColor.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                        }
                    } else {
                        VStack(spacing: 8) {
                            Image(systemName: "tray")
                                .font(.title2)
                                .foregroundStyle(.tertiary)
                            Text("No items added")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding()
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Demo View with All 5 Styles
struct StyleComparisonDemo: View {
    @State private var selectedStyle = 4 // Default to Style 4 (recommended)
    @State private var showModal = false
    
    // Sample project for testing
    private let sampleProject = Project(
        projectName: "Album Recording Session",
        artist: "The Sample Band",
        startDate: Date(),
        endDate: Calendar.current.date(byAdding: .hour, value: 4, to: Date())!,
        status: .open,
        mediaType: .recording,
        delivered: false,
        paid: false
    )
    
    var body: some View {
        NavigationView {
            List {
                Section("Recommended Style for Long-Press Modals") {
                    Button("Style 4: Compact Summary ⭐") {
                        selectedStyle = 4
                        showModal = true
                    }
                    .foregroundStyle(.blue)
                    .fontWeight(.semibold)
                }
                
                Section("Alternative Styles") {
                    ForEach([1, 2, 3, 5], id: \.self) { styleNumber in
                        Button("Style \(styleNumber): \(getStyleDescription(styleNumber))") {
                            selectedStyle = styleNumber
                            showModal = true
                        }
                    }
                }
                
                Section("Style Analysis") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("✅ Style 4: Compact Summary")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.green)
                        Text("• Shows only NEW info (artist, status text, location)")
                            .font(.caption2)
                        Text("• Fixed header prevents scrolling redundancy")
                            .font(.caption2)
                        Text("• Detailed items list in scrollable area")
                            .font(.caption2)
                        
                        Divider()
                        
                        Text("❌ Other Styles:")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.orange)
                        Text("• Repeat info already visible in ProjectView")
                            .font(.caption2)
                        Text("• Too verbose for quick glance interaction")
                            .font(.caption2)
                    }
                    .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Modal Style Comparison")
        }
        .sheet(isPresented: $showModal) {
            switch selectedStyle {
            case 1:
                Style1_OpenProjectModalView(project: sampleProject)
            case 2:
                Style2_OpenProjectModalView(project: sampleProject)
            case 3:
                Style3_OpenProjectModalView(project: sampleProject)
            case 4:
                Style4_OpenProjectModalView(project: sampleProject)
            case 5:
                Style5_OpenProjectModalView(project: sampleProject)
            default:
                Style4_OpenProjectModalView(project: sampleProject)
            }
        }
    }
    
    private func getStyleDescription(_ style: Int) -> String {
        switch style {
        case 1: return "Form-based (too verbose)"
        case 2: return "Card-based (redundant info)"
        case 3: return "Minimal List (still repetitive)"
        case 4: return "Compact Summary (optimal)"
        case 5: return "Visual Hierarchy (information overload)"
        default: return "Unknown"
        }
    }
}

// MARK: - Previews

#Preview("Style Comparison Demo") {
    StyleComparisonDemo()
        .modelContainer(for: Project.self, inMemory: true)
}

#Preview("Optimized for Long-Press") {
    let project = Project(
        projectName: "Recording Session",
        artist: "Test Artist",
        status: .open,
        
    )
    
    return OpenProjectModalView(project: project)
        .modelContainer(for: Project.self, inMemory: true)
}

#Preview("Style 2 - Card-based") {
    let project = Project(
        projectName: "Recording Session", 
        artist: "Test Artist",
        status: .open
    )
    
    return Style2_OpenProjectModalView(project: project)
        .modelContainer(for: Project.self, inMemory: true)
}

#Preview("Style 3 - Minimal List") {
    let project = Project(
        projectName: "Recording Session",
        artist: "Test Artist", 
        status: .open
    )
    
    return Style3_OpenProjectModalView(project: project)
        .modelContainer(for: Project.self, inMemory: true)
}
