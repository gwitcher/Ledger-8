//
//  UndoManager.swift
//  Ledger 8
//
//  Created by Gabe Witcher on [Date]
//

import SwiftUI
import SwiftData
import Combine
import Foundation
import SwiftUIFontIcon
import Contacts

// MARK: - Undo Action Protocol
protocol UndoAction {
    func undo(in context: ModelContext)
    var description: String { get }
}

// MARK: - Concrete Undo Actions
struct DeleteModelUndoAction<T: PersistentModel>: UndoAction {
    let item: T
    let itemName: String
    
    func undo(in context: ModelContext) {
        context.insert(item)
        try? context.save()
    }
    
    var description: String {
        "Delete \(itemName)"
    }
}

// MARK: - Undo Manager
@MainActor
class AppUndoManager: ObservableObject {
    @Published private(set) var canUndo = false
    @Published var showingUndoAlert = false
    
    private var undoStack: [UndoAction] = []
    private let maxUndoActions = 10
    
    func registerDelete<T: PersistentModel>(_ item: T, context: ModelContext) {
        // Get a descriptive name for the item
        let itemName = getItemName(for: item)
        
        // Create generic undo action
        let undoAction = DeleteModelUndoAction(item: item, itemName: itemName)
        
        // Add to undo stack
        undoStack.append(undoAction)
        
        // Limit stack size
        if undoStack.count > maxUndoActions {
            undoStack.removeFirst()
        }
        
        canUndo = !undoStack.isEmpty
    }
    
    private func getItemName<T: PersistentModel>(for item: T) -> String {
        // Use reflection or type name to get a meaningful description
        let typeName = String(describing: type(of: item))
        return typeName
    }
    
    func performUndo(in context: ModelContext) {
        guard let lastAction = undoStack.popLast() else { return }
        
        lastAction.undo(in: context)
        canUndo = !undoStack.isEmpty
        
        // Show confirmation
        showingUndoAlert = true
    }
    
    func clearUndoStack() {
        undoStack.removeAll()
        canUndo = false
    }
    
    var lastActionDescription: String? {
        undoStack.last?.description
    }
}