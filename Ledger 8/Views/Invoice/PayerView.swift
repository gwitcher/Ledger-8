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
//            VStack (alignment: .leading) {
//                Text("To:")
//                    .font(.title3)
//                    .fontWeight(.regular)
//                
//                HStack{
//                    Text("Client: ")
//                        .fontWeight(.medium)
//                        .foregroundStyle(.secondary)
//                    Text(project.client?.name ?? "")
//                        .fontWeight(.regular)
//                }
//                
//                HStack{
//                    Text("Artist: ")
//                        .fontWeight(.medium)
//                        .foregroundStyle(.secondary)
//                    Text(project.artist)
//                        .fontWeight(.regular)
//                }
//                HStack{
//                    Text("Attn: ")
//                        .fontWeight(.medium)
//                        .foregroundStyle(.secondary)
//                    Text("Mock")
//                        .fontWeight(.regular)
//                }
//                HStack{
//                    Text("Address: ")
//                        .fontWeight(.medium)
//                        .foregroundStyle(.secondary)
//                    Text("111 Main St.")
//                        .fontWeight(.regular)
//                }
//                HStack{
//                    Text("Address: ")
//                    
//                        .fontWeight(.medium)
//                        .lineLimit(1)
//                        .foregroundStyle(.secondary)
//                    Text("Los Angeles, CA 90028")
//                        .fontWeight(.regular)
//                        .lineLimit(2)
//                }
//                
//                
//            }
            VStack(spacing: 6) {
                LabeledContent("Client: ") {
                    Text("\(project.client?.name ?? "")")
                    Spacer()
                }
                
                LabeledContent("Artist: ") {
                    Text("\(project.artist)")
                    Spacer()
                }
                
                LabeledContent("Attn: ") {
                    Text("\(project.client?.name ?? "")")
                    Spacer()
                }
                
                LabeledContent {
                    VStack(alignment: .leading){
                        Text("1111 Main St")
                        Text("Burbank, Ca 91506")
                    }
                    Spacer()
                    
                } label: {
                    Text("Address: ")
                    Text("")
                }
            }
            .font(.headline)
            .minimumScaleFactor(0.5)
        }
        .padding()
    }
}

#Preview {
    PayerView(project: Project(projectName: "Dummy", artist: "Dummy", jobDate: Date()))
}
