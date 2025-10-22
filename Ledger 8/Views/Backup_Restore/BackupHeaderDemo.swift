//
//  BackupHeaderDemo.swift
//  Ledger 8
//
//  Demo and testing utilities for the magic header implementation
//

import Foundation

/// Demo utilities for testing and exploring the magic header functionality
struct BackupHeaderDemo {
    
    /// Demonstrates the magic header implementation
    static func demonstrateMagicHeader() {
        print("=== Ledger 8 Backup Magic Header Demo ===\n")
        
        // Show the magic header bytes
        let magicHeader = Data([0x4C, 0x38, 0x42, 0x41, 0x43, 0x4B, 0x55, 0x50, 0x00])
        print("Magic Header (9 bytes):")
        print("  ASCII: L8BACKUP\\0")
        print("  Hex:   \(magicHeader.map { String(format: "%02X", $0) }.joined(separator: " "))")
        print("  Bytes: \(Array(magicHeader))")
        print()
        
        // Demo JSON data
        let sampleJSON = """
        {
            "metadata": {
                "appVersion": "Ledger 8",
                "backupVersion": "2.0",
                "createdDate": "2025-10-21T12:00:00Z"
            },
            "clients": [],
            "projects": []
        }
        """.data(using: .utf8)!
        
        print("Sample JSON data (\(sampleJSON.count) bytes):")
        print(String(data: sampleJSON, encoding: .utf8) ?? "Invalid JSON")
        print()
        
        // Create file with magic header
        var backupFileData = Data()
        backupFileData.append(magicHeader)
        backupFileData.append(sampleJSON)
        
        print("Complete backup file (\(backupFileData.count) bytes):")
        print("  Header (9 bytes): \(backupFileData.prefix(9).map { String(format: "%02X", $0) }.joined(separator: " "))")
        print("  JSON starts at byte 10: \"\(String(data: backupFileData.dropFirst(9).prefix(20), encoding: .utf8) ?? "")...\"")
        print()
        
        // Test validation
        print("=== Header Validation Tests ===")
        
        // Test 1: Valid backup file
        let isValid = BackupHeaderValidator.isValidBackupFile(backupFileData)
        print("1. File with magic header: \(isValid ? "✅ VALID" : "❌ INVALID")")
        
        // Test 2: JSON only (legacy)
        let jsonOnlyValid = BackupHeaderValidator.isValidBackupFile(sampleJSON)
        print("2. JSON-only file (legacy): \(jsonOnlyValid ? "✅ VALID" : "❌ INVALID (expected)")")
        
        // Test 3: Random data
        let randomData = Data([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]) // PNG header
        let randomValid = BackupHeaderValidator.isValidBackupFile(randomData)
        print("3. Random data (PNG header): \(randomValid ? "✅ VALID" : "❌ INVALID (expected)")")
        
        // Test 4: Short file
        let shortData = Data([0x4C, 0x38, 0x42]) // Only "L8B"
        let shortValid = BackupHeaderValidator.isValidBackupFile(shortData)
        print("4. Short file (3 bytes): \(shortValid ? "✅ VALID" : "❌ INVALID (expected)")")
        
        print()
        
        // Test extraction
        print("=== Data Extraction Tests ===")
        
        let extraction1 = BackupHeaderValidator.extractJSONData(from: backupFileData)
        print("1. File with header:")
        print("   Has header: \(extraction1.hasHeader)")
        print("   JSON size: \(extraction1.jsonData.count) bytes")
        print("   JSON preview: \"\(String(data: extraction1.jsonData.prefix(30), encoding: .utf8) ?? "")...\"")
        
        let extraction2 = BackupHeaderValidator.extractJSONData(from: sampleJSON)
        print("2. Legacy JSON file:")
        print("   Has header: \(extraction2.hasHeader)")
        print("   JSON size: \(extraction2.jsonData.count) bytes")
        print("   JSON preview: \"\(String(data: extraction2.jsonData.prefix(30), encoding: .utf8) ?? "")...\"")
    }
    
    /// Creates a test backup file with magic header for manual inspection
    static func createTestBackupFile() -> URL? {
        let sampleBackup = """
        {
            "metadata": {
                "appVersion": "Ledger 8",
                "backupVersion": "2.0",
                "createdDate": "\(ISO8601DateFormatter().string(from: Date()))",
                "deviceName": "Demo Device"
            },
            "clients": [
                {
                    "firstName": "John",
                    "lastName": "Doe",
                    "email": "john.doe@example.com",
                    "company": "Demo Company"
                }
            ],
            "projects": [],
            "items": []
        }
        """.data(using: .utf8)!
        
        // Create file with magic header
        let magicHeader = Data([0x4C, 0x38, 0x42, 0x41, 0x43, 0x4B, 0x55, 0x50, 0x00])
        var fileData = Data()
        fileData.append(magicHeader)
        fileData.append(sampleBackup)
        
        // Save to Documents/Backups folder
        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("❌ Could not access Documents directory")
            return nil
        }
        
        let backupsURL = documentsURL.appendingPathComponent("Backups")
        
        do {
            try FileManager.default.createDirectory(at: backupsURL, withIntermediateDirectories: true)
            
            let fileURL = backupsURL.appendingPathComponent("Demo_MagicHeader_Test.l8backup")
            try fileData.write(to: fileURL)
            
            print("✅ Test backup file created: \(fileURL.path)")
            print("   File size: \(fileData.count) bytes")
            print("   Header size: 9 bytes")
            print("   JSON size: \(sampleBackup.count) bytes")
            
            return fileURL
        } catch {
            print("❌ Failed to create test file: \(error)")
            return nil
        }
    }
}

/// Validator utilities (duplicated here for testing purposes)
fileprivate struct BackupHeaderValidator {
    static let magicHeader = Data([0x4C, 0x38, 0x42, 0x41, 0x43, 0x4B, 0x55, 0x50, 0x00])
    static let headerLength = 9
    
    static func isValidBackupFile(_ data: Data) -> Bool {
        guard data.count >= headerLength else { return false }
        let headerData = data.prefix(headerLength)
        return headerData == magicHeader
    }
    
    static func extractJSONData(from data: Data) -> (hasHeader: Bool, jsonData: Data) {
        if isValidBackupFile(data) {
            let jsonData = data.dropFirst(headerLength)
            return (hasHeader: true, jsonData: Data(jsonData))
        } else {
            return (hasHeader: false, jsonData: data)
        }
    }
}