//
//  ChecksumValidationDemo.swift
//  Ledger 8
//
//  Demo and utilities for checksum validation functionality
//

import Foundation
import CryptoKit

/// Demo utilities for exploring checksum validation functionality
struct ChecksumValidationDemo {
    
    /// Demonstrates the complete checksum validation workflow
    static func demonstrateChecksumValidation() {
        print("=== Ledger 8 Checksum Validation Demo ===\n")
        
        // Sample backup data
        let sampleBackup = """
        {
            "metadata": {
                "appVersion": "Ledger 8",
                "backupVersion": "2.0",
                "backupType": "Complete",
                "createdDate": "2025-10-21T12:00:00Z",
                "deviceName": "Demo Device",
                "contentChecksum": null,
                "checksumAlgorithm": null,
                "fileSize": null
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
            "items": [],
            "invoices": []
        }
        """.data(using: .utf8)!
        
        print("1. Original backup JSON (\(sampleBackup.count) bytes)")
        print(String(data: sampleBackup, encoding: .utf8)?.prefix(200) ?? "Invalid JSON")
        print("...\n")
        
        // Calculate checksum
        let checksum = DemoChecksumValidator.calculateChecksum(for: sampleBackup)
        print("2. Calculated SHA-256 checksum:")
        print("   Full: \(checksum)")
        print("   Short: \(String(checksum.prefix(16)))... (showing first 16 chars)")
        print("   Length: \(checksum.count) characters\n")
        
        // Demonstrate file creation with magic header
        let magicHeader = Data([0x4C, 0x38, 0x42, 0x41, 0x43, 0x4B, 0x55, 0x50, 0x00])
        var completeFile = Data()
        completeFile.append(magicHeader)
        completeFile.append(sampleBackup)
        
        print("3. Complete backup file structure:")
        print("   Magic header: 9 bytes (L8BACKUP\\0)")
        print("   JSON content: \(sampleBackup.count) bytes")
        print("   Total file size: \(completeFile.count) bytes")
        print("   Header hex: \(magicHeader.map { String(format: "%02X", $0) }.joined(separator: " "))\n")
        
        // Test validation scenarios
        print("=== Validation Scenarios ===\n")
        
        // Scenario 1: Valid backup
        testValidationScenario(
            name: "Valid Backup",
            data: sampleBackup,
            storedChecksum: checksum,
            expectedResult: true
        )
        
        // Scenario 2: Corrupted backup
        var corruptedBackup = sampleBackup
        if corruptedBackup.count > 100 {
            corruptedBackup[100] = corruptedBackup[100] ^ 0xFF // Flip bits
        }
        testValidationScenario(
            name: "Corrupted Backup (1 byte changed)",
            data: corruptedBackup,
            storedChecksum: checksum,
            expectedResult: false
        )
        
        // Scenario 3: Wrong checksum
        let wrongChecksum = "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"
        testValidationScenario(
            name: "Wrong Stored Checksum",
            data: sampleBackup,
            storedChecksum: wrongChecksum,
            expectedResult: false
        )
        
        // Scenario 4: No checksum (legacy)
        testValidationScenario(
            name: "Legacy Backup (No Checksum)",
            data: sampleBackup,
            storedChecksum: nil,
            expectedResult: false
        )
        
        // Performance test
        print("\n=== Performance Test ===")
        performanceTest()
    }
    
    /// Test a specific validation scenario
    static func testValidationScenario(name: String, data: Data, storedChecksum: String?, expectedResult: Bool) {
        let result = DemoChecksumValidator.validateChecksum(jsonData: data, expectedChecksum: storedChecksum)
        let passed = result.isValid == expectedResult
        let status = passed ? "✅ PASS" : "❌ FAIL"
        
        print("\(status) \(name):")
        
        switch result {
        case .valid(let calculatedChecksum):
            print("   Result: Valid checksum")
            print("   Checksum: \(String(calculatedChecksum.prefix(16)))...")
            
        case .mismatch(let expected, let calculated):
            print("   Result: Checksum mismatch")
            print("   Expected:   \(String(expected.prefix(16)))...")
            print("   Calculated: \(String(calculated.prefix(16)))...")
            
        case .noChecksumStored:
            print("   Result: No checksum stored (legacy backup)")
        }
        print()
    }
    
