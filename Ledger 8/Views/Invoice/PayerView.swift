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
        let cityState = "\(project.client?.city ?? ""), \(project.client?.state ?? "")"
        
        VStack(spacing: 3) {
            if project.client?.attention != "" {
                LabeledContent("Attn: ") {
                    Text("\(project.client?.fullName ?? "")")
                        .multilineTextAlignment(.trailing)
                }
            }
            
            LabeledContent("Client: ") {
                Text("\(project.client?.fullName ?? "")")
                    .multilineTextAlignment(.trailing)
            }
            
            if project.artist != "" {
                LabeledContent("Artist: ") {
                    Text("\(project.artist)")
                        .multilineTextAlignment(.trailing)
                }
            }
            
            if project.client?.email != "" {
                LabeledContent("Email: ") {
                    Text("\(project.client?.email ?? "")")
                    .multilineTextAlignment(.trailing) 
            }
                           }
            
            if project.client?.address != "" && cityState != "" && project.client?.zip != "" {
                LabeledContent {
                    VStack(alignment: .trailing){
                        Text(project.client?.address ?? "")
                        if project.client?.address2 != "" {
                            Text(project.client?.address2 ?? "")
                        }
                        Text(cityState)
                        Text(project.client?.zip ?? "")
                    }
                    
                } label: {
                    Text("Address: ")
                    Text("")
                    Text("")
                    Text("")
                }
            }
            
        }
        .font(.caption)
        .foregroundStyle(.primary)
    }
}

#Preview {
    PayerView(project: Project(projectName: "Dummy", artist: "Dummy", startDate: Date()))
}
