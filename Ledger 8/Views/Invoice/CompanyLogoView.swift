//
//  mfgwLogoView.swift
//  Ledger 8
//
//  Created by Gabe Witcher on 4/17/25.
//

import SwiftUI


struct CompanyLogoView: View {
    
    @AppStorage("userData") var userData = UserData()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Header - use company name if available, otherwise use contact
            if !userData.company.name.isEmpty {
                // Show company name as header
                Text(userData.company.name)
                    .font(.largeTitle)
                    .fontWeight(.semibold)
                
                // Show contact as subheader if available
                if !userData.company.contact.isEmpty {
                    Text(userData.company.contact)
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundStyle(.opacity(0.7))
                }
            } else if !userData.company.contact.isEmpty {
                // Use contact as header when company name is empty
                Text(userData.company.contact)
                    .font(.largeTitle)
                    .fontWeight(.semibold)
            }
            // Note: No fallback - validation should prevent reaching this view without valid data
            
            // Address line - only show if at least one address field has content
            let addressLine = buildAddressLine()
            if !addressLine.isEmpty {
                Text(addressLine)
                    .font(.subheadline)
                    .foregroundStyle(.opacity(0.8))
            }
            
            // City, State, Zip - only show if not empty
            if !userData.company.cityStateZip.isEmpty {
                Text(userData.company.cityStateZip)
                    .font(.subheadline)
                    .foregroundStyle(.opacity(0.8))
            }
            
            // Phone - only show if not empty
            if !userData.company.phone.isEmpty {
                Text(userData.company.phone)
                    .font(.subheadline)
                    .foregroundStyle(.opacity(0.8))
            }
            
            // Email - only show if not empty
            if !userData.company.email.isEmpty {
                Text(userData.company.email)
                    .font(.subheadline)
                    .foregroundStyle(.opacity(0.8))
            }
        }
        .minimumScaleFactor(0.5)
    }
    
    private func buildAddressLine() -> String {
        let address1 = userData.company.address.trimmingCharacters(in: .whitespacesAndNewlines)
        let address2 = userData.company.address2.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if !address1.isEmpty && !address2.isEmpty {
            return "\(address1)  \(address2)"
        } else if !address1.isEmpty {
            return address1
        } else if !address2.isEmpty {
            return address2
        } else {
            return ""
        }
    }
}


#Preview("Default/Empty Data") {
    var userData = UserData()
    userData.company.contact = "Preview Test Contact"  // Add minimal data for preview
    return CompanyLogoView(userData: userData)
}

#Preview("Complete Company Data") {
    var userData = UserData()
    userData.company.name = "Acme Design Studios"
    userData.company.contact = "John Smith, Creative Director"
    userData.company.address = "123 Main Street"
    userData.company.address2 = "Suite 400"
    userData.company.city = "New York"
    userData.company.state = "NY"
    userData.company.zip = "10001"
    userData.company.phone = "(555) 123-4567"
    userData.company.email = "info@acmedesign.com"
    
    return CompanyLogoView(userData: userData)
        .padding()
}

#Preview("Minimal Company Data") {
    var userData = UserData()
    userData.company.name = "Simple Studios"
    userData.company.phone = "(555) 987-6543"
    userData.company.email = "hello@simple.com"
    
    return CompanyLogoView(userData: userData)
        .padding()
}

#Preview("Address Only") {
    var userData = UserData()
    userData.company.name = "Local Business"
    userData.company.address = "456 Oak Avenue"
    userData.company.city = "Portland"
    userData.company.state = "OR"
    userData.company.zip = "97201"
    
    return CompanyLogoView(userData: userData)
        .padding()
}

#Preview("Contact as Header") {
    var userData = UserData()
    userData.company.contact = "Jane Doe, Freelance Designer"
    userData.company.phone = "(555) 123-4567"
    userData.company.email = "jane@example.com"
    userData.company.address = "789 Creative Lane"
    userData.company.city = "Austin"
    userData.company.state = "TX"
    userData.company.zip = "78701"
    
    return CompanyLogoView(userData: userData)
        .padding()
}
