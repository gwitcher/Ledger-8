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
    @State private var client = Client()
    @State private var projectName = ""
    @State private var artist = ""
    @State private var jobDate = Date().formatted(date: .long, time: .omitted)
    
    let dateFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateStyle = .long
            return formatter
        }()
    
    var body: some View {
        
        HStack {
            VStack (alignment: .leading) {
                Text("To:")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                HStack{
                    Text("Client: ")
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                    Text(project.client?.givenName ?? "")
                        .fontWeight(.regular)
                }
                
                HStack{
                    Text("Artist: ")
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                    Text(artist)
                        .fontWeight(.regular)
                }
                HStack{
                    Text("Attn: ")
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                    Text("Mock")
                        .fontWeight(.regular)
                }
                HStack{
                    Text("Address: ")
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                    Text("111 Main St.")
                        .fontWeight(.regular)
                }
                HStack{
                    Text("Address: ")
                    
                        .fontWeight(.medium)
                        .lineLimit(1)
                        .foregroundStyle(.secondary)
                    Text("Los Angeles, CA 90028")
                        .fontWeight(.regular)
                        .lineLimit(2)
                }
                
                
            }
            .font(.subheadline)
            .minimumScaleFactor(0.5)
            
        }
        .padding()
        .onAppear {
            client = project.client ?? Client()
            projectName = project.projectName
            artist = project.artist
            jobDate = project.jobDate.formatted(date: .long, time: .omitted)
        }
    }
}

#Preview {
    PayerView(project: Project(projectName: "Dummy", artist: "Dummy", jobDate: Date()))
}
