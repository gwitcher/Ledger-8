//
//  mfgwLogoView.swift
//  Ledger 8
//
//  Created by Gabe Witcher on 4/17/25.
//

import SwiftUI


struct CompanyLogoView: View {
    
    @AppStorage("userData") var userData = UserData()
    //var company = Company()
    
    var body: some View {
        
        VStack (alignment: .leading) {
            Text(userData.company.name)
                .font(.title)
                .fontWeight(.semibold)
            
            Text(userData.company.contact)
                .font(.headline)
                .fontWeight(.medium)
                .foregroundStyle(.opacity(0.7))
            Group {
                Text(userData.company.address)
                Text(userData.company.cityStateZip)
                Text(userData.company.phone)
                Text(userData.company.email)
            }
            .font(.subheadline)
           // .minimumScaleFactor(0.5)
            .foregroundStyle(.opacity(0.8))
        }
    }
}

#Preview {
    CompanyLogoView(userData: UserData())
}
