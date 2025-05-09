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


