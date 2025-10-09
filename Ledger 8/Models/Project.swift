//
//  Project.swift
//  Ledger 8
//
//  Created by Gabe Witcher on 4/15/25.
//

import Foundation
import SwiftData
import SwiftUIFontIcon
import Contacts


@Model
class Project: Identifiable {
    var projectName: String
    var artist:String
    var startDate: Date
    var endDate: Date
    var status: Status
    var mediaType: MediaType
    var notes: String
    var delivered: Bool
    var paid: Bool
    var dateOpened: Date
    var dateDelivered: Date
    var dateClosed: Date
    var endDateSelected: Bool
    
    @Relationship(deleteRule: .cascade)var invoice: Invoice?
    @Relationship(deleteRule: .cascade) var items: [Item]?
    @Relationship var client: Client?
    
    
    init(
        projectName: String = "",
        artist: String = "",
        startDate: Date = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date())!,
        endDate: Date = Calendar.current.date(bySettingHour: 10, minute: 0, second: 0, of: Date())!,
        status: Status = Status.open,
        mediaType: MediaType = MediaType.recording,
        notes: String = "",
        delivered: Bool = false,
        paid: Bool = false,
        dateOpened: Date = Date.now,
        dateDelivered: Date = Date.distantPast,
        dateClosed: Date = Date.distantFuture,
        endDateSelected: Bool = false,
        items: [Item] = []
    ) {
        self.projectName = projectName
        self.artist = artist
        self.startDate = startDate
        self.endDate = endDate
        self.status = status
        self.mediaType = mediaType
        self.notes = notes
        self.delivered = delivered
        self.paid = paid
        self.dateOpened = dateOpened
        self.dateDelivered = dateDelivered
        self.dateClosed = dateClosed
        self.endDateSelected = endDateSelected
        self.items = [Item]()
    }
    
    var icon: FontAwesomeCode {
        switch mediaType {
        case .film:
                .film
        case .tv:
                .tv
        case .recording:
                .microphone
        case .concert:
                .users
        case .tour:
                .bus
        case .lesson:
                .graduation_cap
        case .other:
                .question
        case .game:
                .gamepad
        }
    }
}



