//
//  mfgwLogoView.swift
//  Ledger 8
//
//  Created by Gabe Witcher on 4/17/25.
//

import SwiftUI


struct CompanyLogoView: View {
    
    @AppStorage("userData") var userData = UserData()
    //var userData = UserData()
    //var company = Company()
    
    var body: some View {
        
        VStack (alignment: .leading) {
            Text(userData.company.name)
                .font(.largeTitle)
                .fontWeight(.semibold)
            
            Text(userData.company.contact)
                .font(.headline)
                .fontWeight(.medium)
                .foregroundStyle(.opacity(0.7))
            Group {
                Text(userData.company.address + "  " + userData.company.address2)
                Text(userData.company.cityStateZip)
                Text(userData.company.phone)
                Text(userData.company.email)
            }
            .font(.subheadline)
            .foregroundStyle(.opacity(0.8))
        }
        .minimumScaleFactor(0.5)
    }
}

#Preview {
    CompanyLogoView(userData: UserData())
}
