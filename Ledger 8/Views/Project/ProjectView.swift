//
//  ProjectEntryView.swift
//  Ledger 7
//
//  Created by Gabe Witcher on 3/27/25.
//

import SwiftUI
import SwiftData
import SwiftUIFontIcon


struct ProjectView: View {
    
    var project: Project
    
    var body: some View {
        HStack(spacing: 20){
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.mintyFresh3.opacity(0.6))
                .frame(width: 44, height: 44)
                .overlay {
                    FontIcon.text(.awesome5Solid(code: project.icon), fontsize: 24, color: Color.quiteClear2)
                }
            VStack(alignment: .leading, spacing: 6) {
                
                Text(project.client?.fullName ?? "Add Client")
            
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .bold()
                    .lineLimit(1)
                
                Text(project.projectName)
                    .font(.footnote)
                    .foregroundStyle(.primary)
                    .opacity(0.7)
                    .lineLimit(1)
                
                Text(project.startDate.formatted(date: .abbreviated, time: .omitted))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    //.opacity(0.7)
                
            }
            
            Spacer()
            
            VStack (alignment: .trailing, spacing: 6) {
              
                Text("\(project.calculateFeeTotal(items: project.items!).formatted(.currency(code: "USD")))")
                    .font(.subheadline)
                    .foregroundStyle(project.status.statusColor)
                    .bold()
                    .lineLimit(1)
                
                Text("\(project.mediaType.rawValue)")
              
                    .font(.footnote)
                    .foregroundStyle(.primary)
                    .opacity(0.7)
                    .lineLimit(1)
                
                Text(" ^[\(project.items?.count ?? 0) Items](inflect: true)")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    //.opacity(0.7)
                
                
            }
        }
        .padding([.top, .bottom], 6)
        
    }
}

#Preview {
    ProjectView(project: Project(projectName: "Dummy", startDate: Date(), items: []))
    
}
