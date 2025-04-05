//
//  ActiveShelf.swift
//  wispr
//
//  Created by Faisal Alalaiwat on 27.03.25.
//
import SwiftUI

@Observable
final class ShelfStateService {
    enum SType {
        case date, book, setting, none
    }

    var shelf: SType = .none

    func isShown() -> Bool {
        shelf != .none
    }

    func isDatePicker() -> Bool {
        shelf == .date
    }

    func isBook() -> Bool {
        shelf == .book
    }

    func isSetting() -> Bool {
        shelf == .setting
    }

    func openBookShelf() {
        if !isBook() {
            shelf = .book
        }
    }

    func openDatePickerShelf() {
        if !isDatePicker() {
            shelf = .date
        }
    }

    func toggleDateShelfView() {
        shelf = isDatePicker() ? .none : .date
    }

    func toggleBookShelf() {
        shelf = isBook() ? .none : .book
    }

    func toggleSettingShelf() {
        shelf = isSetting() ? .none : .setting
    }

    func dismissShelf() {
        shelf = .none
    }

    func toggle(type: SType) {
        shelf = shelf == type ? .none : type
    }

    @ViewBuilder
    func display<DateShelf: View, BookShelf: View>(
        _ dateShelfView: DateShelf,
        _ bookShelfView: BookShelf
    ) -> some View {
        VStack {
            switch shelf {
                case .date:
                    dateShelfView
                        .id("dateShelfView")
                case .book:
                    bookShelfView
                        .id("bookShelfView")
                case .setting:
                    BaseSettingShelfView()
                default:
                    EmptyView()
            }
        }
        .frame(height: 450)
        .onDisappear {
            self.dismissShelf()
        }
    }
}
