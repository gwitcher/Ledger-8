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

    // MARK: - Business Logic Methods
    
    /// Calculates the total fee for all items in this project
    var totalFee: Double {
        calculateFeeTotal()
    }
    
    /// Calculates the total fee for the project's items
    /// - Parameter items: Optional array of items to calculate from. If nil, uses project's items
    /// - Returns: The sum of all item fees
    func calculateFeeTotal(items: [Item]? = nil) -> Double {
        let itemsToCalculate = items ?? self.items ?? []
        return itemsToCalculate.reduce(0.0) { total, item in
            total + item.fee
        }
    }
    
    /// Calculates fees by item type for detailed breakdowns
    /// - Returns: Dictionary mapping ItemType to total fees
    func feesByItemType() -> [ItemType: Double] {
        guard let items = self.items else { return [:] }
        
        var feesByType: [ItemType: Double] = [:]
        for item in items {
            feesByType[item.itemType, default: 0.0] += item.fee
        }
        return feesByType
    }
    
    // MARK: - Status Management
    
    /// Updates project status based on delivered and paid flags
    func updateStatus() {
        if delivered && paid {
            status = .closed
        } else if delivered && !paid {
            status = .delivered
        } else if !delivered && paid {
            status = .closed // Paid without delivery still closes project
        } else {
            status = .open
        }
    }
    
    /// Marks project as delivered and sets delivery date if not already set
    func markAsDelivered() {
        delivered = true
        if dateDelivered == Date.distantPast {
            dateDelivered = Date.now
        }
        updateStatus()
    }
    
    /// Marks project as paid and sets closed date if not already set
    func markAsPaid() {
        paid = true
        if dateClosed == Date.distantFuture {
            dateClosed = Date.now
        }
        // Auto-mark as delivered when paid if not already
        if !delivered {
            markAsDelivered()
        }
        updateStatus()
    }
    
    /// Resets project to open status
    func markAsOpen() {
        delivered = false
        paid = false
        dateDelivered = Date.distantPast
        dateClosed = Date.distantFuture
        updateStatus()
    }
    
    /// Returns items sorted by fee (highest to lowest)
    var itemsSortedByFee: [Item] {
        guard let items = self.items else { return [] }
        return items.sorted { $0.fee > $1.fee }
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
