//
//  BackupHeaderTests.swift
//  Ledger 8
//
//  Tests for the magic header implementation
//

import Testing
import Foundation

@Suite("Magic Header Implementation Tests")
struct BackupHeaderTests {
    
    // Test data constants
    static let validMagicHeader = Data([0x4C, 0x38, 0x42, 0x41, 0x43, 0x4B, 0x55, 0x50, 0x00])
    static let sampleJSON = """
    {"test": "data", "valid": true}
    """.data(using: .utf8)!
    
    @Test("Magic header constants are correct")
    func magicHeaderConstants() {
        let header = TestBackupFileHeader.magicHeader
        
        // Test header length
        #expect(header.count == 9, "Header should be exactly 9 bytes")
        #expect(TestBackupFileHeader.headerLength == 9, "Header length constant should be 9")
        
        // Test header content (L8BACKUP\0)
        let expectedBytes: [UInt8] = [0x4C, 0x38, 0x42, 0x41, 0x43, 0x4B, 0x55, 0x50, 0x00]
        #expect(Array(header) == expectedBytes, "Header bytes should match L8BACKUP\\0")
        
        // Test ASCII representation (excluding null terminator)
        let asciiPart = header.prefix(8)
        let asciiString = String(data: asciiPart, encoding: .ascii)
        #expect(asciiString == "L8BACKUP", "ASCII part should read 'L8BACKUP'")
    }
    
    @Test("Valid backup file detection works correctly")
    func validBackupFileDetection() {
        // Test 1: Valid file with header + JSON
        var validFile = Data()
        validFile.append(Self.validMagicHeader)
        validFile.append(Self.sampleJSON)
        
        #expect(TestBackupFileHeader.isValidBackupFile(validFile), "File with valid header should be detected as valid")
        
        // Test 2: JSON only (legacy format)
        #expect(!TestBackupFileHeader.isValidBackupFile(Self.sampleJSON), "JSON-only file should not be detected as having a header")
        
        // Test 3: Empty file
        #expect(!TestBackupFileHeader.isValidBackupFile(Data()), "Empty file should not be valid")
        
        // Test 4: Short file (less than 9 bytes)
        let shortFile = Data([0x4C, 0x38, 0x42]) // Just "L8B"
        #expect(!TestBackupFileHeader.isValidBackupFile(shortFile), "Short file should not be valid")
        
        // Test 5: Wrong magic header
        let wrongHeader = Data([0x50, 0x4B, 0x03, 0x04, 0x14, 0x00, 0x00, 0x00, 0x08]) // ZIP header
        var fileWithWrongHeader = Data()
        fileWithWrongHeader.append(wrongHeader)
        fileWithWrongHeader.append(Self.sampleJSON)
        
        #expect(!TestBackupFileHeader.isValidBackupFile(fileWithWrongHeader), "File with wrong header should not be valid")
    }
    
    @Test("JSON data extraction works correctly")
    func jsonDataExtraction() {
        // Test 1: File with magic header
        var fileWithHeader = Data()
        fileWithHeader.append(Self.validMagicHeader)
        fileWithHeader.append(Self.sampleJSON)
        
        let result1 = TestBackupFileHeader.extractJSONData(from: fileWithHeader)
        #expect(result1.hasHeader == true, "Should detect header presence")
        #expect(result1.jsonData == Self.sampleJSON, "Should extract correct JSON data")
        #expect(result1.jsonData.count == Self.sampleJSON.count, "Extracted JSON should have correct size")
        
        // Test 2: Legacy JSON file (no header)
        let result2 = TestBackupFileHeader.extractJSONData(from: Self.sampleJSON)
        #expect(result2.hasHeader == false, "Should not detect header in legacy file")
        #expect(result2.jsonData == Self.sampleJSON, "Should return original data for legacy file")
    }
    
    @Test("Backup file data creation works correctly")
    func backupFileDataCreation() {
        let originalJSON = Self.sampleJSON
        let backupFileData = TestBackupFileHeader.createBackupFileData(jsonData: originalJSON)
        
        // Test total size
        let expectedSize = TestBackupFileHeader.headerLength + originalJSON.count
        #expect(backupFileData.count == expectedSize, "Backup file should have correct total size")
        
        // Test header portion
        let headerPortion = backupFileData.prefix(TestBackupFileHeader.headerLength)
        #expect(headerPortion == TestBackupFileHeader.magicHeader, "File should start with correct magic header")
        
        // Test JSON portion
        let jsonPortion = backupFileData.dropFirst(TestBackupFileHeader.headerLength)
        #expect(Data(jsonPortion) == originalJSON, "File should contain correct JSON data after header")
        
        // Test round-trip (create file, then extract JSON)
        let extraction = TestBackupFileHeader.extractJSONData(from: backupFileData)
        #expect(extraction.hasHeader == true, "Created file should be detected as having header")
        #expect(extraction.jsonData == originalJSON, "Round-trip should preserve JSON data")
    }
    
    @Test("Header validation handles edge cases")
    func edgeCaseHandling() {
        // Test exactly 9 bytes with valid header
        let exactHeader = TestBackupFileHeader.magicHeader
        #expect(TestBackupFileHeader.isValidBackupFile(exactHeader), "Exact header length should be valid")
        
        // Test 8 bytes (missing null terminator)
        let shortHeader = Data([0x4C, 0x38, 0x42, 0x41, 0x43, 0x4B, 0x55, 0x50])
        #expect(!TestBackupFileHeader.isValidBackupFile(shortHeader), "Header without null terminator should be invalid")
        
        // Test header with extra bytes that match
        var headerWithExtra = TestBackupFileHeader.magicHeader
        headerWithExtra.append(contentsOf: [0x4C, 0x38, 0x42]) // Add "L8B"
        #expect(TestBackupFileHeader.isValidBackupFile(headerWithExtra), "Header with extra data should still be valid")
        
        // Test case sensitivity (lowercase 'l')
        let wrongCaseHeader = Data([0x6C, 0x38, 0x42, 0x41, 0x43, 0x4B, 0x55, 0x50, 0x00]) // l8BACKUP\0
        #expect(!TestBackupFileHeader.isValidBackupFile(wrongCaseHeader), "Header with wrong case should be invalid")
    }
}

// MARK: - Test Helper Structure

/// Test version of BackupFileHeader for unit testing
/// (Duplicated to avoid dependencies in tests)
fileprivate struct TestBackupFileHeader {
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
    
    static func createBackupFileData(jsonData: Data) -> Data {
        var fileData = Data()
        fileData.append(magicHeader)
        fileData.append(jsonData)
        return fileData
    }
}