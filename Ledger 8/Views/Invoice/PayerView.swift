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
        
        HStack {
            VStack(spacing: 6) {
                LabeledContent("Client: ") {
                    Text("\(project.client?.name ?? "")")
                    //Spacer()
                }
                
                LabeledContent("Artist: ") {
                    Text("\(project.artist)")
                    //Spacer()
                }
                
                LabeledContent("Attn: ") {
                    Text("\(project.client?.name ?? "")")
                    //Spacer()
                }
                
                LabeledContent("Email: ") {
                    Text("\(project.client?.email ?? "")")
                    //Spacer()
                }
                
                LabeledContent {
                    VStack(alignment: .leading){
                        Text(project.client?.address ?? "")
                        Text(project.client?.address2 ?? "")
                    }
                    //Spacer()
                    
                } label: {
                    Text("Address: ")
                    Text(" ")
                       
                }
            }
            .font(.caption)
            //.minimumScaleFactor(0.5)
            Spacer()
        }
        //.padding()
        
    }
}

#Preview {
    PayerView(project: Project(projectName: "Dummy", artist: "Dummy", jobDate: Date()))
}
