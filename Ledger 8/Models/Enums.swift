//
//  Enums.swift
//  Ledger 8
//
//  Created by Gabe Witcher on 4/16/25.
//

import Foundation
import SwiftUI

enum Status: String, CaseIterable, Identifiable, Codable {
    case open = "Open"
    case delivered = "Delivered"
    case closed = "Paid"
    
    var id: Self {self}
    
    var statusColor: Color {
        switch self {
        case .open:
                .yellow
        case .delivered:
                .red
        case .closed:
                .green
        }
    }
    
    var feeTotalLabel: String {
        switch self {
        case .open:
            "UPCOMING PROJECTS"
        case .delivered:
            "PAYMENTS"
        case .closed:
            "PROJECTS PAID"
        }
    }
}

enum MediaType: String, CaseIterable, Identifiable, Codable {
    case film = "Film"
    case tv = "TV"
    case recording = "Recording"
    case concert = "Concert"
    case lesson = "Lesson"
    case other = "Other"
    
    var id: Self {self}
}

enum ItemType: String, CaseIterable, Identifiable, Codable {
    case session = "Recording Session"
    case overdub = "Overdub"
    case concert = "Concert"
    case arrangement = "Arrangement"
    case score = "Score"
    case production = "Production Services"
    case rehearsal = "Rehearsal"
    case rental = "Chart Rental"
    case hourLesson = "Lesson (1 hr)"
    case halfLesson = "Lesson (30 mins)"
    
    var id: Self {self}
    
}
