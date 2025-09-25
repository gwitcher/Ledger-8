//
//  ContentView.swift
//  Ledger 8
//
//  Created by Gabe Witcher on 4/15/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) var modelContext
    
    //@Query var projects: [Project]
    
    var body: some View {
        NavigationStack{
            ProjectListView()
            //MainView()
            //ClientListView()
            //UserDefaultsView()
            //Charts()
        }
        .navigationTitle("Projects")
    }
}

#Preview {
    ContentView()
}
