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
    PayerView(project: Project(projectName: "Dummy", artist: "Dummy", jobDate: Date()))
}
