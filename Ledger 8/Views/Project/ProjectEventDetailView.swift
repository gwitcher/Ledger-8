import SwiftUI
import MapKit
import SwiftUIFontIcon
import SwiftData

struct ProjectEventDetailView: View {
    @Bindable var project: Project  // Keep @Bindable for direct project updates in UI
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: ProjectEventDetailViewModel
    
    var customDismissAction: (() -> Void)? = nil
    
    init(project: Project) {
        self.project = project
        self._viewModel = State(initialValue: ProjectEventDetailViewModel(project: project))
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {  // FIXED: Consistent spacing throughout
                
                //MARK: - Project Name
                HStack(spacing: 12) {  // FIXED: Consistent spacing
                    Text(project.projectName)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color.mintyFresh3.opacity(0.6))
                        .frame(width: 37, height: 34)
                        .overlay {
                            FontIcon.text(.awesome5Solid(code: project.mediaType.icon), fontsize: 20, color: Color.quiteClear2)
                        }
                }
                .padding(.bottom, 4)  // FIXED: Consistent bottom spacing
                
                //MARK: - Client
                HStack {
                    VStack(alignment: .leading, spacing: 4) {  // FIXED: Better structure
                        
                            Text("Client")
                                .font(.headline)
                                .foregroundColor(.secondary)
                        
                            Text(project.client?.fullName ?? "No Client Assigned")
                                .font(.title3)
                                .fontWeight(.medium)
                        }
                    
                    if !project.artist.isEmpty {
                        
                        Spacer()
                        
                        VStack(alignment: .leading, spacing: 4) {  // FIXED: Better structure
                            
                                Text("Artist")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                            
                                Text(project.artist)
                                    .font(.title3)
                                    .fontWeight(.medium)
                            }
                        
                        Spacer()
                    }
                    
                    
                }
                
                //MARK: - Location Address (Tappable)
                if let location = project.location, !location.address.isEmpty {
                    Button(action: {
                        viewModel.openInMaps(location: location)
                    }) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading){
                                Text(location.name)
                                    .font(.footnote)
                                    .foregroundStyle(.red)
                                    .underline()
                                Text(location.address)
                                    .font(.caption)
                                    .foregroundStyle(.red)
                                    .underline()
                            }
                        }
                        .padding(.bottom, 10)
                    }
                    .buttonStyle(.plain)
                }
                
                //MARK: - Date and Time
                VStack(alignment: .leading, spacing: 4) {  // FIXED: Better structure
                    Text("Schedule")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    let (line1, line2) = viewModel.eventDateDetails(start: project.startDate, end: project.endDate)
                    Text(line1)
                        .font(.callout)
                        .fontWeight(.medium)
                    Text(line2)
                        .font(.callout)
                        .foregroundColor(.secondary)
                }
                
                //MARK: - Notes
                if !project.notes.isEmpty {
                    HStack {
                        //                        Rectangle()
                        //                            .foregroundStyle(.clear)
                        //                            .frame(width: 10)
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundStyle(.orange)
                        Text("Notes: \(project.notes)")
                            .font(.footnote)
                    }
                    .padding(.bottom, 15)
                }
                
                
                Divider()
                    .padding(.bottom, 5)
                
                //MARK: - Items and Total Fee
                if let items = project.items, !items.isEmpty {
                    Section {
                        Text("Items")
                            .font(.headline)
                        
                        ForEach(items, id: \.name) { item in
                            HStack {
                                FontIcon.text(.awesome5Solid(code: item.icon), fontsize: 15)
                                Text(item.name)
                                    .font(.subheadline)
                                Spacer()
                                Text(item.fee, format: .currency(code: "USD"))
                                    .font(.subheadline)
                                    .foregroundColor(.primary).opacity(0.7)
                            }
                            
                        }
                        HStack {
                            Text("Total Fee")
                                .fontWeight(.semibold)
                            
                            Spacer()
                            Text(viewModel.totalFee(items: items), format: .currency(code: "USD"))
                                .fontWeight(.bold)
                                .foregroundStyle(.green)
                        }
                        .padding(.top, 4)
                        .padding(.bottom, 5)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        viewModel.toggleItemList()
                    }
                }
                
                Divider()
                    .padding(.vertical, 1)
                
                
                //MARK: - Invoice
                
                
                
                
                if project.invoice != nil {
                    InvoiceLinkView(project: project)
                    // Warning message when invoice needs update
                    if project.invoiceNeedsUpdate {
                      
                        Text("⚠️ Warning: Project info has changed. Please delete invoice and create new.")
                            .font(.caption)
                            .foregroundColor(.orange)
                            .padding(.top, 4)
                    }
                    Divider()
                        .padding(.vertical, 10)
                }
                
                
                
                
                
                
                
                
                
                //MARK: - Status
                HStack {
                    Text("Status")
                        .font(.headline)
                    
                    Spacer()
                    
                    // Calendar-style status picker with dot and menu
                    Menu {
                        ForEach(Status.allCases, id: \.self) { status in
                            Button {
                                viewModel.updateProjectStatus(status, in: modelContext)
                            } label: {
                                HStack {
                                    Circle()
                                        .fill(status.statusColor)
                                        .frame(width: 12, height: 12)
                                    Text(status.rawValue)
                                    if project.status == status {
                                        Spacer()
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(project.status.statusColor)
                                .frame(width: 12, height: 12)
                            Text(project.status.rawValue)
                                .foregroundColor(.primary)
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Divider()
                    .padding(.vertical, 8)
                
                //MARK: - Map (if available) - Calendar style: non-interactive, tap to open Maps
                if let location = project.location {
                    let cameraPosition: MapCameraPosition = .region(viewModel.region)
                    let center = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
                    
                    // Non-interactive map that just shows location and opens Maps on tap
                    Map(initialPosition: cameraPosition, content: {
                        Marker(location.name.isEmpty ? "Event Location" : location.name, 
                               systemImage: "mappin.circle.fill", 
                               coordinate: center)
                    })
                    .frame(height: 180)
                    .cornerRadius(12)
                    .allowsHitTesting(false)  // Makes map non-interactive
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
                    .contentShape(Rectangle())  // Makes entire area tappable
                    .onTapGesture {
                        // Only action: open in Maps app (like Calendar)
                        viewModel.openInMaps(location: location)
                    }
                }
                
            }
            .padding()
        }
        .navigationTitle("Event Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    viewModel.toggleProjectDetailView()
                } label: {
                    Image(systemName: "pencil")
                }
            }
            
            ToolbarItem(placement: .bottomBar) {
                Button(role: .destructive) {
                    viewModel.showDeleteConfirmation()
                } label: {
                    Image(systemName: "trash")
                        .foregroundStyle(Color(.systemRed))
                }
            }
        }
        .sheet(isPresented: $viewModel.projectDetailViewIsShowing) {
            ProjectDetailView(project: project)
        }
        .sheet(isPresented: $viewModel.itemListIsShowing) {
            EnhancedProjectItemListView(project: project)
        }
        .alert("Delete Project", isPresented: $viewModel.showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                viewModel.deleteProject(from: modelContext, customDismissAction: customDismissAction, dismiss: dismiss)
            }
        } message: {
            Text("Are you sure you want to delete this project? This action cannot be undone.")
        }
    }
}



