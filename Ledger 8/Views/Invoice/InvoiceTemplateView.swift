//
//  InvoiceTemplateView.swift
//  Ledger 8
//
//  Created by Gabe Witcher on 4/17/25.
//

import SwiftUI
import SwiftData

struct InvoiceTemplateView: View {
    @Environment(\.modelContext) var modelContext
    
    var project: Project
    
    
    var body: some View {
        
        HStack  {
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .foregroundStyle(.icon)
                .opacity(0.2)
                .overlay {
                    HStack (alignment: .top) {
                        mfgwLogoView()
                            .frame(width: 170, height: 60)
                            .padding()
                            .minimumScaleFactor(0.5)
                            //.border(.black)
                        
                        Spacer()
                        
                        VStack (alignment: .center) {
                            Text("Invoice: 1003")
                                .font(.caption)
                                .padding(.horizontal)
                                //.border(.blue)
                           
                            
                            Text("Total Due: $200.00")
                                .font(.caption)
                                .fontWeight(.black)
                                .minimumScaleFactor(0.5)
                                .lineLimit(1)
                                .padding(8)
                                .background(.red.opacity(0.5), in: Capsule())
                                
                                //.border(.green)
                            
                            
                            
                        }
                        .padding()
                        //.frame(width: .infinity)
                        
                        //.border(.red)
                        
                        
                    }
                    .padding(.horizontal)
                }
        }
        .frame(width: 400, height: 100)
            
           
       
            
            
       
        HStack (alignment: .bottom) {
            PayerView(project: project)
                .frame(width: 170, height: 60)
                .padding()
                .minimumScaleFactor(0.5)
                .background(Color(.secondarySystemBackground).opacity(0.75),
                                        in: RoundedRectangle(cornerRadius: 10.0, style: .continuous))
                //.border(.black)
            
            Spacer()
            
            VStack (alignment: .trailing) {
                HStack{
                    Text("Job Date: ")
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                    Text(project.jobDate.formatted(date: .long, time: .omitted))
                        .fontWeight(.thin)
                }
                HStack{
                    Text("Project: ")
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                    Text(project.projectName)
                        .fontWeight(.thin)
                }
            }
            .font(.caption)
            .fontWeight(.medium)
            .minimumScaleFactor(0.5)
            .lineLimit(1)
           
        }
        .padding()
        Spacer()
        
        ItemTableView()
            .minimumScaleFactor(0.5)
        
    }
}

#Preview {
    InvoiceTemplateView( project: Project(client: "Dummy Dums", projectName: "Dummy", artist: "Dummy", jobDate: Date()))
}