    /// Performance test with different file sizes
    static func performanceTest() {
        let testSizes = [
            ("1KB", 1024),
            ("10KB", 10 * 1024),
            ("100KB", 100 * 1024),
            ("1MB", 1024 * 1024)
        ]
        
        for (sizeName, bytes) in testSizes {
            // Create test data
            let testData = Data(repeating: 0x42, count: bytes) // Fill with 'B' bytes
            
            // Measure checksum calculation
            let startTime = CFAbsoluteTimeGetCurrent()
            let checksum = DemoChecksumValidator.calculateChecksum(for: testData)
            let duration = CFAbsoluteTimeGetCurrent() - startTime
            
            let durationMs = duration * 1000
            print("   \(sizeName): \(String(format: "%.2f", durationMs))ms (\(String(checksum.prefix(8)))...)")
        }
        print()
    }
    
    /// Creates a test backup file with checksum for manual inspection
    static func createTestBackupWithChecksum() -> URL? {
        let sampleBackup = """
        {
            "metadata": {
                "appVersion": "Ledger 8",
                "backupVersion": "2.0",
                "backupType": "Complete",
                "createdDate": "\(ISO8601DateFormatter().string(from: Date()))",
                "deviceName": "Demo Device - Checksum Test"
            },
            "clients": [
                {
                    "firstName": "Alice",
                    "lastName": "Johnson",
                    "email": "alice.johnson@example.com",
                    "company": "Checksum Demo Corp",
                    "phone": "555-0123",
                    "address": "123 Validation St",
                    "city": "Demo City",
                    "state": "CA",
                    "zip": "90210"
                }
            ],
            "projects": [
                {
                    "projectName": "Checksum Validation Project",
                    "artist": "Demo Artist",
                    "startDate": "\(ISO8601DateFormatter().string(from: Date()))",
                    "endDate": "\(ISO8601DateFormatter().string(from: Date().addingTimeInterval(86400 * 7)))",
                    "status": "Active",
                    "mediaType": "Digital",
                    "notes": "This project was created to test checksum validation functionality."
                }
            ],
            "items": [],
            "invoices": []
        }
        """.data(using: .utf8)!
        
        // Calculate checksum
        let checksum = DemoChecksumValidator.calculateChecksum(for: sampleBackup)
        
        // Update JSON with checksum (simulate what the backup manager would do)
        var updatedBackup = String(data: sampleBackup, encoding: .utf8)!
        updatedBackup = updatedBackup.replacingOccurrences(of: "\"contentChecksum\": null", with: "\"contentChecksum\": \"\(checksum)\"")
        updatedBackup = updatedBackup.replacingOccurrences(of: "\"checksumAlgorithm\": null", with: "\"checksumAlgorithm\": \"SHA-256\"")
        
        guard let finalJSON = updatedBackup.data(using: .utf8) else {
            print("❌ Failed to create final JSON")
            return nil
        }
        
        // Create file with magic header
        let magicHeader = Data([0x4C, 0x38, 0x42, 0x41, 0x43, 0x4B, 0x55, 0x50, 0x00])
        var fileData = Data()
        fileData.append(magicHeader)
        fileData.append(finalJSON)
        
        // Save to Documents/Backups folder
        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("❌ Could not access Documents directory")
            return nil
        }
        
        let backupsURL = documentsURL.appendingPathComponent("Backups")
        
