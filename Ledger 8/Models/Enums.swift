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
                .limeMargarita2
        case .delivered:
                .sharpEdge3
        case .closed:
                .sharpEdge5
        }
    }
    
    var statusColorDark: Color {
        switch self {
        case .open:
                .feeTotalOpen
        case .delivered:
                .feeTotalDelivered
        case .closed:
                .feeTotalClosed
        }
    }
    
    var feeTotalLabel: String {
        switch self {
        case .open:
            "UPCOMING PROJECTS"
        case .delivered:
            "PAYMENT"
        case .closed:
            "PROJECT"
        }
    }
}

enum MediaType: String, CaseIterable, Identifiable, Codable {
    case film = "Film"
    case tv = "TV"
    case recording = "Recording"
    case game = "Video Game"
    case concert = "Concert"
    case tour = "Tour"
    case lesson = "Lesson"
    case other = "Other"
    
    var id: Self {self}
}

enum ItemType: String, CaseIterable, Identifiable, Codable {
    case session = "Tracking Session"
    case overdub = "Overdub"
    case demo = "Demo"
    case rehearsal = "Rehearsal"
    case concert = "Concert"
    case tour = "Tour"
    case perDiem = "Per Diem"
    case reimbursement = "Reimbursement"
    case arrangement = "Arrangement"
    case score = "Score"
    case production = "Production Services"
    case rental = "Chart Rental"
    case lesson = "Lesson"
    //case halfLesson = "Lesson (30 mins)"
    case other = "Other"
    
    var id: Self {self}
    
}

enum ProjectField {
    case project, artist, startDate, endDate, notes
}

enum ItemField {
    case itemName, fee
}

enum clientField {
    case firstName, lastName, email, phone, attn, address, address2, city, state, zip, notes, contact, company
}

enum userField {
    case firstName, lastName
}

enum bankField {
    case bank, accountName, routing, account, zelle, venmo
}
