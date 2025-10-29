//
//  BackupIntegrityService.swift
//  Ledger 8
//
//  Created by Gabe Witcher on 10/28/25.
//

import Foundation
import CryptoKit

@MainActor
protocol BackupIntegrityService {
    var isValidationEnabled: Bool { get }
    func setValidationEnabled(_ enabled: Bool)
    func validateBackupFile(at fileURL: URL) async throws -> BackupIntegrityResult
    func validateBackup(fileData: Data, extractedJSON: Data, backup: CompleteLedgerBackup) async throws -> Bool
    func recalculateChecksum(for fileURL: URL) async throws -> String
}

@MainActor
class ComprehensiveBackupIntegrityService: BackupIntegrityService {
    
    // MARK: - Properties
    private(set) var isValidationEnabled: Bool = true
    
    // MARK: - Public Methods
    
    func setValidationEnabled(_ enabled: Bool) {
        isValidationEnabled = enabled
    }
    
    func validateBackupFile(at fileURL: URL) async throws -> BackupIntegrityResult {
        guard fileURL.startAccessingSecurityScopedResource() else {
            throw ComprehensiveBackupError.fileAccessDenied
        }
        defer { fileURL.stopAccessingSecurityScopedResource() }
        
        let rawData = try Data(contentsOf: fileURL)
        let headerValidation = BackupFileHeader.extractJSONData(from: rawData)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let backup = try decoder.decode(CompleteLedgerBackup.self, from: headerValidation.jsonData)
        
        return BackupChecksumValidator.validateBackupIntegrity(
            fileData: rawData,
            extractedJSON: headerValidation.jsonData,
            backup: backup
        )
    }
    
    func validateBackup(fileData: Data, extractedJSON: Data, backup: CompleteLedgerBackup) async throws -> Bool {
        let integrityResult = BackupChecksumValidator.validateBackupIntegrity(
            fileData: fileData,
            extractedJSON: extractedJSON,
            backup: backup
        )
        
        if !integrityResult.isValid {
            let details = integrityResult.validationResults.joined(separator: "\n")
            throw ComprehensiveBackupError.checksumValidationFailed(details)
        }
        
        return true
    }
    
    func recalculateChecksum(for fileURL: URL) async throws -> String {
        guard fileURL.startAccessingSecurityScopedResource() else {
            throw ComprehensiveBackupError.fileAccessDenied
        }
        defer { fileURL.stopAccessingSecurityScopedResource() }
        
        let rawData = try Data(contentsOf: fileURL)
        let headerValidation = BackupFileHeader.extractJSONData(from: rawData)
        
        return BackupChecksumValidator.calculateChecksum(for: headerValidation.jsonData)
    }
}

// MARK: - Checksum Validation (Extracted from original manager)

struct BackupChecksumValidator {
    
    /// Calculates SHA-256 checksum for backup content data
    static func calculateChecksum(for data: Data) -> String {
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    /// Validates checksum against stored value in metadata
    static func validateChecksum(jsonData: Data, expectedChecksum: String?) -> ChecksumValidationResult {
        guard let expectedChecksum = expectedChecksum else {
            return .noChecksumStored
        }
        
        // Decode the backup to access it structurally (matching how it was created)
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            var backup = try decoder.decode(CompleteLedgerBackup.self, from: jsonData)
            
            // Remove checksum fields from metadata (to recreate the state when checksum was calculated)
            backup.metadata.contentChecksum = nil
            backup.metadata.checksumAlgorithm = nil
            
            // Re-encode using the SAME settings as backup creation
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            
            let dataForValidation = try encoder.encode(backup)
            
            // Calculate checksum
            let calculatedChecksum = calculateChecksum(for: dataForValidation)
            
            if calculatedChecksum == expectedChecksum {
                return .valid(calculatedChecksum)
            } else {
                return .mismatch(expected: expectedChecksum, calculated: calculatedChecksum)
            }
            
        } catch {
            // If decoding/encoding fails, fall back to direct comparison
            let calculatedChecksum = calculateChecksum(for: jsonData)
            return calculatedChecksum == expectedChecksum ? .valid(calculatedChecksum) : .mismatch(expected: expectedChecksum, calculated: calculatedChecksum)
        }
    }
    
    /// Adds checksum to backup metadata after JSON encoding
    static func addChecksumToBackup(_ backup: inout CompleteLedgerBackup, jsonData: Data) {
        let checksum = calculateChecksum(for: jsonData)
        backup.metadata.contentChecksum = checksum
        backup.metadata.checksumAlgorithm = "SHA-256"
    }
    
    /// Comprehensive validation of backup file integrity
    static func validateBackupIntegrity(fileData: Data, extractedJSON: Data, backup: CompleteLedgerBackup) -> BackupIntegrityResult {
        var results: [String] = []
        var warnings: [String] = []
        var hasErrors = false
        
        // 1. File size validation
        let totalFileSize = fileData.count
        let expectedMinSize = BackupFileHeader.headerLength + 100 // Minimum JSON size
        if totalFileSize < expectedMinSize {
            results.append("❌ File too small (\(totalFileSize) bytes)")
            hasErrors = true
        } else {
            results.append("✅ File size OK (\(totalFileSize) bytes)")
        }
        
        // 2. Header validation
        if BackupFileHeader.isValidBackupFile(fileData) {
            results.append("✅ Magic header valid")
        } else {
            warnings.append("⚠️  No magic header (legacy backup)")
        }
        
        // 3. Checksum validation
        let checksumResult = validateChecksum(jsonData: extractedJSON, expectedChecksum: backup.metadata.contentChecksum)
        switch checksumResult {
        case .valid(let checksum):
            results.append("✅ Checksum valid (\(String(checksum.prefix(8)))...)")
        case .mismatch(let expected, let calculated):
            results.append("❌ Checksum mismatch!")
            results.append("   Expected: \(String(expected.prefix(16)))...")
            results.append("   Calculated: \(String(calculated.prefix(16)))...")
            hasErrors = true
        case .noChecksumStored:
            warnings.append("⚠️  No checksum stored (legacy backup)")
        }
        
        // 4. JSON structure validation
        if backup.clients.count + backup.projects.count + backup.items.count + backup.invoices.count > 0 {
            results.append("✅ Backup contains data")
        } else {
            warnings.append("⚠️  Backup appears to be empty")
        }
        
        // 5. Timestamp validation
        let backupAge = Date().timeIntervalSince(backup.metadata.createdDate)
        if backupAge < 0 {
            results.append("❌ Backup timestamp is in the future")
            hasErrors = true
        } else if backupAge > 365 * 24 * 3600 { // 1 year
            warnings.append("⚠️  Backup is over 1 year old")
        } else {
            results.append("✅ Backup timestamp reasonable")
        }
        
        return BackupIntegrityResult(
            isValid: !hasErrors,
            hasWarnings: !warnings.isEmpty,
            validationResults: results,
            warnings: warnings,
            checksumResult: checksumResult
        )
    }
}