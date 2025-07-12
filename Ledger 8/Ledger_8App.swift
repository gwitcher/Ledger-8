//
//  Ledger_8App.swift
//  Ledger 8
//
//  Created by Gabe Witcher on 4/15/25.
//

import SwiftUI
import SwiftData

@main
struct Ledger_8App: App {
    let container: ModelContainer
    let dbName = "GigTracker"
    
    var body: some Scene {
        WindowGroup {
           //MainView()
            ContentView()
           
        }
        .modelContainer(container)
    }
    
    init() {
        let schema = Schema([Project.self])
        let config  = ModelConfiguration(dbName, schema: schema)
        do{
            container = try ModelContainer(for: schema, configurations: config)
           // container.mainContext.undoManager = UndoManager()
        } catch {
            fatalError("Could not configure the container")
        }
        
        print(URL.applicationSupportDirectory.path(percentEncoded: false))
    }
}
