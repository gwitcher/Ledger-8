//
//  Item.swift
//  Ledger 8
//
//  Created by Gabe Witcher on 4/15/25.
//

import Foundation
import SwiftData


@Model
class Item: Identifiable {
    var name: String
    var fee: Double
    
    init(name: String, fee: Double) {
        self.name = name
        self.fee = fee
    }
    
    var project: Project?
    
    
}
