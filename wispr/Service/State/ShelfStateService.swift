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

    var dateShelfView: some View {
        Shelf(content: _dateShelfContent)
    }
    
    var bookShelfView: some View {
        Shelf(content: _bookShelfContent)
    }

    var dateShelfButtonView: some View {
        ShelfButton(
            type: .date,
            label: self._dateShelfLabel,
            content: self._dateShelfContent
        )
    }
    
    var bookShelfButtonView: some View {
        ShelfButton(
            type: .book,
            label: self._bookShelfLabel,
            content: self._bookShelfContent
        )
    }

    var _dateShelfContent: AnyView = AnyView(BaseDateShelfView())
    var _dateShelfLabel:  AnyView = AnyView(BaseDateShelfLabelView())
    var _bookShelfContent: AnyView = AnyView(BaseBookShelfView())
    var _bookShelfLabel: AnyView = AnyView(BaseBookShelfLabelView())
    
    func setDateShelf<Content: View, Label: View>(_ content: () -> Content, _ label: () -> Label) {
        _dateShelfContent = AnyView(content())
        _dateShelfLabel = AnyView(label())
    }
    
    func setBookShelf<Content: View, Label: View>(_ content: () -> Content, _ label: () -> Label) {
        _bookShelfContent = AnyView(content())
        _bookShelfLabel = AnyView(label())
    }
    
    func toggle(type: SType) {
        shelf = shelf == type ? .none : type
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

