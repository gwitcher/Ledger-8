//
//  Project.swift
//  Ledger 8
//
//  Created by Gabe Witcher on 4/15/25.
//

import Foundation
import SwiftData
import SwiftUIFontIcon


@Model
class Project: Identifiable {
    var client: String
    var projectName: String
    var artist:String
    var jobDate: Date
    var status: Status
    var mediaType: MediaType
    var notes: String
    var delivered: Bool
    var paid: Bool
    var dateOpened: Date
    var dateDelivered: Date
    var dateClosed: Date
    
    @Relationship(deleteRule: .cascade) var items: [Item]?
    
    
    init(
        client: String = "",
        projectName: String = "",
        artist: String = "",
        jobDate: Date = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date())!,
        status: Status = Status.open,
        mediaType: MediaType = MediaType.recording,
        notes: String = "",
        invoiced: Bool = false,
        paid: Bool = false,
        dateOpened: Date = Date.now,
        dateDelivered: Date = Date.distantPast,
        dateClosed: Date = Date.distantFuture,
        items: [Item] = []
    ) {
        self.client = client
        self.projectName = projectName
        self.artist = artist
        self.jobDate = jobDate
        self.status = status
        self.mediaType = mediaType
        self.notes = notes
        self.delivered = invoiced
        self.paid = paid
        self.dateOpened = dateOpened
        self.dateDelivered = dateDelivered
        self.dateClosed = dateClosed
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
        case .lesson:
                .school
        case .other:
                .question
        }
    }
    
    
}


