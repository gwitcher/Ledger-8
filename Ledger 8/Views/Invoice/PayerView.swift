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
                LabeledContent("Client: ") {
                    Text("\(project.client?.name ?? "")")
                        .multilineTextAlignment(.trailing)
                }
                
                LabeledContent("Artist: ") {
                    Text("\(project.artist)")
                        .multilineTextAlignment(.trailing)
                }
                
                LabeledContent("Attn: ") {
                    Text("\(project.client?.name ?? "")")
                        .multilineTextAlignment(.trailing)
                }
                
                LabeledContent("Email: ") {
                    Text("\(project.client?.email ?? "")")
                    .multilineTextAlignment(.trailing)                }
                
                LabeledContent {
                    VStack(alignment: .trailing){
                        Text(project.client?.address ?? "")
                        Text(project.client?.address2 ?? "")
                        Text(cityState)
                        Text(project.client?.zip ?? "")
                    }
                    //Spacer()
                    
                } label: {
                    Text("Address: ")
                    Text("")
                    Text("")
                    Text("")
                       
                }
            }
            .font(.caption)
            //Spacer()
        
       
    }
}

#Preview {
    PayerView(project: Project(projectName: "Dummy", artist: "Dummy", startDate: Date()))
}
