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
    @AppStorage("onboard_complete") var onboardComplete: Bool = false
    @StateObject var locationManager = LocationManager()

    let container: ModelContainer
    let dbName = "GigTracker"
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(locationManager)
                .fullScreenCover(isPresented: .constant(!onboardComplete)) {
                    OnboardingGradientView()
                }
                
           
        }
        .modelContainer(container)
    }
    
    init() {
        let schema = Schema([Project.self, Item.self, Client.self, Invoice.self])
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
