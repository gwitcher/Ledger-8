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
    
    var project: [Project]?
    
    init(
        id: UUID = UUID(),
        name: String = "",
        email: String = "",
        phone: String = ""
    ) {
        self.id = id
        self.name = name
        self.email = email
        self.phone = phone
    }
}

