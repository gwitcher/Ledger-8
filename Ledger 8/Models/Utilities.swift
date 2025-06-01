//
//  Utilities.swift
//  Ledger 8
//
//  Created by Gabe Witcher on 6/1/25.
//

import SwiftUI

struct UndoRedoAction: Identifiable {
    enum UndoOrRedo {
        case undo, redo

        var localizable: LocalizedStringKey {
            switch self {
                case .undo:
                    return "Undo"
                case .redo:
                    return "Redo"
            }
        }
    }
    let id: UUID
    let title: String
    let undoOrRedo: UndoOrRedo

    private init(_ undoOrRedo: UndoOrRedo, title: String) {
        self.id = UUID()
        self.title = title
        self.undoOrRedo = undoOrRedo
    }

    static func undo(title: String) -> Self {
        .init(.undo, title: title)
    }

    static func redo(title: String) -> Self {
        .init(.redo, title: title)
    }
}
