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
        "\(city), \(state) \(zip)"
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

@Model
class UserData: Identifiable {
    var userName: String
    var company: Company
    var bankingInfo: BankingInfo
    var addToCalendar: Bool
    
    init(userName: String = "", company: Company = Company(), bankingInfo: BankingInfo = BankingInfo(), addToCalendar: Bool = false) {
        self.userName = userName
        self.company = company
        self.bankingInfo = bankingInfo
        self.addToCalendar = addToCalendar
    }
}
