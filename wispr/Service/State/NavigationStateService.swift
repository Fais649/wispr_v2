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
    var background: GlobalBackground {
        GlobalBackground()
    }

    var tempBackground: (() -> AnyView)?

    private var _path: [Path] = [.dayScreen]

    var pathState: PathStateService = .init()
    var activePath: Path {
        pathState.active
    }

    var onDayScreen: Bool {
        pathState.onDayScreen
    }

    var onTimeline: Bool {
        pathState.onTimelineScreen
    }

    var onForm: Bool {
        pathState.onForm
    }

    var onBookForm: Bool {
        pathState.onBookForm
    }

    var onItemForm: Bool {
        pathState.onItemForm
    }

    func goBack() {
        pathState.goBack()
    }

    @MainActor
    func goToItemForm(_ item: Item? = nil, date: Date? = nil) {
        pathState
            .setActive(.itemForm(
                item: item ?? ItemStore
                    .create(
                        timestamp: Calendar.current.combineDateAndTime(
                            date: date ?? Date(),
                            time: Date()
                        )
                    )
            ))
    }

    @MainActor
    func goToBookForm(_ book: Book? = nil) {
        pathState
            .setActive(.bookForm(book: book ?? BookStore.create()))
    }

    func goToDayScreen() {
        pathState.setActiveTab(.dayScreen)
    }

    var shelfState: ShelfStateService = .init()
    var bookState: BookStateService = .init()

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

    func toggleSettingShelf() {
        shelfState.toggleSettingShelf()
    }

    @MainActor
    @ViewBuilder
    func destination(_ animation: Namespace.ID, _ path: Path) -> some View {
        switch path {
            case let .itemForm(item: item):
                ItemForm(animation: animation, item: item)
                    .navigationTransition(.zoom(
                        sourceID: "newItem",
                        in: animation
                    ))
                    .navigationTransition(.zoom(
                        sourceID: item.id,
                        in: animation
                    ))
            case let .bookForm(book: book):
                BookForm(book: book)
                    .navigationTransition(.zoom(
                        sourceID: "newBook",
                        in: animation
                    ))
            default:
                EmptyView()
        }
    }
}
