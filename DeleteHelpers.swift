//
//  DeleteHelpers.swift
//  Ledger 8
//
//  Created by Gabe Witcher on [Date]
//

import SwiftUI
import SwiftData

// MARK: - Delete Helper Functions
extension View {
    /// Performs a delete operation with undo support
    @MainActor
    func deleteWithUndo<T: PersistentModel>(
        _ item: T,
        from context: ModelContext,
        undoManager: AppUndoManager
    ) {
        // Register the delete for undo before actually deleting
        undoManager.registerDelete(item, context: context)
        
        // Perform the actual delete
        context.delete(item)
        
        // Save the context
        try? context.save()
    }
    
    /// Performs multiple delete operations with undo support
    @MainActor
    func deleteMultipleWithUndo<T: PersistentModel>(
        _ items: [T],
        from context: ModelContext,
        undoManager: AppUndoManager
    ) {
        // Register all deletes for undo
        for item in items {
            undoManager.registerDelete(item, context: context)
        }
        
        // Perform the actual deletes
        for item in items {
            context.delete(item)
        }
        
        // Save the context
        try? context.save()
    }
}

// MARK: - SwiftData Extensions for Your Models
extension Project {
    @MainActor
    static func delete(_ project: Project, context: ModelContext, undoManager: AppUndoManager) {
        undoManager.registerDelete(project, context: context)
        context.delete(project)
        try? context.save()
    }
}

extension Client {
    @MainActor
    static func delete(_ client: Client, context: ModelContext, undoManager: AppUndoManager) {
        undoManager.registerDelete(client, context: context)
        context.delete(client)
        try? context.save()
    }
}

extension Item {
    @MainActor
    static func delete(_ item: Item, context: ModelContext, undoManager: AppUndoManager) {
        undoManager.registerDelete(item, context: context)
        context.delete(item)
        try? context.save()
    }
}

extension Invoice {
    @MainActor
    static func delete(_ invoice: Invoice, context: ModelContext, undoManager: AppUndoManager) {
        undoManager.registerDelete(invoice, context: context)
        context.delete(invoice)
        try? context.save()
    }
}