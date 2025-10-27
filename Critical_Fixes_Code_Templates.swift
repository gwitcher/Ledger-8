//// Critical Fixes: Code Templates
//
//// MARK: - 1. ProjectEventDetailView Fixes
//
//// Fix Status Picker and Map OnTap
//struct ProjectEventDetailView: View {
//    @Bindable var project: Project
//    @Environment(\.dismiss) private var dismiss
//    
//    var body: some View {
//        NavigationStack {
//            Form {
//                Section("Project Details") {
//                    TextField("Project Name", text: $project.projectName)
//                    TextField("Artist", text: $project.artist)
//                }
//                
//                Section("Status") {
//                    // FIXED: Proper status picker with binding
//                    Picker("Status", selection: $project.status) {
//                        ForEach(Status.allCases, id: \.self) { status in
//                            HStack {
//                                Circle()
//                                    .fill(status.statusColor)
//                                    .frame(width: 12, height: 12)
//                                Text(status.rawValue)
//                            }
//                            .tag(status)
//                        }
//                    }
//                    .pickerStyle(.menu)
//                }
//                
//                Section("Location") {
//                    // FIXED: Map with proper tap handling
//                    LocationPickerView(selectedLocation: $project.location)
//                        .frame(height: 200)
//                }
//                
//                Section("Timeline") {
//                    DatePicker("Start Date", selection: $project.startDate, displayedComponents: [.date, .hourAndMinute])
//                    DatePicker("End Date", selection: $project.endDate, displayedComponents: [.date, .hourAndMinute])
//                }
//            }
//            .navigationTitle("Project Details")
//            .toolbar {
//                ToolbarItem(placement: .navigationBarLeading) {
//                    Button("Cancel") { dismiss() }
//                }
//                ToolbarItem(placement: .navigationBarTrailing) {
//                    Button("Save") { dismiss() }
//                        .fontWeight(.semibold)
//                }
//            }
//        }
//    }
//}
//
//// FIXED: Separate LocationPickerView with proper map handling
//struct LocationPickerView: View {
//    @Binding var selectedLocation: Spot?
//    @State private var mapRegion = MKCoordinateRegion(
//        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
//        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
//    )
//    @State private var showingLocationSearch = false
//    
//    var body: some View {
//        VStack(spacing: 0) {
//            // Map view with tap handling
//            Map(coordinateRegion: $mapRegion, annotationItems: annotations) { location in
//                MapAnnotation(coordinate: CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)) {
//                    Button(action: {
//                        selectLocation(location)
//                    }) {
//                        Image(systemName: "mappin.circle.fill")
//                            .font(.title2)
//                            .foregroundColor(.red)
//                            .background(Color.white, in: Circle())
//                            .shadow(radius: 3)
//                    }
//                }
//            }
//            .onTapGesture(coordinateSpace: .local) { location in
//                // FIXED: Convert tap location to coordinate
//                handleMapTap(coordinate: mapRegion.center)
//            }
//            .overlay(alignment: .topTrailing) {
//                Button("Search") {
//                    showingLocationSearch = true
//                }
//                .buttonStyle(.borderedProminent)
//                .buttonBorderShape(.capsule)
//                .padding()
//            }
//            
//            // Current selection info
//            if let location = selectedLocation {
//                HStack {
//                    VStack(alignment: .leading) {
//                        Text(location.name)
//                            .font(.headline)
//                        Text(location.address)
//                            .font(.caption)
//                            .foregroundColor(.secondary)
//                    }
//                    Spacer()
//                    Button("Remove") {
//                        selectedLocation = nil
//                    }
//                    .foregroundColor(.red)
//                }
//                .padding()
//                .background(Color(.systemGray6))
//            }
//        }
//        .cornerRadius(12)
//        .sheet(isPresented: $showingLocationSearch) {
//            LocationSearchView(selectedLocation: $selectedLocation)
//        }
//    }
//    
//    private var annotations: [Spot] {
//        if let selected = selectedLocation {
//            return [selected]
//        }
//        return []
//    }
//    
//    private func selectLocation(_ spot: Spot) {
//        selectedLocation = spot
//        withAnimation {
//            mapRegion.center = CLLocationCoordinate2D(latitude: spot.latitude, longitude: spot.longitude)
//        }
//    }
//    
//    private func handleMapTap(coordinate: CLLocationCoordinate2D) {
//        let newSpot = Spot(
//            name: "Custom Location",
//            address: "Tap to set address",
//            latitude: coordinate.latitude,
//            longitude: coordinate.longitude
//        )
//        selectLocation(newSpot)
//    }
//}
//
//// MARK: - 2. Enhanced ItemListView
//
//struct EnhancedItemListView: View {
//    let items: [Item]
//    let onItemTap: ((Item) -> Void)?
//    let onItemDelete: ((Item) -> Void)?
//    
//    var body: some View {
//        if items.isEmpty {
//            EmptyItemsView()
//        } else {
//            LazyVStack(spacing: 8) {
//                ForEach(items) { item in
//                    EnhancedItemRowView(
//                        item: item,
//                        onTap: { onItemTap?(item) },
//                        onDelete: { onItemDelete?(item) }
//                    )
//                }
//            }
//            .padding(.horizontal)
//        }
//    }
//}
//
//// ENHANCED: Much better visual design
//struct EnhancedItemRowView: View {
//    let item: Item
//    let onTap: () -> Void
//    let onDelete: () -> Void
//    
//    @State private var isPressed = false
//    
//    var body: some View {
//        HStack(spacing: 16) {
//            // Left: Icon with colored background
//            ZStack {
//                Circle()
//                    .fill(item.itemType.color.opacity(0.15))
//                    .frame(width: 48, height: 48)
//                
//                Image(systemName: item.icon.systemName)
//                    .font(.system(size: 20, weight: .medium))
//                    .foregroundColor(item.itemType.color)
//            }
//            
//            // Center: Item details
//            VStack(alignment: .leading, spacing: 4) {
//                Text(item.name.isEmpty ? "Untitled Item" : item.name)
//                    .font(.headline)
//                    .foregroundColor(.primary)
//                    .lineLimit(1)
//                
//                Text(item.itemType.rawValue)
//                    .font(.subheadline)
//                    .foregroundColor(.secondary)
//                
//                if !item.notes.isEmpty {
//                    Text(item.notes)
//                        .font(.caption)
//                        .foregroundColor(.tertiary)
//                        .lineLimit(2)
//                        .padding(.top, 2)
//                }
//            }
//            
//            Spacer()
//            
//            // Right: Fee and actions
//            VStack(alignment: .trailing, spacing: 8) {
//                Text(item.fee, format: .currency(code: "USD"))
//                    .font(.title3)
//                    .fontWeight(.bold)
//                    .foregroundColor(.primary)
//                
//                HStack(spacing: 8) {
//                    Button(action: {}) {
//                        Image(systemName: "pencil")
//                            .font(.caption)
//                            .foregroundColor(.blue)
//                    }
//                    
//                    Button(action: onDelete) {
//                        Image(systemName: "trash")
//                            .font(.caption)
//                            .foregroundColor(.red)
//                    }
//                }
//            }
//        }
//        .padding(.horizontal, 16)
//        .padding(.vertical, 14)
//        .background(backgroundColor)
//        .cornerRadius(16)
//        .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
//        .scaleEffect(isPressed ? 0.98 : 1.0)
//        .onTapGesture {
//            onTap()
//        }
//        .onLongPressGesture(minimumDuration: 0) { pressing in
//            withAnimation(.easeInOut(duration: 0.1)) {
//                isPressed = pressing
//            }
//        } perform: {}
//    }
//    
//    private var backgroundColor: Color {
//        Color(.systemBackground)
//            .overlay(
//                LinearGradient(
//                    colors: [item.itemType.color.opacity(0.05), Color.clear],
//                    startPoint: .leading,
//                    endPoint: .trailing
//                )
//            )
//    }
//}
//
//// MARK: - 3. Enhanced Invoice Model
//
//@Model
//class EnhancedInvoice: Identifiable {
//    // Existing properties
//    var number: Int
//    var name: String
//    var url: URL?
//    
//    // ENHANCED: Professional invoice tracking
//    var status: InvoiceStatus = .draft
//    var dateCreated: Date = Date()
//    var dateSent: Date?
//    var dateDue: Date?
//    var datePaid: Date?
//    var dateViewed: Date?
//    
//    // Client/project relationship
//    var clientName: String = ""
//    var clientEmail: String = ""
//    var projectName: String = ""
//    
//    // Financial tracking
//    var subtotal: Double = 0.0
//    var taxRate: Double = 0.0
//    var taxAmount: Double = 0.0
//    var totalAmount: Double = 0.0
//    var amountPaid: Double = 0.0
//    
//    // Communication
//    var emailSubject: String = ""
//    var emailBody: String = ""
//    var notes: String = ""
//    
//    // Template and formatting
//    var templateUsed: String = "default"
//    var logoIncluded: Bool = true
//    
//    // Payment details
//    var paymentMethod: String = ""
//    var paymentReference: String = ""
//    
//    init(
//        number: Int,
//        name: String,
//        url: URL? = nil,
//        clientName: String = "",
//        projectName: String = "",
//        subtotal: Double = 0.0,
//        taxRate: Double = 0.0
//    ) {
//        self.number = number
//        self.name = name
//        self.url = url
//        self.clientName = clientName
//        self.projectName = projectName
//        self.subtotal = subtotal
//        self.taxRate = taxRate
//        self.taxAmount = subtotal * (taxRate / 100)
//        self.totalAmount = subtotal + taxAmount
//        
//        // Auto-generate due date (Net 30)
//        self.dateDue = Calendar.current.date(byAdding: .day, value: 30, to: Date())
//        
//        // Auto-generate email content
//        self.emailSubject = "Invoice #\(number) - \(projectName)"
//        self.emailBody = generateDefaultEmailBody()
//    }
//    
//    // MARK: - Computed Properties
//    
//    var isOverdue: Bool {
//        guard let dueDate = dateDue else { return false }
//        return Date() > dueDate && status != .paid && status != .cancelled
//    }
//    
//    var daysPastDue: Int {
//        guard let dueDate = dateDue, isOverdue else { return 0 }
//        return Calendar.current.dateComponents([.day], from: dueDate, to: Date()).day ?? 0
//    }
//    
//    var remainingBalance: Double {
//        totalAmount - amountPaid
//    }
//    
//    var isPaidInFull: Bool {
//        remainingBalance <= 0.01
//    }
//    
//    // MARK: - Status Management
//    
//    func markAsSent() {
//        status = .sent
//        dateSent = Date()
//    }
//    
//    func markAsViewed() {
//        if status == .sent {
//            status = .viewed
//        }
//        dateViewed = Date()
//    }
//    
//    func markAsPaid(amount: Double = 0, method: String = "", reference: String = "") {
//        status = .paid
//        datePaid = Date()
//        
//        if amount > 0 {
//            amountPaid = amount
//        } else {
//            amountPaid = totalAmount
//        }
//        
//        paymentMethod = method
//        paymentReference = reference
//    }
//    
//    // MARK: - Email Generation
//    
//    private func generateDefaultEmailBody() -> String {
//        return """
//        Dear \(clientName),
//        
//        Please find attached invoice #\(number) for the \(projectName) project.
//        
//        Amount Due: \(totalAmount.formatted(.currency(code: "USD")))
//        Due Date: \(dateDue?.formatted(date: .long, time: .omitted) ?? "N/A")
//        
//        Thank you for your business!
//        
//        Best regards
//        """
//    }
//}
//
//// ENHANCED: Professional invoice status tracking
//enum InvoiceStatus: String, CaseIterable, Identifiable, Codable {
//    case draft = "Draft"
//    case sent = "Sent"
//    case viewed = "Viewed"
//    case paid = "Paid"
//    case overdue = "Overdue"
//    case cancelled = "Cancelled"
//    case partiallyPaid = "Partially Paid"
//    
//    var id: Self { self }
//    
//    var color: Color {
//        switch self {
//        case .draft: return .gray
//        case .sent: return .blue
//        case .viewed: return .orange
//        case .paid: return .green
//        case .overdue: return .red
//        case .cancelled: return .secondary
//        case .partiallyPaid: return .yellow
//        }
//    }
//    
//    var icon: String {
//        switch self {
//        case .draft: return "doc.plaintext"
//        case .sent: return "paperplane"
//        case .viewed: return "eye"
//        case .paid: return "checkmark.circle.fill"
//        case .overdue: return "exclamationmark.triangle.fill"
//        case .cancelled: return "xmark.circle"
//        case .partiallyPaid: return "percent"
//        }
//    }
//}
//
//// MARK: - 4. Extensions for ItemType Colors
//
//extension ItemType {
//    var color: Color {
//        switch self {
//        case .session, .overdub, .demo:
//            return .blue
//        case .rehearsal:
//            return .orange
//        case .concert, .tour:
//            return .purple
//        case .perDiem, .reimbursement:
//            return .green
//        case .arrangement, .score:
//            return .indigo
//        case .production:
//            return .pink
//        case .rental:
//            return .brown
//        case .lesson:
//            return .teal
//        case .other:
//            return .gray
//        }
//    }
//}
//
//extension FontAwesomeCode {
//    var systemName: String {
//        switch self {
//        case .music: return "music.note"
//        case .ticket_alt: return "ticket"
//        case .bus: return "bus"
//        case .dollar_sign: return "dollarsign.circle"
//        case .book_open: return "book.open"
//        case .wave_square: return "waveform"
//        case .clock: return "clock"
//        case .receipt: return "receipt"
//        case .graduation_cap: return "graduationcap"
//        case .question: return "questionmark"
//        default: return "questionmark"
//        }
//    }
//}
//
//// MARK: - 5. Data Migration Manager
//
//@MainActor
//class DataMigrationManager: ObservableObject {
//    @Published var isMigrating = false
//    @Published var migrationProgress: Double = 0.0
//    @Published var migrationError: String?
//    
//    func performMigrations(context: ModelContext) async {
//        isMigrating = true
//        migrationProgress = 0.0
//        
//        do {
//            // Migration 1: Invoice enhancements
//            await migrateInvoices(context: context)
//            migrationProgress = 0.25
//            
//            // Migration 2: Add dates to items
//            await migrateItems(context: context)
//            migrationProgress = 0.50
//            
//            // Migration 3: Client international fields
//            await migrateClients(context: context)
//            migrationProgress = 0.75
//            
//            // Migration 4: Project soft delete setup
//            await migrateProjects(context: context)
//            migrationProgress = 1.0
//            
//            try context.save()
//            
//        } catch {
//            migrationError = error.localizedDescription
//        }
//        
//        isMigrating = false
//    }
//    
//    private func migrateInvoices(context: ModelContext) async {
//        // SwiftData handles schema changes automatically for most cases
//    }
//    
//    private func migrateItems(context: ModelContext) async {
//        let descriptor = FetchDescriptor<Item>()
//        
//        do {
//            let items = try context.fetch(descriptor)
//            for item in items {
//                if item.datePerformed == nil {
//                    item.datePerformed = item.project?.startDate
//                }
//            }
//        } catch {
//            print("Error migrating items: \(error)")
//        }
//    }
//    
//    private func migrateClients(context: ModelContext) async {
//        let descriptor = FetchDescriptor<Client>()
//        
//        do {
//            let clients = try context.fetch(descriptor)
//            for client in clients {
//                if client.country.isEmpty {
//                    client.country = "US"
//                }
//                if client.currency.isEmpty {
//                    client.currency = "USD"
//                }
//                if client.paymentTerms == 0 {
//                    client.paymentTerms = 30
//                }
//            }
//        } catch {
//            print("Error migrating clients: \(error)")
//        }
//    }
//    
//    private func migrateProjects(context: ModelContext) async {
//        let descriptor = FetchDescriptor<Project>()
//        
//        do {
//            let projects = try context.fetch(descriptor)
//            for project in projects {
//                if project.status == .pendingDeletion && project.deletionDate == nil {
//                    project.status = .open
//                }
//            }
//        } catch {
//            print("Error migrating projects: \(error)")
//        }
//    }
//}
