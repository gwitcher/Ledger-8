//
//  User.swift
//  Ledger 8
//
//  Created by Gabe Witcher on 5/7/25.
//
import SwiftUI
import SwiftData

struct Company: Codable {
    var name = ""
    var contact = ""
    var address = ""
    var address2 = ""
    var city = ""
    var state = ""
    var zip = ""
    var phone = ""
    var email = ""
    
    var cityStateZip: String {
        let trimmedCity = city.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedState = state.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedZip = zip.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // If all are empty, return empty string
        if trimmedCity.isEmpty && trimmedState.isEmpty && trimmedZip.isEmpty {
            return ""
        }
        
        // Build the string dynamically
        var result = ""
        
        if !trimmedCity.isEmpty {
            result += trimmedCity
        }
        
        if !trimmedState.isEmpty {
            if !result.isEmpty {
                result += ", "
            }
            result += trimmedState
        }
        
        if !trimmedZip.isEmpty {
            if !result.isEmpty {
                result += " "
            }
            result += trimmedZip
        }
        
        return result
    }
    
    /// Returns true if the company has enough information to create an invoice
    /// Requires either a company name or contact information
    var isValidForInvoice: Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedContact = contact.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmedName.isEmpty || !trimmedContact.isEmpty
    }
}

struct BankingInfo: Codable {
    var bank = ""
    var routingNumber = ""
    var accountNumber = ""
    var accountName = ""
    var zelle = ""
    var venmo = ""
}


struct UserData: Codable {
    var userFirstName = ""
    var userLastName = ""
    var company = Company()
    var bankingInfo = BankingInfo()
    var addToCalendar = false
    
    init() {}
    
    enum CodingKeys: CodingKey {
        case userFirstName
        case userLastName
        case company
        case bankingInfo
        case addToCalendar
    }
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.userFirstName = try container.decode(String.self, forKey: .userFirstName)
        self.userLastName = try container.decode(String.self, forKey: .userLastName)
        self.company = try container.decode(Company.self, forKey: .company)
        self.bankingInfo = try container.decode(BankingInfo.self, forKey: .bankingInfo)
        self.addToCalendar = try container.decode(Bool.self, forKey: .addToCalendar)
    }
    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.userFirstName, forKey: .userFirstName)
        try container.encode(self.userLastName, forKey: .userLastName)
        try container.encode(self.company, forKey: .company)
        try container.encode(self.bankingInfo, forKey: .bankingInfo)
        try container.encode(self.addToCalendar, forKey: .addToCalendar)
    }
}


extension UserData: RawRepresentable {
    var rawValue: String {
        guard let data = try? JSONEncoder().encode(self),
              let userDataString = String(data: data, encoding: .utf8)
        else {
            return "{}"
        }
        return userDataString
    }
    
     init?(rawValue: String) {
        guard let data = rawValue.data(using: .utf8 ),
              let userData = try? JSONDecoder().decode(UserData.self, from: data)
        else {
            return nil
        }
        self = userData
                
    }
}

