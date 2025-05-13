//
//  UserNameView.swift
//  Ledger 8
//
//  Created by Gabe Witcher on 5/10/25.
//

import SwiftUI


struct UserNameView: View {
    
    @AppStorage("userData") var userData = UserData()
    
    var body: some View {
        NavigationStack{
            Form {
                Section("User Name"){
                    TextField("User Name", text: $userData.userName)
                }
            }
            .navigationTitle("User Info")
        }
    }
}

#Preview {
    UserNameView(userData: UserData())
}
