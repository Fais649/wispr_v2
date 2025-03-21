//
//  Navigator.swift
//  wispr
//
//  Created by Faisal Alalaiwat on 21.03.25.
//
import SwiftData
import SwiftUI

@Observable
final class NavigatorService {
    private var _path: [Path] = [.dayScreen]
    var activeBoard: ActiveBoard = .init()

    var path: [Path] {
        get { _path }
        set {
            _path = newValue
        }
    }

    var activePath: Path {
        if let last = path.last {
            return last
        }

        return .timelineScreen
    }

    var activeItem: Item? {
        if case let .itemForm(item: item) = activePath {
            return item
        }
        return nil
    }

    var onDayList: Bool {
        activePath == .dayScreen
    }

    var onTimeline: Bool {
        activePath == .timelineScreen
    }

    var onForm: Bool {
        switch activePath {
            case .itemForm, .boardForm:
                return true
            default:
                return false
        }
    }

    var onItemForm: Bool {
        if case .itemForm = activePath {
            return true
        }
        return false
    }

    var showDatePicker = false
    private var _activeDate: Date = Calendar.current.startOfDay(for: Date())
    var activeDate: Date {
        get {
            _activeDate
        }
        set {
            resetDatePicker()
            _activeDate = Calendar.current.startOfDay(for: newValue)
        }
    }

    func goBack() {
        resetDatePicker()
        path.removeLast()
    }

    @MainActor
    func goToItemForm(_ item: Item? = nil) {
        resetDatePicker()
        path
            .append(.itemForm(
                item: item ?? ItemStore
                    .create(timestamp: activeDate)
            ))
    }

    func goToDayScreen() {
        resetDatePicker()
        path.append(.dayScreen)
    }

    var datePicker: () -> AnyView = { AnyView(DefaultDatePicker()) }

    var datePickerButton: () -> AnyView = { AnyView(DefaultDatePickerButton()) }
    var datePickerButtonLabel: ()
        -> AnyView = { AnyView(DefaultDatePickerButtonLabel()) }

    func setDatePicker<Content: View>(
        @ViewBuilder content: @escaping () -> Content
    ) {
        datePicker = { AnyView(content()) }
    }

    func setDatePickerButton<Content: View>(
        @ViewBuilder content: @escaping ()
            -> Content
    ) {
        datePickerButton = { AnyView(content()) }
    }

    func setDatePickerButtonLabel<Content: View>(
        @ViewBuilder content: @escaping ()
            -> Content
    ) {
        datePickerButtonLabel = { AnyView(content()) }
    }

    func resetDatePicker() {
        showDatePicker = false
        datePicker = { AnyView(DefaultDatePicker()) }
        datePickerButton = { AnyView(DefaultDatePickerButton()) }
        datePickerButtonLabel = { AnyView(DefaultDatePickerButtonLabel()) }
    }

    @MainActor
    @ViewBuilder
    var destination: some View {
        VStack {
            switch activePath {
                case .dayScreen:
                    DayScreen(
                        activeDate: activeDate,
                        boardFilter: activeBoard.board
                    )
                    .navigationTransition(
                        .slide.combined(with: .fade(.in))
                            .combined(with: .fade(.out))
                    )
                    .navigationBarBackButtonHidden()
                case let .itemForm(item: item):
                    ItemForm(item: item)
                        .navigationTransition(
                            .slide.combined(with: .fade(.in))
                                .combined(with: .fade(.out))
                        )
                        .navigationBarBackButtonHidden()
                case let .boardForm(board: board):
                    BoardForm(board: board)
                        .navigationTransition(.slide.combined(with: .fade(.in)))
                        .navigationBarBackButtonHidden()
                default:
                    EmptyView()
                        .navigationBarBackButtonHidden()
            }
        }
        .screenStyler()
    }
}

@Observable
final class ActiveBoard {
    init(board: Board? = nil, showBoard: Bool = false) {
        self.board = board
        self.showBoard = showBoard
    }

    var board: Board?
    var showBoard = false
}

enum Path: Hashable {
    case dayScreen,
         timelineScreen,
         boardForm(board: Board? = nil),
         itemForm(item: Item)

    var isBoardDetails: Bool {
        if case .boardForm = self {
            return true
        }
        return false
    }

    var isItemDetails: Bool {
        if case .itemForm = self {
            return true
        }
        return false
    }

    var isTimeline: Bool {
        self == .timelineScreen
    }
}

@Observable
final class ActiveTheme {
    private var _theme: UITheme = DefaultTheme()

    var theme: UITheme {
        get {
            _theme
        }
        set {
            _theme = newValue
        }
    }

    var headerBackground: some View {
        Rectangle()
            .fill(theme.headerBackgroundColor.opacity(0.5))
            .background(theme.headerMaterial)
    }

    var headerForeground: Color {
        theme.headerForegroundColor
    }
}