        do {
            try FileManager.default.createDirectory(at: backupsURL, withIntermediateDirectories: true)
            
            let fileURL = backupsURL.appendingPathComponent("Demo_ChecksumValidation_Test.l8backup")
            try fileData.write(to: fileURL)
            
            print("✅ Test backup with checksum created: \(fileURL.path)")
            print("   File size: \(fileData.count) bytes")
            print("   Header size: 9 bytes")
            print("   JSON size: \(finalJSON.count) bytes")
            print("   Content checksum: \(String(checksum.prefix(16)))...")
            
            return fileURL
        } catch {
            print("❌ Failed to create test file: \(error)")
            return nil
        }
    }
    
    /// Validates an existing backup file
    static func validateExistingBackup(at url: URL) {
        print("=== Validating Existing Backup ===")
        print("File: \(url.lastPathComponent)\n")
        
        do {
            let fileData = try Data(contentsOf: url)
            print("File size: \(fileData.count) bytes")
            
            // Check for magic header
            let magicHeader = Data([0x4C, 0x38, 0x42, 0x41, 0x43, 0x4B, 0x55, 0x50, 0x00])
            let hasHeader = fileData.count >= 9 && fileData.prefix(9) == magicHeader
            
            print("Magic header: \(hasHeader ? "✅ Present" : "❌ Missing (legacy format)")")
            
            // Extract JSON
            let jsonData: Data
            if hasHeader {
                jsonData = Data(fileData.dropFirst(9))
                print("JSON size: \(jsonData.count) bytes")
            } else {
                jsonData = fileData
                print("File is pure JSON (legacy)")
            }
            
            // Parse JSON to get metadata
            if let backupDict = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
               let metadata = backupDict["metadata"] as? [String: Any] {
                
                print("\nBackup metadata:")
                if let appVersion = metadata["appVersion"] as? String {
                    print("   App version: \(appVersion)")
                }
                if let backupVersion = metadata["backupVersion"] as? String {
                    print("   Backup version: \(backupVersion)")
                }
                if let createdDate = metadata["createdDate"] as? String {
                    print("   Created: \(createdDate)")
                }
                if let deviceName = metadata["deviceName"] as? String {
                    print("   Device: \(deviceName)")
                }
                
                // Check checksum
                if let storedChecksum = metadata["contentChecksum"] as? String,
                   let algorithm = metadata["checksumAlgorithm"] as? String {
                    print("\nChecksum validation:")
                    print("   Algorithm: \(algorithm)")
                    print("   Stored: \(String(storedChecksum.prefix(16)))...")
                    
                    let calculatedChecksum = DemoChecksumValidator.calculateChecksum(for: jsonData)
                    print("   Calculated: \(String(calculatedChecksum.prefix(16)))...")
                    
                    if storedChecksum == calculatedChecksum {
                        print("   Status: ✅ VALID - File integrity confirmed")
                    } else {
                        print("   Status: ❌ INVALID - File may be corrupted!")
                    }
                } else {
                    print("\nChecksum validation: ⚠️  No checksum stored (legacy backup)")
                }
            }
            
        } catch {
            print("❌ Error reading backup file: \(error)")
        }
    }
}

// MARK: - Demo Helper Structure

fileprivate struct DemoChecksumValidator {
    static func calculateChecksum(for data: Data) -> String {
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    static func validateChecksum(jsonData: Data, expectedChecksum: String?) -> DemoChecksumResult {
        guard let expectedChecksum = expectedChecksum else {
            return .noChecksumStored
        }
        
        let calculatedChecksum = calculateChecksum(for: jsonData)
        
        if calculatedChecksum == expectedChecksum {
            return .valid(calculatedChecksum)
        } else {
            return .mismatch(expected: expectedChecksum, calculated: calculatedChecksum)
        }
    }
}

fileprivate enum DemoChecksumResult {
    case valid(String)
    case mismatch(expected: String, calculated: String)
    case noChecksumStored
    
    var isValid: Bool {
        switch self {
        case .valid: return true
        case .mismatch, .noChecksumStored: return false
        }
    }
}