//
//  InvoiceTemplateTest.swift
//  Ledger 8
//
//  Created by Gabe Witcher on 4/18/25.
//

import SwiftUI
import SwiftData

struct InvoiceTemplateTest: View {
    @Environment(\.modelContext) var modelContext
    
    var project: Project
    
    var company = Company()
    
    var body: some View {
        
        let total = project.calculateFeeTotal(items: project.items ?? [])
        
        VStack{
            VStack{
                Text(company.name)
                    .font(.largeTitle)
                Text(company.contact)
            }
            
            
            VStack{
                Text(project.client?.name ?? "")
                Text(project.artist)
                Text(project.projectName)
                Text(project.jobDate.formatted(date: .numeric, time: .omitted))
            }
            
            Text(total.formatted(.currency(code: "USD")))
        }
        .padding()
        
        Spacer()
    }
}

#Preview {
    InvoiceTemplateTest(project: Project())
}
