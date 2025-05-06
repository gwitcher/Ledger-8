//
//  mfgwLogoView.swift
//  Ledger 8
//
//  Created by Gabe Witcher on 4/17/25.
//

import SwiftUI


struct mfgwLogoView: View {
    
    var company = Company()
    
    var body: some View {
        
        VStack (alignment: .leading) {
            Text(company.name)
                .font(.title)
                .fontWeight(.semibold)
            
            Text(company.contact)
                .font(.headline)
                .fontWeight(.medium)
                .foregroundStyle(.opacity(0.7))
            Group {
                Text(company.address)
                Text(company.cityStateZip)
                Text(company.phone)
                Text(company.email)
            }
            .font(.caption)
            .minimumScaleFactor(0.5)
            .foregroundStyle(.opacity(0.8))
        }
    }
}

#Preview {
    mfgwLogoView(company: Company())
}
