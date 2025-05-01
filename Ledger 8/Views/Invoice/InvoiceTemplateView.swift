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
        
        
        VStack {
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
                            
                            
                            Spacer()
                            
                            VStack (alignment: .center) {
                                Text("Invoice: \(project.invoice?.number ?? 0)")
                                    .font(.caption)
                                    .padding(.horizontal)
                                //.border(.blue)
                                
                                RoundedRectangle(cornerRadius: 30)
                                    .scaleEffect(1)
                                    .opacity(0.6)
                                    .foregroundStyle(.red)
                                    .overlay {
                                        Text("Total Due: $200.00")
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .minimumScaleFactor(0.5)
                                            .lineLimit(1)
                                            .padding(8)
                                    }
                                
                                
                                
                            }
                            .padding()
                            
                        }
                        .padding(.horizontal)
                    }
            }
            .frame(width: 400, height: 100)
            
            
            
            HStack {
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .foregroundStyle(.clear)
                    .opacity(0.1)
                    .overlay {
                        HStack {
                            PayerView(project: project)
                                .padding()
                            
                        }
                        
                    }
               
               
            }
            .frame(width: 200, height: 120)
            .border(.black)
           
            
            
            ItemTableView(project: project)
                .padding()
                .minimumScaleFactor(0.5)
            
            Spacer()
            
        }
    }
}

#Preview {
    InvoiceTemplateView( project: Project(projectName: "Dummy", artist: "Dummy", jobDate: Date()))
}

