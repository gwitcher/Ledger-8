//
//  CSVTemplates.swift
//  Ledger 8
//
//  CSV Template Examples and Documentation
//

import Foundation

/*
 CSV IMPORT TEMPLATES AND EXAMPLES
 
 The CSV importer supports three main data types: Projects, Items, and Clients.
 Below are example CSV formats for each type.
 
 IMPORTANT NOTES:
 - Column headers are case-insensitive
 - Spaces and underscores in headers are handled automatically
 - Dates should be in MM/dd/yyyy, yyyy-MM-dd, or M/d/yy format
 - Boolean values can be true/false, yes/no, or 1/0
 - Items can be linked to projects by including the project name
 
 ==========================================
 PROJECTS CSV TEMPLATE:
 ==========================================
 
 ProjectName,Artist,StartDate,EndDate,Status,MediaType,Notes,Delivered,Paid
 "Album Recording Session","John Doe","01/15/2025","01/20/2025","Open","Recording","Studio session for new album",false,false
 "Concert Backup","Jane Smith","02/01/2025","02/01/2025","Open","Concert","Live performance downtown",false,false
 "Film Score","Various Artists","01/10/2025","03/15/2025","Open","Film","Soundtrack composition",false,false
 
 Valid Status values: Open, Delivered, Paid
 Valid MediaType values: Film, TV, Recording, Video Game, Concert, Tour, Lesson, Other
 
 ==========================================
 ITEMS CSV TEMPLATE:
 ==========================================
 
 Name,Fee,ItemType,Notes,Project
 "Recording Session - Day 1",500.00,"Tracking Session","8-hour session","Album Recording Session"
 "Overdub - Vocals",150.00,"Overdub","Vocal corrections","Album Recording Session"
 "Concert Performance",800.00,"Concert","Main set performance","Concert Backup"
 "Score Arrangement",1200.00,"Arrangement","Full orchestral arrangement","Film Score"
 
 Valid ItemType values: Tracking Session, Overdub, Demo, Rehearsal, Concert, Tour, 
 Per Diem, Reimbursement, Arrangement, Score, Production Services, Chart Rental, Lesson, Other
 
 ==========================================
 CLIENTS CSV TEMPLATE:
 ==========================================
 
 FirstName,LastName,Email,Phone,Company,Address,City,State,Zip,Notes
 "John","Doe","john@example.com","555-0123","Doe Records","123 Music Ave","Nashville","TN","37201","Primary contact"
 "Jane","Smith","jane@venue.com","555-0456","Downtown Venue","456 Stage St","Nashville","TN","37203","Event coordinator"
 "","","info@filmstudio.com","555-0789","Film Studio Inc","789 Cinema Blvd","Los Angeles","CA","90210","Studio contact"
 
 ==========================================
 USAGE INSTRUCTIONS:
 ==========================================
 
 1. Prepare your CSV file using the templates above
 2. Make sure your CSV file has proper headers (first row)
 3. Use the CSVImportView in your app to select and import the file
 4. The importer will automatically detect the type based on column headers
 5. Data will be validated and imported into your SwiftData models
 
 The importer handles:
 - Automatic CSV type detection
 - Data validation and type conversion
 - Progress tracking during import
 - Error handling and reporting
 - Relationship linking (Items to Projects)
 
 ==========================================
*/

// MARK: - Sample Data Generator (for testing)
struct CSVTemplateGenerator {
    
    static func generateSampleProjectsCSV() -> String {
        let header = "ProjectName,Artist,StartDate,EndDate,Status,MediaType,Notes,Delivered,Paid"
        let rows = [
            "\"Album Recording Session\",\"John Doe\",\"01/15/2025\",\"01/20/2025\",\"Open\",\"Recording\",\"Studio session for new album\",false,false",
            "\"Concert Backup\",\"Jane Smith\",\"02/01/2025\",\"02/01/2025\",\"Open\",\"Concert\",\"Live performance downtown\",false,false",
            "\"Film Score\",\"Various Artists\",\"01/10/2025\",\"03/15/2025\",\"Open\",\"Film\",\"Soundtrack composition\",false,false"
        ]
        return ([header] + rows).joined(separator: "\n")
    }
    
    static func generateSampleItemsCSV() -> String {
        let header = "Name,Fee,ItemType,Notes,Project"
        let rows = [
            "\"Recording Session - Day 1\",500.00,\"Tracking Session\",\"8-hour session\",\"Album Recording Session\"",
            "\"Overdub - Vocals\",150.00,\"Overdub\",\"Vocal corrections\",\"Album Recording Session\"",
            "\"Concert Performance\",800.00,\"Concert\",\"Main set performance\",\"Concert Backup\"",
            "\"Score Arrangement\",1200.00,\"Arrangement\",\"Full orchestral arrangement\",\"Film Score\""
        ]
        return ([header] + rows).joined(separator: "\n")
    }
    
    static func generateSampleClientsCSV() -> String {
        let header = "FirstName,LastName,Email,Phone,Company,Address,City,State,Zip,Notes"
        let rows = [
            "\"John\",\"Doe\",\"john@example.com\",\"555-0123\",\"Doe Records\",\"123 Music Ave\",\"Nashville\",\"TN\",\"37201\",\"Primary contact\"",
            "\"Jane\",\"Smith\",\"jane@venue.com\",\"555-0456\",\"Downtown Venue\",\"456 Stage St\",\"Nashville\",\"TN\",\"37203\",\"Event coordinator\"",
            "\"\",\"\",\"info@filmstudio.com\",\"555-0789\",\"Film Studio Inc\",\"789 Cinema Blvd\",\"Los Angeles\",\"CA\",\"90210\",\"Studio contact\""
        ]
        return ([header] + rows).joined(separator: "\n")
    }
}