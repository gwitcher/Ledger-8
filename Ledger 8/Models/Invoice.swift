//
//  Invoice.swift
//  Ledger 8
//
//  Created by Gabe Witcher on 4/17/25.
//

import Foundation
import SwiftData

@Model
class Invoice: Identifiable {
    var number: Int
    var name: String
    var url: URL?
    
    init(number: Int, name: String, url: URL? = nil) {
        self.number = number
        self.name = name
        self.url = url
    }
}

struct Company {
    var name = "MFGW Family Group, Inc."
    let contact = "Gabe Witcher | Mary Faber"
    let address = "1132 N Reese Pl"
    let cityStateZip = "Burbank, CA 91506"
    let phone = "818-554-7384"
    let email = "gabewitcher@gmail.com"
}
