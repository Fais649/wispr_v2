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
        case date, book, none
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

    func dismissShelf() {
        shelf = .none
    }

    @ViewBuilder
    var dateShelfView: some View {
        AnyView(
            _dateShelfView
        )
    }

    @ViewBuilder
    var bookShelfView: some View {
        AnyView(
            _bookShelfView
        )
    }

    var _dateShelfView: any DateShelfView = BaseDateShelfView()
    var _bookShelfView: any BookShelfView = BaseBookShelfView()


    func setDateShelfView<V: DateShelfView>(_ view:  V) {
        _dateShelfView = view
    }
    
    func setBookShelfView<V: BookShelfView>(_ view:  V) {
        _bookShelfView = view
    }
   
    @ViewBuilder
    func display() -> some View {
        switch shelf {
            case .date:
                dateShelfView
                    .id("dateShelfView")
            case .book:
                bookShelfView
                    .id("bookShelfView")
            default:
                EmptyView()
        }
    }
}

