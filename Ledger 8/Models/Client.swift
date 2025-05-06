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
    var name: String
    var email: String
    var phone: String
    var attention: String
    var address: String
    var address2: String
    var city: String
    var state: String
    var zip: String
    
    
    @Relationship(inverse: \Project.client) var project: [Project]?
    
    init(
        id: UUID = UUID(),
        name: String = "",
        email: String = "",
        phone: String = "",
        attention: String = "",
        address: String = "",
        address2: String = "",
        city: String = "",
        state: String = "",
        zip: String = ""
        
    ) {
        self.id = id
        self.name = name
        self.email = email
        self.phone = phone
        self.attention = attention
        self.address = address
        self.address2 = address
        self.city = city
        self.state = state
        self.zip = zip
        
    }
}

