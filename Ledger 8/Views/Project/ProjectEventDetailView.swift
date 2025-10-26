import SwiftUI
import MapKit
import SwiftUIFontIcon

struct ProjectEventDetailView: View {
    @State var project: Project
    @State private var region: MKCoordinateRegion = MKCoordinateRegion()
    @State private var status: Status
    @State private var projectDetialViewIsShowing = false
    
    init(project: Project) {
        self._project = State(initialValue: project)
        self._status = State(initialValue: project.status)
        if let location = project.location {
            let center = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
            self._region = State(initialValue: MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)))
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                
                //MARK: - Project Name
                HStack{
                    Text(project.projectName)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.bottom, 4)
                    
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color.mintyFresh3.opacity(0.6))
                        .frame(width: 37, height: 34)
                        .overlay {
                            FontIcon.text(.awesome5Solid(code: project.icon), fontsize: 20, color: Color.quiteClear2)
                        }
                    
                }
                
                //MARK: - Client
                HStack{
                    Text(project.client?.fullName ?? "No Client")
                        .font(.title3)
                    
                    
                }
                
                //MARK: - Location Address (Tappable)
                if let location = project.location, !location.address.isEmpty {
                    Button(action: {
                        openInMaps(location: location)
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
                
                VStack(alignment: .leading){
                    let (line1, line2) = eventDateDetails(start: project.startDate, end: project.endDate)
                    Text(line1)
                        .font(.callout)
                    Text(line2)
                        .font(.callout)
                }
                .padding(.bottom, 10)
                
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
                            Text(totalFee(items: items), format: .currency(code: "USD"))
                                .fontWeight(.bold)
                                .foregroundStyle(.green)
                        }
                        .padding(.top, 4)
                        .padding(.bottom, 5)
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
                HStack{
                    Text("Status")
                    
                    Spacer()
                    
                    Circle()
                        .frame(height: 13)
                        .foregroundStyle(status.statusColor)
                    Picker("Status", selection: $status) {
                        ForEach(Status.allCases) { stat in
                            Text(stat.rawValue)
                                .foregroundStyle(status.statusColor)
                        }
                    }
                    .pickerStyle(.menu)
                }
                // .padding(.top, 10)
                
                Divider()
                    .padding(.vertical, 8)
                
                //MARK: - Map (if available)
                if let location = project.location {
                    let cameraPosition: MapCameraPosition = .region(region)
                    let center = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
                    Map(initialPosition: cameraPosition, content: {
                        Marker("", systemImage: "mappin.circle.fill", coordinate: center )
                    })
                    .frame(height: 150)
                    .cornerRadius(12)
                    .onTapGesture(perform: {
                        openInMaps(location: location)
                    })
                    .padding(.top, 8)
                    
                    
                }
                
            }
            .padding()
        }
        .navigationTitle("Event Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button("Edit") {
                projectDetialViewIsShowing.toggle()
            }
        }
        .sheet(isPresented: $projectDetialViewIsShowing) {
            ProjectDetailView(project: project)
        }
    }
    // MARK: - Helper Functions
    private func dateTimeString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func totalFee(items: [Item]) -> Double {
        items.reduce(0) { $0 + $1.fee }
    }
    
    private func openInMaps(location: Spot) {
        let coordinate = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
        mapItem.name = location.name.isEmpty ? "Project Location" : location.name
        mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
    }
    
    private func eventDateDetails(start: Date, end: Date) -> (String, String) {
        let calendar = Calendar.current
        
        let longDateFormatter = DateFormatter()
        longDateFormatter.dateFormat = "EEEE, MMM d, yyyy"
        
        let shortDateFormatter = DateFormatter()
        shortDateFormatter.dateFormat = "E, MMM d, yyyy"
        
        let hourFormatter = DateFormatter()
        hourFormatter.dateFormat = "ha"
        hourFormatter.amSymbol = "AM"
        hourFormatter.pmSymbol = "PM"
        
        if calendar.isDate(start, inSameDayAs: end) {
            // Same day: line 1 is the full date, line 2 is "11AM–12PM"
            let dateString = longDateFormatter.string(from: start)
            let startTime = hourFormatter.string(from: start).replacingOccurrences(of: " ", with: "")
            let endTime = hourFormatter.string(from: end).replacingOccurrences(of: " ", with: "")
            let timeString = "\(startTime)–\(endTime)"
            return (dateString, timeString)
        } else {
            // Different days: "from 11AM Thu, Oct 30, 2025", "to 12PM Fri, Oct 31, 2025"
            let startTime = hourFormatter.string(from: start).replacingOccurrences(of: " ", with: "")
            let startDate = shortDateFormatter.string(from: start)
            let endTime = hourFormatter.string(from: end).replacingOccurrences(of: " ", with: "")
            let endDate = shortDateFormatter.string(from: end)
            let line1 = "from \(startTime) \(startDate)"
            let line2 = "to \(endTime) \(endDate)"
            return (line1, line2)
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
