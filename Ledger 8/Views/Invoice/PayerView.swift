//
//  PayerView.swift
//  Ledger 8
//
//  Created by Gabe Witcher on 4/17/25.
//

import SwiftUI

struct PayerView: View {
    @Environment(\.modelContext) var modelContext
    
    var project: Project
    
    var body: some View {
        VStack(spacing: 3) {
            // Show attention line only if it's different from full name and not empty
            if let client = project.client,
               !client.attention.isEmpty && client.attention != client.fullName {
                LabeledContent("Attn: ") {
                    Text(client.attention)
                        .multilineTextAlignment(.trailing)
                }
            }
            
            // Client name - always show with fallback
            LabeledContent("Client: ") {
                Text(project.client?.fullName ?? "Client Name TBD")
                    .multilineTextAlignment(.trailing)
            }
            
            // Artist - only show if not empty
            if !project.artist.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                LabeledContent("Artist: ") {
                    Text(project.artist)
                        .multilineTextAlignment(.trailing)
                }
            }
            
            // Email - only show if not empty
            if let client = project.client,
               !client.email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                LabeledContent("Email: ") {
                    Text(client.email)
                        .multilineTextAlignment(.trailing)
                }
            }
            
            // Address section - only show if we have meaningful address data
            buildAddressContent()
        }
        .font(.caption)
        .foregroundStyle(.primary)
    }
    
    @ViewBuilder
    private func buildAddressContent() -> some View {
        if let client = project.client {
            let address = client.address.trimmingCharacters(in: .whitespacesAndNewlines)
            let address2 = client.address2.trimmingCharacters(in: .whitespacesAndNewlines)
            let city = client.city.trimmingCharacters(in: .whitespacesAndNewlines)
            let state = client.state.trimmingCharacters(in: .whitespacesAndNewlines)
            let zip = client.zip.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Check if we have enough address info to display something meaningful
            let hasAddress = !address.isEmpty
            let hasCityState = !city.isEmpty || !state.isEmpty
            let hasZip = !zip.isEmpty
            
            if hasAddress || hasCityState || hasZip {
                LabeledContent {
                    VStack(alignment: .trailing, spacing: 1) {
                        if !address.isEmpty {
                            Text(address)
                        }
                        if !address2.isEmpty {
                            Text(address2)
                        }
                        if hasCityState {
                            let cityState = [city, state].filter { !$0.isEmpty }.joined(separator: ", ")
                            if !cityState.isEmpty {
                                Text(cityState)
                            }
                        }
                        if !zip.isEmpty {
                            Text(zip)
                        }
                    }
                } label: {
                    VStack(alignment: .leading) {
                        Text("Address: ")
                        // Add empty Text views to align with the address lines
                        if !address2.isEmpty { Text("") }
                        if hasCityState { Text("") }
                        if !zip.isEmpty { Text("") }
                    }
                }
            }
        }
    }
}

#Preview("Complete Client Data") {
    let client = Client()
    client.company = "Acme Studios Inc."
    client.attention = "John Smith"
    client.email = "john.smith@acmestudios.com"
    client.address = "123 Main Street"
    client.address2 = "Suite 400"
    client.city = "New York"
    client.state = "NY"
    client.zip = "10001"
    
    let project = Project(projectName: "Album Cover Design", artist: "The Rolling Stones", startDate: Date())
    project.client = client
    
    return PayerView(project: project)
        .padding()
}

#Preview("Minimal Client Data") {
    let client = Client()
    client.firstName = "Jane"
    client.lastName = "Doe"
    client.email = "jane@example.com"
    // No address data
    
    let project = Project(projectName: "Logo Design", artist: "Local Band", startDate: Date())
    project.client = client
    
    return PayerView(project: project)
        .padding()
}

#Preview("No Client Assigned") {
    let project = Project(projectName: "Poster Design", artist: "Indie Artist", startDate: Date())
    // No client assigned
    
    return PayerView(project: project)
        .padding()
}

#Preview("Client with Partial Address") {
    let client = Client()
    client.company = "Creative Agency LLC"
    client.attention = "Creative Agency LLC" // Same as full name, so shouldn't show
    client.email = "hello@creativeagency.com"
    client.city = "Los Angeles"
    client.state = "CA"
    // No street address or zip
    
    let project = Project(projectName: "Brand Identity", artist: "Pop Star", startDate: Date())
    project.client = client
    
    return PayerView(project: project)
        .padding()
}

#Preview("Client with Only Street Address") {
    let client = Client()
    client.company = "Mom & Pop Records"
    client.email = "contact@momandpop.com"
    client.address = "456 Music Row"
    // No city, state, or zip
    
    let project = Project(projectName: "Album Art", artist: "", startDate: Date()) // Empty artist
    project.client = client
    
    return PayerView(project: project)
        .padding()
}

#Preview("Long Address Example") {
    let client = Client()
    client.company = "International Music Corporation"
    client.attention = "A&R Department"
    client.email = "ar@internationalmusiccorp.com"
    client.address = "789 Very Long Street Name That Goes On And On"
    client.address2 = "Building C, Floor 12, Suite 1234A"
    client.city = "San Francisco"
    client.state = "California"
    client.zip = "94102-1234"
    
    let project = Project(projectName: "Multi-Album Campaign", artist: "Famous Artist with a Really Long Name", startDate: Date())
    project.client = client
    
    return PayerView(project: project)
        .padding()
}
