//
//  MainView.swift
//  Ledger 8
//
//  Created by Gabe Witcher on 4/23/25.
//

import SwiftUI


struct MainView: View {
    var body: some View {
        TabView {
            ProjectListView()
                .tabItem {
                    Label("Projects", systemImage: "list.bullet.circle")
                }
            
            ClientListView()
                .tabItem {
                    Label("Clients", systemImage: "person.crop.circle")
                }
        }
    }
}

#Preview {
    MainView()
}