// MARK: - Preview Data

struct ProjectEventDetailView_Previews: PreviewProvider {
    static var previewProject: Project {
        // Sample Spot
        let spot = Spot(name: "Music Studio", address: "123 Main St, Nashville, TN", latitude: 36.1627, longitude: -86.7816, addedDate: Date())
        // Sample Client
        let client = Client(
            firstName: "Taylor",
            lastName: "Swift",
            email: "taylor@music.com",
            phone: "615-555-1234",
            attention: "",
            address: "456 Elm St",
            address2: "",
            city: "Nashville",
            state: "TN",
            zip: "37201",
            notes: "",
            company: "TS Productions"
        )
        
        // Sample Items
        let item1 = Item(name: "Tracking Session", fee: 350.0, itemType: .session, notes: "")
        let item2 = Item(name: "Mixing", fee: 200.0, itemType: .overdub, notes: "")
        let item3 = Item(name: "Arrangement", fee: 150.0, itemType: .arrangement, notes: "")
        let items = [item1, item2, item3]
        
        // Sample start/end dates
        let startDate = Calendar.current.date(bySettingHour: 14, minute: 0, second: 0, of: Date())!
        let endDate = Calendar.current.date(byAdding: .hour, value: 48, to: startDate)!
        
        let project = Project(
            projectName: "Album Recording",
            artist: "Taylor Swift",
            startDate: startDate,
            endDate: endDate,
            status: .open,
            mediaType: .recording,
            notes: "New album for 2025 release.",
            delivered: false,
            paid: false,
            dateOpened: Date(),
            dateDelivered: Date.distantPast,
            dateClosed: Date.distantFuture,
            endDateSelected: true,
            items: items,
            location: spot
        )
        project.client = client
        project.items = items
        return project
    }
    
    static var previews: some View {
        NavigationStack {
            ProjectEventDetailView(project: previewProject)
        }
    }
}
