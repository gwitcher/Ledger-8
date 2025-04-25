//
//  AddInvoiceView.swift
//  Ledger 8
//
//  Created by Gabe Witcher on 4/24/25.
//

import SwiftUI
import SwiftData

struct AddInvoiceView: View {
    @Environment(\.modelContext) var modelContext
    
    var project: Project
    
    var body: some View {
                        Button {
                            _ = project.render(project: project)
                        } label: {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundStyle(.green)
                                Text("Add Invoice")
                                    .tint(.primary)
                            }
                        }
    }
}

#Preview {
    AddInvoiceView(project: Project())
}
