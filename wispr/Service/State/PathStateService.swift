//
//  PathStateService.swift
//  wispr
//
//  Created by Faisal Alalaiwat on 27.03.25.
//
import SwiftUI

@Observable
final class PathStateService {
    var path: [Path] = []
    var tab: Path = .dayScreen

    var active: Path {
        if let last = path.last {
            return last
        }

        return tab
    }

    var onScreen: Bool {
        path.isEmpty
    }

    var onDayScreen: Bool {
        onScreen && tab == .dayScreen
    }

    var onTimelineScreen: Bool {
        onScreen && tab == .timelineScreen
    }

    var onForm: Bool {
        switch active {
            case .itemForm, .bookForm:
                return true
            default:
                return false
        }
    }

    var onBookForm: Bool {
        if case .bookForm = active {
            return true
        }
        return false
    }

    var onItemForm: Bool {
        if case .itemForm = active {
            return true
        }
        return false
    }

    func goBack() {
        path.removeLast()
    }

    func setActive(_ path: Path) {
        self.path.append(path)
    }

    func setActiveTab(_ path: Path) {
        if tab != path {
            tab = path
        }
    }
}

enum Path: Hashable {
    case dayScreen,
         timelineScreen,
         bookForm(book: Book),
         itemForm(item: Item),
         dateShelf,
         bookShelf,
         settingShelf

    var isBookForm: Bool {
        if case .bookForm = self {
            return true
        }
        return false
    }

    var isForm: Bool {
        isItemForm || isBookForm
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

    var title: String {
        switch self {
            case .dayScreen:
                ""
            default:
                ""
        }
    }
}
