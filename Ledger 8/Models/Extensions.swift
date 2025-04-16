//
//  Extensions.swift
//  Ledger 8
//
//  Created by Gabe Witcher on 4/16/25.
//

import Foundation
import SwiftUI

extension Project {
    
    func calculateFeeTotal(items: [Item] ) -> Double {
        var total = 0.0
        for item in items {
            total += item.fee
        }
        return total
    }
    
    
}
