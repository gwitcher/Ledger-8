//
//  MVVM_Backup_Migration_Guide.md
//  Ledger 8
//
//  Created by Gabe Witcher on 10/28/25.
//

# MVVM Backup Architecture Migration Guide

## Overview
This guide shows how to migrate from the monolithic `ComprehensiveBackupManager` to a clean MVVM architecture with proper separation of concerns.

## New Architecture

### Services Layer (Business Logic)
- `BackupService` - Core backup/restore operations
- `AutoBackupService` - Auto-backup scheduling and management  
- `BackupIntegrityService` - Checksum validation and file integrity
- `BackupFileService` - File system operations for backup files

### ViewModels Layer (UI State & Logic)
- `BackupOperationsViewModel` - UI state for backup/restore operations
- `AutoBackupSettingsViewModel` - UI state for auto-backup settings
- `BackupListViewModel` - UI state for backup file management

### Coordinator Layer
- `BackupCoordinator` - Dependency injection and service coordination
- `LegacyBackupManagerBridge` - Compatibility bridge during migration

## Migration Steps

### Step 1: Replace ComprehensiveBackupManager Usage

```swift
// OLD: Direct manager usage
@StateObject private var backupManager = ComprehensiveBackupManager(modelContext: modelContext)

// NEW: Use coordinator with ViewModels
@State private var backupCoordinator = BackupCoordinator(modelContext: modelContext)
@State private var backupOperationsVM: BackupOperationsViewModel?
@State private var autoBackupSettingsVM: AutoBackupSettingsViewModel?

// In view's onAppear:
backupOperationsVM = backupCoordinator.createBackupOperationsViewModel()
autoBackupSettingsVM = backupCoordinator.createAutoBackupSettingsViewModel()
```

### Step 2: Update View Bindings

```swift
// OLD: Direct @Published bindings
Button("Create Backup") {
    Task {
        try await backupManager.createCompleteBackup()
    }
}
.disabled(backupManager.isBackingUp)

if backupManager.isBackingUp {
    ProgressView(value: backupManager.progress)
    Text(backupManager.statusMessage)
}

// NEW: ViewModel bindings
Button("Create Backup") {
    Task {
        await backupOperationsVM.createBackup()
    }
}
.disabled(!backupOperationsVM.canPerformOperations)

if backupOperationsVM.shouldShowProgress {
    ProgressView(value: backupOperationsVM.progress)
    Text(backupOperationsVM.statusMessage)
        .foregroundStyle(backupOperationsVM.statusColor)
}
```

### Step 3: Update Auto-Backup Settings

```swift
// OLD: Direct manager properties
Toggle("Auto Backup", isOn: $backupManager.autoBackupEnabled)
Picker("Frequency", selection: $backupManager.autoBackupFrequency) {
    // ...
}

// NEW: ViewModel properties
Toggle("Auto Backup", isOn: $autoBackupSettingsVM.autoBackupEnabled)
Picker("Frequency", selection: $autoBackupSettingsVM.autoBackupFrequency) {
    // ...
}
.opacity(autoBackupSettingsVM.shouldShowFrequencyPicker ? 1.0 : 0.3)
```

### Step 4: Error Handling

```swift
// OLD: Single error property
if let error = backupManager.errorMessage {
    Text(error)
        .foregroundStyle(.red)
}

// NEW: Contextual error handling
if backupOperationsVM.hasError {
    ErrorView(
        message: backupOperationsVM.errorMessage!,
        onDismiss: backupOperationsVM.clearError
    )
}
```

### Step 5: File Management

```swift
// OLD: Direct file access
let backups = backupManager.getAutoBackupFiles()

// NEW: Through BackupListViewModel
@State private var backupListVM = backupCoordinator.createBackupListViewModel()

List(backupListVM.filteredAutoBackups, id: \.fileName) { backup in
    BackupRow(backup: backup) {
        Task {
            await backupListVM.deleteAutoBackup(backup)
        }
    }
}
.searchable(text: $backupListVM.searchText)
.refreshable {
    await backupListVM.refreshBackups()
}
```

## Benefits of New Architecture

### ✅ Proper Separation of Concerns
- Services handle business logic only
- ViewModels handle UI state and user interactions
- Views are thin and focused on presentation

### ✅ Better Testability
```swift
// Easy to test ViewModels with mock services
let mockBackupService = MockBackupService()
let viewModel = BackupOperationsViewModel(
    backupService: mockBackupService,
    integrityService: mockIntegrityService
)

// Test business logic without UI dependencies
func testBackupCreation() async {
    await viewModel.createBackup()
    XCTAssertTrue(viewModel.showingBackupComplete)
    XCTAssertNil(viewModel.errorMessage)
}
```

### ✅ Modern Swift Patterns
- Uses `@Observable` instead of `ObservableObject`
- Proper `@MainActor` usage
- Protocol-based dependency injection
- Clean async/await patterns

### ✅ Scalable Architecture
- Easy to add new features (just create new ViewModels)
- Services can be reused across multiple ViewModels
- Clear dependency graph

## Gradual Migration Strategy

1. **Phase 1**: Create new services alongside existing manager
2. **Phase 2**: Create ViewModels that use new services
3. **Phase 3**: Update views to use ViewModels (use bridge if needed)
4. **Phase 4**: Remove old ComprehensiveBackupManager
5. **Phase 5**: Remove LegacyBackupManagerBridge

This allows you to migrate incrementally without breaking existing functionality.