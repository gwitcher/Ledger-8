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

    // Invoice update tracking
    var invoiceUpdateFlag: Bool = false

    // ADD THIS LINE
    var location: Spot?

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
        items: [Item] = [],
        location: Spot? = nil // <--- Add this default parameter
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
        self.location = location
    }

    // MARK: - Business Logic Methods (Consider moving to ViewModel)
    func calculateFeeTotal(items: [Item]?) -> Double {
        guard let items = items else { return 0.0 }
        return items.reduce(0) { $0 + $1.fee }
    }
    
    // Computed property to check if invoice needs updating
    var invoiceNeedsUpdate: Bool {
        guard invoice != nil else { return false }
        return invoiceUpdateFlag
    }
    
    // Helper functions to manage invoice update flag
    func flagInvoiceForUpdate() {
        if invoice != nil {
            invoiceUpdateFlag = true
        }
    }
    
    func clearInvoiceUpdateFlag() {
        invoiceUpdateFlag = false
    }
    
    // Call this when invoice is deleted
    func deleteInvoice() {
        invoice = nil
        invoiceUpdateFlag = false
    }
}
