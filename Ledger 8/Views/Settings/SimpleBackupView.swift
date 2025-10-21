//
//  SimpleBackupView.swift
//  Ledger 8
//
//  Created for testing backup view compilation
//

import SwiftUI
import SwiftData

struct SimpleBackupView: View {
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Backup & Restore")
                    .font(.title)
                    .padding()
                
                Text("Feature coming soon...")
                    .foregroundColor(.secondary)
            }
            .navigationTitle("Backup")
        }
    }
}

#Preview {
    SimpleBackupView()
}