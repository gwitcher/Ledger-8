//
//  ItemListView2.swift
//  Ledger 8
//
//  Created by Gabe Witcher on 9/22/25.
//

import SwiftUI
import SwiftData

struct ItemListView2: View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    var project: Project
    
    @State private var sheetIsPresented = false
    
    //@State private var itemEditIsPresented = false
    
    var body: some View {
        
        ZStack{
            RadialGradient(
                gradient: Gradient(colors: [Color.quiteClear1, Color.quiteClear4.opacity(0.2)]),
                center: .top,
                startRadius: 100,
                endRadius: UIScreen.main.bounds.height)
            .ignoresSafeArea()
            VStack {
                //HStack{
                
                Text("Total: \(project.calculateFeeTotal(items: project.items!).formatted(.currency(code: "USD")))")
                
                //}
                    .padding(20)
                    .font(.title2)
                    .fontWeight(.bold)
                    //.border(.red)
                //.opacity(0.7)
                
                
                List {
                    ForEach(project.items ?? []) {item in
                        NavigationLink {
                            ItemEditView(item: item)
                        } label: {
                            ItemView(item: item)
                        }
                        .swipeActions {
                            Button("Delete", role: .destructive) {
                                modelContext.delete(item)
                                
                                guard let _ = try? modelContext.save() else {
                                    print("😡 ERROR: Could not save after delete")
                                    return
                                }
                            }
                        }
                    }
                }
                //.listStyle(.sidebar)
                .padding(10)
            }
        }
        .navigationTitle(project.projectName)
        .navigationBarTitleDisplayMode(.automatic)
        .toolbarColorScheme( colorScheme == .light ? .light : .dark)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .status) {
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

//#Preview {
//    ItemListView2()
//}
