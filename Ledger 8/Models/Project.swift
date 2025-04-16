//
//  Project.swift
//  Ledger 8
//
//  Created by Gabe Witcher on 4/15/25.
//

import Foundation
import SwiftData


@Model
class Project: Identifiable {
    var client: String
    var projectName: String
    var jobDate: Date
    
    @Relationship(deleteRule: .cascade) var items: [Item]?
    
    
    init(
        client: String = "",
        projectName: String = "",
        jobDate: Date = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date())!,
        items: [Item] = []
    ) {
        self.client = client
        self.projectName = projectName
        self.jobDate = jobDate
        self.items = [Item]()
    }
    
    
}
