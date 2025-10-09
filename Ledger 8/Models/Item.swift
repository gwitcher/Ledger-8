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
    var notes: String
    var project: Project?
    
    init(
        name: String = "",
        fee: Double = .zero,
        itemType: ItemType = .overdub,
        notes: String = "",
        project: Project? = nil
    ) {
        self.name = name
        self.fee = fee
        self.itemType = itemType
        self.notes = notes
        self.project = project
    }
    
    
    
    var icon: FontAwesomeCode {
        switch itemType {
        case .session:
                .music
        case .overdub:
                .music
        case .concert:
                .ticket_alt
        case .tour:
                .bus
        case .perDiem:
                .dollar_sign
        case .arrangement:
                .book_open
        case .score:
                .book_open
        case .production:
                .wave_square
        case .rehearsal:
                .clock
        case .rental:
                .receipt
        case .reimbursement:
                .dollar_sign
        case .lesson:
                .graduation_cap
//        case .halfLesson:
//                .graduation_cap
        case .other:
                .question
        case .demo:
                .music
        }
    }
}
