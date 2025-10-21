//
//  SettingsView.swift
//  Ledger 8
//
//  Created by Gabe Witcher on 5/10/25.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss
    
    @AppStorage("userData") var userData = UserData()
    @AppStorage("InitialInvoiceNumber") var initialInvoiceNumber = 0
    @State private var showingCSVImport = false
    @State private var showingBackupRestore = false
    
    
    var body: some View {
        
        
        NavigationStack {
            List {
                
                Section("User"){
                    NavigationLink {
                        UserNameView(userData: userData)
                    } label: {
                        HStack {
                            Image(systemName: "person")
                            Text("\(userData.userFirstName) \(userData.userLastName)")
                                .fontWeight(.bold)
                        }
                    }
                }
                
                Section("Invoice Info") {
                    NavigationLink {
                        CompanyInfoView(userData: userData)
                    } label: {
                        HStack {
                            Image(systemName: "building.2")
                            Text("Company Info")
                        }
                    }
                    NavigationLink {
                        BankingInfoView(userData: userData)
                    } label: {
                        HStack {
                            Image(systemName: "building.columns")
                            Text("Banking Info")
                        }
                    }
                }
                
                Section("Starting Invoice Number") {
                    TextField("Beginning Invoice Number", value: $initialInvoiceNumber, format: .number.grouping(.never))
                        .font(.headline)
                        //.foregroundStyle(.primary)
                        .frame(height: 30)
                        .padding(.horizontal)
                        //.background(Color.white)
                        .cornerRadius(10)
                    
                }
                
                Section("Data Management") {
                    Button {
                        showingCSVImport = true
                    } label: {
                        HStack {
                            Image(systemName: "square.and.arrow.down")
                                .foregroundColor(.blue)
                            Text("Import CSV Data")
                        }
                    }
                    
                    Button {
                        showingBackupRestore = true
                    } label: {
                        HStack {
                            Image(systemName: "externaldrive.badge.plus")
                                .foregroundColor(.green)
                            Text("Backup & Restore")
                        }
                    }
                }
                
//                Toggle("Add to Calendar", systemImage: "calendar.badge.plus", isOn: $userData.addToCalendar)
//                    .foregroundStyle(.black)
                
                
                
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingCSVImport) {
                CSVImportView(modelContext: modelContext)
            }
            .sheet(isPresented: $showingBackupRestore) {
                CompleteBackupView()
                    .environment(\.modelContext, modelContext)
            }
        }
    }
}

#Preview {
    SettingsView()
}
