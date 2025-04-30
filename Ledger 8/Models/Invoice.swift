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
    var id: UUID
    var number: Int
    var invoiceDate: Date
    var name: String
    var urlString: String?
    var project: Project?
    
    init(
        id: UUID = UUID(),
        number: Int = 0,
        invoiceDate: Date = Date.now,
        name: String = "",
        urlString: String?
    ) {
        self.id = id
        self.number = number
        self.invoiceDate = invoiceDate
        self.name = name
        
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
