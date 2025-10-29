//
//  BackupFileService.swift
//  Ledger 8
//
//  Created by Gabe Witcher on 10/28/25.
//

import Foundation

@MainActor
protocol BackupFileService {
    func getManualBackupFiles() async throws -> [BackupFileInfo]
    func deleteBackup(at url: URL) async throws
    func getBackupDetails(at url: URL) async throws -> BackupDetailsInfo
}

@MainActor
class ComprehensiveBackupFileService: BackupFileService {
    
    func getManualBackupFiles() async throws -> [BackupFileInfo] {
        let documentsURL = URL.documentsDirectory
        let backupsURL = documentsURL.appendingPathComponent("Backups")
        
        // Check if directory exists
        guard FileManager.default.fileExists(atPath: backupsURL.path) else {
            return []
        }
        
        let files = try FileManager.default.contentsOfDirectory(
            at: backupsURL,
            includingPropertiesForKeys: [.creationDateKey, .fileSizeKey, .isDirectoryKey]
        )
        
        // Filter out auto-backup directory and only get backup files
        let backupFiles = files.filter { url in
            // Skip directories (like Auto subfolder)
            if let isDirectory = try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory,
               isDirectory {
                return false
            }
            
            // Only include .l8backup files
            return url.pathExtension == "l8backup"
        }
        
        return backupFiles.compactMap { url in
            guard let attributes = try? url.resourceValues(forKeys: [.creationDateKey, .fileSizeKey]),
                  let creationDate = attributes.creationDate,
                  let fileSize = attributes.fileSize else {
                return nil
            }
            
            return BackupFileInfo(
                url: url,
                fileName: url.lastPathComponent,
                creationDate: creationDate,
                fileSize: Int64(fileSize),
                isAutoBackup: false
            )
        }.sorted { $0.creationDate > $1.creationDate }
    }
    
    func deleteBackup(at url: URL) async throws {
        try FileManager.default.removeItem(at: url)
    }
    
    func getBackupDetails(at url: URL) async throws -> BackupDetailsInfo {
        guard url.startAccessingSecurityScopedResource() else {
            throw ComprehensiveBackupError.fileAccessDenied
        }
        defer { url.stopAccessingSecurityScopedResource() }
        
        let rawData = try Data(contentsOf: url)
        let headerValidation = BackupFileHeader.extractJSONData(from: rawData)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let backup = try decoder.decode(CompleteLedgerBackup.self, from: headerValidation.jsonData)
        
        return BackupDetailsInfo(
            metadata: backup.metadata,
            clientsCount: backup.clients.count,
            projectsCount: backup.projects.count,
            itemsCount: backup.items.count,
            invoicesCount: backup.invoices.count,
            hasIntegrityData: backup.metadata.contentChecksum != nil
        )
    }
}