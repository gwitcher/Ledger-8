//
//  SettingsView.swift
//  Ledger 8
//
//  Created by Gabe Witcher on 5/10/25.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @State private var userData = UserData()
    
    var body: some View {
        
        NavigationStack {
            List {
                
                Section("User"){
                    NavigationLink {
                        UserNameView()
                    } label: {
                        HStack {
                            Image(systemName: "person")
                            Text(userData.userName)
                                .fontWeight(.bold)
                        }
                    }
                }
                
                Section("Invoice Info") {
                    NavigationLink {
                        CompanyInfoView()
                    } label: {
                        HStack {
                            Image(systemName: "building.2")
                            Text("Company Info")
                        }
                    }
                    NavigationLink {
                        BankingInfoView()
                    } label: {
                        HStack {
                            Image(systemName: "building.columns")
                            Text("Banking Info")
                        }
                    }
                }

                Toggle("Add to Calendar", systemImage: "calendar.badge.plus", isOn: $userData.addToCalendar)
                    .foregroundStyle(.black)
            }
            .navigationTitle("Settings")
            
           
            
        }
    }
}

#Preview {
    SettingsView()
}
