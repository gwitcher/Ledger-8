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
    @StateObject private var undoManager = AppUndoManager()
    
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
        .environmentObject(undoManager)
        .onShake {
            if undoManager.canUndo {
                undoManager.performUndo(in: modelContext)
            }
        }
        .alert("Undo Successful", isPresented: $undoManager.showingUndoAlert) {
            Button("OK") { }
        } message: {
            if let description = undoManager.lastActionDescription {
                Text("Undid: \(description)")
            } else {
                Text("The last delete action has been undone.")
            }
        }
    }
}

#Preview {
    ContentView()
}
