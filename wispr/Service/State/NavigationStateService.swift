//
//  Navigator.swift
//  wispr
//
//  Created by Faisal Alalaiwat on 21.03.25.
//
import SwiftData
import SwiftUI

@Observable
final class NavigationStateService {
    private var _path: [Path] = [.dayScreen]
    var bookState: BookStateService = .init()
    var shelfState: ShelfStateService = .init()
    var pathState: PathStateService = .init()

    var activePath: Path {
        pathState.active
    }

    var onDayScreen: Bool {
        pathState.onDayScreen
    }

    var onTimeline: Bool {
        pathState.onTimeline
    }

    var onForm: Bool {
        pathState.onForm
    }

    var onItemForm: Bool {
        pathState.onItemForm
    }

    func isShelfShown() -> Bool {
        shelfState.isShown()
    }

    func closeShelf() {
        shelfState.dismissShelf()
    }

    func openBookShelf() {
        shelfState.openBookShelf()
    }

    func openDatePickerShelf() {
        shelfState.openDatePickerShelf()
    }

    func toggleDatePickerShelf() {
        shelfState.toggleDateShelfView()
    }

    func toggleBookShelf() {
        shelfState.toggleBookShelf()
    }

    private var _activeDate: Date = Calendar.current.startOfDay(for: Date())

    var todayDate: Date {
        Calendar.current.startOfDay(for: Date())
    }

    func isToday(_ date: Date) -> Bool {
        Calendar.current.isDateInToday(date)
    }

    func isPast(_ date: Date) -> Bool {
        Calendar.current.startOfDay(for: date) < todayDate
    }

    func isFuture(_ date: Date) -> Bool {
        Calendar.current.startOfDay(for: date) > todayDate
    }

    var isTodayActive: Bool {
        _activeDate == todayDate
    }

    func goToToday() {
        activeDate = todayDate
    }

    var activeDate: Date {
        get {
            _activeDate
        }
        set {
            _activeDate = Calendar.current.startOfDay(for: newValue)
        }
    }

    func goBack() {
        pathState.goBack()
    }

    @MainActor
    func goToItemForm(_ item: Item? = nil) {
        pathState
            .setActive(.itemForm(
                item: item ?? ItemStore
                    .create(
                        timestamp: Calendar.current.combineDateAndTime(
                            date: activeDate,
                            time: Date()
                        )
                    )
            ))
    }

    func goToDayScreen() {
        pathState.setActive(.dayScreen)
    }

    @MainActor
    @ViewBuilder
    func destination(_ path: Path) -> some View {
        switch path {
            case .dayScreen:
                DayScreen(
                    activeDate: activeDate,
                    bookFilter: bookState.book
                )
            case let .itemForm(item: item):
                ItemForm(item: item)
            case let .bookForm(book: book):
                BookForm(book: book)
            default:
                EmptyView()
        }
    }
}
