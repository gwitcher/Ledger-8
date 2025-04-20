//
//  Client.swift
//  Ledger 8
//
//  Created by Gabe Witcher on 4/19/25.
//

import Foundation
import SwiftData
import Contacts

@Model
class Client {
    var givenName: String
    var familyName: String
    var email: String
    var phone: String
    var address: String
    var city: String
    var state: String
    var zip: String
    var companyName: String
    var project: Project?
    
    init(
        givenName: String = "",
        familyName: String = "",
        email: String = "",
        phone: String = "",
        address: String = "",
        city: String = "",
        state: String = "",
        zip: String = "",
        companyName: String = ""
    ) {
        self.givenName = givenName
        self.familyName = familyName
        self.email = email
        self.phone = phone
        self.address = address
        self.city = city
        self.state = state
        self.zip = zip
        self.companyName = companyName
    }
    
}


