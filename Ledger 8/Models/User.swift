//
//  User.swift
//  Ledger 8
//
//  Created by Gabe Witcher on 5/7/25.
//
import SwiftUI
import SwiftData

struct Company: Codable {
    var name = "MFGW Family Group, INC"
    var contact = "Gabe Witcher | Mary Faber"
    var address = "1132 N Reese Pl"
    var address2 = ""
    var city = "Burbank"
    var state = "CA"
    var zip = "91506"
    var phone = "818-554-7384"
    var email = "gabewitcher@gmail.com"
    
    var cityStateZip: String {
        "\(city), \(state) \(zip)"
    }
}

struct BankingInfo: Codable {
    var bank = "Chase"
    var routingNumber = "021000021"
    var accountNumber = "4152749337"
    var accountName = "Gabriel Witcher"
    var zelle = "gabewitcher@gmail.com"
    var venmo = "@Gabriel-Witcher"
}

@Model
class UserData: Identifiable {
    var userName: String
    var company: Company
    var bankingInfo: BankingInfo
    var addToCalendar: Bool
    
    init(userName: String = "Gabe Witcher", company: Company = Company(), bankingInfo: BankingInfo = BankingInfo(), addToCalendar: Bool = false) {
        self.userName = userName
        self.company = company
        self.bankingInfo = bankingInfo
        self.addToCalendar = addToCalendar
    }
}
