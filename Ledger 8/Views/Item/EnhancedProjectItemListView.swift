//
//  EnhancedProjectItemListView.swift
//  Ledger 8
//
//  Created by Assistant on 10/26/25.
//

import SwiftUI
import SwiftData

struct EnhancedProjectItemListView: View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    var project: Project
    
    @State private var sheetIsPresented = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                RadialGradient(
                    gradient: Gradient(colors: [Color.quiteClear1, Color.quiteClear4.opacity(0.2)]),
                    center: .top,
                    startRadius: 100,
                    endRadius: UIScreen.main.bounds.height
                )
                .ignoresSafeArea()
                
                EnhancedItemListView(
                    items: project.items ?? [],
                    onItemTap: nil
                )
            }
            .navigationTitle(project.projectName)
            .navigationBarTitleDisplayMode(.automatic)
            .toolbarColorScheme(colorScheme == .light ? .light : .dark)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .bottomBar) {
                    Button {
                        sheetIsPresented.toggle()
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(.green)
                            Text("Add Item")
                                .tint(.primary)
                        }
                    }
                }
            }
            .sheet(isPresented: $sheetIsPresented) {
                ItemDetailView(project: project)
            }
        }
    }
}
