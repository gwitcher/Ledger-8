//
//  TopClientLocationsView.swift
//  Ledger 8
//
//  Created by (Your Name) on (Today’s Date).
//

import SwiftUI

struct TopClientLocationsView: View {
    let client: Client

    struct LocationUsage: Identifiable {
        let spot: Spot
        let count: Int
        let lastUsed: Date
        var id: UUID { spot.id }
    }

    private var topLocations: [LocationUsage] {
        guard let projects = client.project else { return [] }

        // Gather all locations from projects
        let locations = projects.compactMap { project in
            project.location.map { (spot: $0, date: project.startDate) }
        }

        // Group by unique location (name + address), count and get most recent.
        let grouped = Dictionary(grouping: locations, by: { loc in
            loc.spot.name.lowercased() + "|" + loc.spot.address.lowercased()
        })

        return grouped.map { (_, group) in
            let count = group.count
            let mostRecent = group.max { $0.date < $1.date }?.date ?? .distantPast
            // Use the first spot in the group (they should be identical by name/address)
            let spot = group.first!.spot
            return LocationUsage(spot: spot, count: count, lastUsed: mostRecent)
        }
        .sorted {
            if $0.count != $1.count { return $0.count > $1.count }
            return $0.lastUsed > $1.lastUsed
        }
        .prefix(3)
        .map { $0 }
    }

    var body: some View {
        HStack(spacing: 16) {
            ForEach(topLocations) { usage in
                VStack(alignment: .leading, spacing: 4) {
                    VStack(spacing: 6) {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundStyle(.red)
                            .font(.system(size: 60))
                        Text(usage.spot.name)
                            .font(.headline)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    VStack{
                        Text(usage.spot.address)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                            .minimumScaleFactor(0.8)
                    }

                }
                .padding(8)
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
    }
}

#Preview {
    // Sample client + spots for preview
    let spot1 = Spot(name: "Studio A", address: "123 Main St", latitude: 0, longitude: 0, addedDate: Date().addingTimeInterval(-3600))
    let spot2 = Spot(name: "Studio B", address: "789 Side St", latitude: 0, longitude: 0, addedDate: Date().addingTimeInterval(-7200))
    let spot3 = Spot(name: "Studio C", address: "555 Broadway", latitude: 0, longitude: 0, addedDate: Date().addingTimeInterval(-10800))

    let client = Client(firstName: "Test", lastName: "Client")
    let p1 = Project(projectName: "Proj1", artist: "", startDate: Date().addingTimeInterval(-100000), endDate: Date(), location: spot1)
    let p2 = Project(projectName: "Proj2", artist: "", startDate: Date().addingTimeInterval(-90000), endDate: Date(), location: spot1)
    let p3 = Project(projectName: "Proj3", artist: "", startDate: Date().addingTimeInterval(-80000), endDate: Date(), location: spot2)
    let p4 = Project(projectName: "Proj4", artist: "", startDate: Date().addingTimeInterval(-70000), endDate: Date(), location: spot3)
    let p5 = Project(projectName: "Proj5", artist: "", startDate: Date().addingTimeInterval(-60000), endDate: Date(), location: spot1)

    client.project = [p1, p2, p3, p4, p5]

    return TopClientLocationsView(client: client)
        .padding()
        .background(Color(.systemGroupedBackground))
}
