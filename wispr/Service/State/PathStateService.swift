//
//  PathStateService.swift
//  wispr
//
//  Created by Faisal Alalaiwat on 27.03.25.
//
import SwiftUI

@Observable
final class PathStateService {
     var path: [Path] = [.dayScreen]
    
    var active: Path {
        if let last = path.last {
            return last
        }
        
        return .timelineScreen
    }
    
    var onDayScreen: Bool {
        active == .dayScreen
    }
    
    var onTimeline: Bool {
        active == .timelineScreen
    }
    
    var onForm: Bool {
        switch active {
            case .itemForm, .bookForm:
                return true
            default:
                return false
        }
    }
    
    var onItemForm: Bool {
        if case .itemForm = active {
            return true
        }
        return false
    }
    
    func goBack() -> Void {
        path.removeLast()
    }
    
    func setActive(_ path: Path) -> Void {
        self.path.append(path)
    }
}

enum Path: Hashable {
    case dayScreen,
         timelineScreen,
         bookForm(book: Book? = nil),
         itemForm(item: Item)
    
    var isBookForm: Bool {
        if case .bookForm = self {
            return true
        }
        return false
    }
    
    var isItemForm: Bool {
        if case .itemForm = self {
            return true
        }
        return false
    }
    
    var isTimeline: Bool {
        self == .timelineScreen
    }
}
