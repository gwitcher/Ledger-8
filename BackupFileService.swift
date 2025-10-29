//
//  BackupFileService.swift
//  Ledger 8
//
//  Created by MVVM Refactoring on 10/28/25.
//

import Foundation

@MainActor
class BackupFileService: BackupFileServiceProtocol {
    
    // MARK: - Directory URLs
    private var documentsURL: URL {
        URL.documentsDirectory
    }
    
    private var backupsURL: URL {
        documentsURL.appendingPathComponent("Backups")
    }
    
    private var autoBackupsURL: URL {
        backupsURL.appendingPathComponent("Auto")
    }
    
    private var manualBackupsURL: URL {
        backupsURL
    }
    
    // MARK: - Public Methods
    
    func getManualBackupFiles() async throws -> [BackupFileInfo] {
        try ensureBackupDirectoriesExist()
        
        do {
            let files = try FileManager.default.contentsOfDirectory(
                at: manualBackupsURL,
                includingPropertiesForKeys: [.creationDateKey, .fileSizeKey],
                options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants]
            )
            
            // Filter out the Auto subdirectory and only include backup files
            let backupFiles = files.filter { url in
                !url.hasDirectoryPath && 
                (url.pathExtension == "l8backup" || url.pathExtension == "json")
            }
            
            return try backupFiles.compactMap { url in
                try createBackupFileInfo(from: url, isAutoBackup: false)
            }.sorted { $0.creationDate > $1.creationDate }
            
        } catch {
            throw BackupError.serviceNotAvailable("Failed to read backup directory: \(error.localizedDescription)")
        }
    }
    
    func deleteBackup(at url: URL) async throws {
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw BackupError.invalidBackupFile("File does not exist")
        }
        
        do {
            try FileManager.default.removeItem(at: url)
        } catch {
            throw BackupError.serviceNotAvailable("Failed to delete backup: \(error.localizedDescription)")
        }
    }
    
    func getBackupDetails(at url: URL) async throws -> BackupDetailsInfo {
        guard url.startAccessingSecurityScopedResource() else {
            throw BackupError.fileAccessDenied
        }
        defer { url.stopAccessingSecurityScopedResource() }
        
        do {
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
            
        } catch {
            throw BackupError.corruptedBackup("Failed to read backup details: \(error.localizedDescription)")
        }
    }
    
    func organizeBackupFiles() async throws {
        try ensureBackupDirectoriesExist()
        
        // Get all files in the main backups directory
        let files = try FileManager.default.contentsOfDirectory(
            at: backupsURL,
            includingPropertiesForKeys: [.creationDateKey],
            options: [.skipsHiddenFiles]
        )
        
        // Move auto-backup files that might be in the wrong location
        for file in files {
            if file.hasDirectoryPath { continue }
            
            let fileName = file.lastPathComponent
            if fileName.contains("AutoBackup") {
                let destinationURL = autoBackupsURL.appendingPathComponent(fileName)
                
                // Only move if destination doesn't already exist
                if !FileManager.default.fileExists(atPath: destinationURL.path) {
                    try FileManager.default.moveItem(at: file, to: destinationURL)
                }
            }
        }
    }
    
    func getTotalBackupSize() async throws -> Int64 {
        try ensureBackupDirectoriesExist()
        
        var totalSize: Int64 = 0
        
        // Calculate size of manual backups
        let manualFiles = try FileManager.default.contentsOfDirectory(
            at: manualBackupsURL,
            includingPropertiesForKeys: [.fileSizeKey],
            options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants]
        )
        
        for file in manualFiles {
            if !file.hasDirectoryPath {
                let attributes = try file.resourceValues(forKeys: [.fileSizeKey])
                totalSize += Int64(attributes.fileSize ?? 0)
            }
        }
        
        // Calculate size of auto backups
        let autoFiles = try FileManager.default.contentsOfDirectory(
            at: autoBackupsURL,
            includingPropertiesForKeys: [.fileSizeKey],
            options: [.skipsHiddenFiles]
        )
        
        for file in autoFiles {
            let attributes = try file.resourceValues(forKeys: [.fileSizeKey])
            totalSize += Int64(attributes.fileSize ?? 0)
        }
        
        return totalSize
    }
    
    func cleanupOldBackups(maxToKeep: Int) async throws {
        try ensureBackupDirectoriesExist()
        
        // Clean up manual backups
        try cleanupBackupsInDirectory(manualBackupsURL, maxToKeep: maxToKeep)
        
        // Clean up auto backups (handled separately by AutoBackupService)
        // This is just a safety cleanup in case the service missed some
        try cleanupBackupsInDirectory(autoBackupsURL, maxToKeep: maxToKeep * 2) // Keep more auto backups
    }
    
    // MARK: - Private Methods
    
    private func ensureBackupDirectoriesExist() throws {
        try FileManager.default.createDirectory(
            at: backupsURL,
            withIntermediateDirectories: true,
            attributes: nil
        )
        
        try FileManager.default.createDirectory(
            at: autoBackupsURL,
            withIntermediateDirectories: true,
            attributes: nil
        )
    }
    
    private func createBackupFileInfo(from url: URL, isAutoBackup: Bool) throws -> BackupFileInfo? {
        guard !url.hasDirectoryPath else { return nil }
        
        let attributes = try url.resourceValues(forKeys: [.creationDateKey, .fileSizeKey])
        
        guard let creationDate = attributes.creationDate,
              let fileSize = attributes.fileSize else {
            return nil
        }
        
        return BackupFileInfo(
            url: url,
            fileName: url.lastPathComponent,
            creationDate: creationDate,
            fileSize: Int64(fileSize),
            isAutoBackup: isAutoBackup
        )
    }
    
    private func cleanupBackupsInDirectory(_ directoryURL: URL, maxToKeep: Int) throws {
        let files = try FileManager.default.contentsOfDirectory(
            at: directoryURL,
            includingPropertiesForKeys: [.creationDateKey],
            options: [.skipsHiddenFiles]
        )
        
        // Filter backup files and sort by creation date (newest first)
        let backupFiles = files.compactMap { url -> (URL, Date)? in
            guard !url.hasDirectoryPath,
                  (url.pathExtension == "l8backup" || url.pathExtension == "json"),
                  let creationDate = try? url.resourceValues(forKeys: [.creationDateKey]).creationDate else {
                return nil
            }
            return (url, creationDate)
        }.sorted { $0.1 > $1.1 }
        
        // Remove files beyond the limit
        if backupFiles.count > maxToKeep {
            let filesToDelete = Array(backupFiles.dropFirst(maxToKeep))
            for (fileURL, _) in filesToDelete {
                try FileManager.default.removeItem(at: fileURL)
                print("Cleaned up old backup: \(fileURL.lastPathComponent)")
            }
        }
    }
}