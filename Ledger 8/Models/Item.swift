//
//  Item.swift
//  Ledger 8
//
//  Created by Gabe Witcher on 4/15/25.
//

import Foundation
import SwiftData
import SwiftUIFontIcon

@Model
class Item: Identifiable {
    var name: String
    var fee: Double
    var itemType: ItemType
    
    init(
        name: String = "",
        fee: Double = .zero,
        itemType: ItemType = .overdub,
        project: Project? = nil
    ) {
        self.name = name
        self.fee = fee
        self.itemType = itemType
        self.project = project
    }
    
    var project: Project?
    
    var icon: FontAwesomeCode {
        switch itemType {
        case .session:
                .compact_disc
        case .overdub:
                .compact_disc
        case .concert:
                .broadcast_tower
        case .arrangement:
                .book_open
        case .score:
                .book_open
        case .production:
                .wave_square
        case .rehearsal:
                .music
        case .rental:
                .receipt
        case .hourLesson:
                .school
        case .halfLesson:
                .school
        }
    }
}
