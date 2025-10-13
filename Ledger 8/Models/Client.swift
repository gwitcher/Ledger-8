//
//  Contact.swift
//  Ledger 8
//
//  Created by Gabe Witcher on 4/22/25.
//

import Foundation
import SwiftData

@Model
class Client: Identifiable {
    var id: UUID
    var firstName: String
    var lastName: String
    var email: String
    var phone: String
    var attention: String
    var address: String
    var address2: String
    var city: String
    var state: String
    var zip: String
    var notes: String
    var company: String
    
    
    
    @Relationship(inverse: \Project.client) var project: [Project]?
    
    
    var fullName: String {
        let first = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        let last = lastName.trimmingCharacters(in: .whitespacesAndNewlines)
        let comp = company.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if !last.isEmpty && !first.isEmpty {
            return "\(first) \(last)"
        } else if !last.isEmpty {
            return last
        } else if !first.isEmpty {
            return first
        } else if !comp.isEmpty {
            return comp
        } else {
            return "Unnamed Contact"
        }
    }
    
    init(
        id: UUID = UUID(),
        firstName: String = "",
        lastName: String = "",
        email: String = "",
        phone: String = "",
        attention: String = "",
        address: String = "",
        address2: String = "",
        city: String = "",
        state: String = "",
        zip: String = "",
        notes: String = "",
        company: String = ""
        
    ) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.phone = phone
        self.attention = attention
        self.address = address
        self.address2 = address2
        self.city = city
        self.state = state
        self.zip = zip
        self.notes = notes
        self.company = company
        
    }
}

