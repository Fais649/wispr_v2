//
//  ContentView.swift
//  wispr
//
//  Created by Faisal Alalaiwat on 10.01.25.
//

import AudioKit
import AVFoundation
import AVKit
import NavigationTransitions
import SwiftData
import SwiftUI
import SwiftUIIntrospect
import WidgetKit

@Observable
final class StateManager {
    var nav: Navigator = .init()
    var activeBoard: ActiveBoard = .init()
    var activeTheme: ActiveTheme = .init()
}

@Observable
final class ActiveFocus {
    var focus: FocusedField?
}

@Observable
final class Navigator {
    private var _path: [Path] = [.dayScreen]

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

        return .timeline
    }

    var onDayList: Bool {
        activePath == .dayScreen
    }

    var onTimeline: Bool {
        activePath == .timeline
    }

    var onForm: Bool {
        switch activePath {
        case .itemForm, .boardDetails:
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

    var showDatePicker: Bool = false
    private var _selectedDate: Date = Calendar.current.startOfDay(for: Date())
    var selectedDate: Date {
        get {
            _selectedDate
        }
        set {
            showDatePicker = false
            _selectedDate = Calendar.current.startOfDay(for: newValue)
        }
    }

    func goBack() {
        path.removeLast()
    }

    func goToItemForm(_ item: Item? = nil) {
        path.append(.itemForm(item: item))
    }

    func goToDayScreen() {
        path.append(.dayScreen)
    }

    @ViewBuilder
    func destination(_ path: Path) -> some View {
        Destination(path: path)
    }

    struct Destination: View {
        @Environment(Navigator.self) private var nav: Navigator
        @Environment(ActiveBoard.self) private var activeBoard: ActiveBoard

        var path: Path

        var body: some View {
            switch path {
            case .dayScreen:
                DayScreen(selectedDate: Bindable(nav).selectedDate, boardFilter: activeBoard.board)
                    .navigationTransition(.slide.combined(with: .fade(.cross)))
                    .navigationBarBackButtonHidden()
            case let .itemForm(item: item):
                ItemForm(item: item)
                    .navigationBarBackButtonHidden()
            case let .boardDetails(board: board):
                BoardForm(board: board)
                    .navigationBarBackButtonHidden()
            default:
                TimeLineScreen()
            }
        }
    }
}

@Observable
final class ActiveBoard {
    var board: Board?
    var showBoard: Bool = false
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
        Rectangle().fill(theme.headerBackgroundColor.opacity(0.5)).background(theme.headerMaterial)
    }

    var headerForeground: Color {
        theme.headerForegroundColor
    }
}

enum Path: Hashable {
    case dayScreen, timeline, boardDetails(board: Board? = nil), itemForm(item: Item? = nil)

    var isBoardDetails: Bool {
        if case .boardDetails = self {
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
        self == .timeline
    }
}

private extension UIView {
    var allSubViews: [UIView] {
        return subviews.flatMap { [$0] + $0.allSubViews }
    }
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(ActiveTheme.self) private var activeTheme: ActiveTheme

    @State var nav: Navigator = .init()
    @State var activeBoard: ActiveBoard = .init()

    @Namespace var namespace

    var activePath: Path {
        nav.activePath
    }

    var body: some View {
        NavigationStack(path: $nav.path) {
            TimeLineScreen()
                .navigationDestination(for: Path.self) { path in
                    nav.destination(path)
                }
                .toolbarBackground(.hidden)
                .navigationTransition(.slide.combined(with: .fade(.cross)))
        }
        .sheet(isPresented: $activeBoard.showBoard) {
            BoardSheet()
        }
        .overlay(alignment: .bottom) {
            VStack {
                if nav.showDatePicker {
                    DatePicker("", selection: $nav.selectedDate,
                               displayedComponents:
                               [.date]).datePickerStyle(.graphical).tint(Material.ultraThinMaterial)
                        .background(RoundedRectangle(cornerRadius: 20).fill(activeTheme.theme.headerMaterial))
                        .frame(width: 320, height: 320)
                        .padding()
                        .transition(.opacity)
                        .animation(.smooth, value: nav.selectedDate)
                        .animation(.smooth, value: nav.showDatePicker)
                }

                HStack {
                    if !nav.onTimeline {
                        ToolbarButton {
                            nav.goBack()
                        } label: {
                            Image(systemName: nav.onDayList ? "text.line.magnify" : "chevron.left")
                        }
                    }

                    ToolbarButton(clipShape: Capsule()) {
                        activeBoard.showBoard = true
                    } label: {
                        LogoBoardButton()
                    }

                    ToolbarButton(clipShape: Capsule()) {
                        nav.showDatePicker.toggle()
                    } label: {
                        Text(nav.selectedDate.formatted(.dateTime.day().month().year(.twoDigits)))
                    }.offset(y: nav.showDatePicker ? -10 : 0)
                        .onChange(of: nav.selectedDate) {
                            withAnimation {
                                nav.showDatePicker = false
                            }
                        }

                    if !nav.onForm {
                        ToolbarButton {
                            nav.goToItemForm()
                        } label: {
                            Image(systemName: "plus")
                        }
                    }

                    if nav.onTimeline {
                        ToolbarButton {
                            nav.goToDayScreen()
                        } label: {
                            Image(systemName: "chevron.right")
                        }
                    }
                }
            }
            .padding()
            .background {
                Color.clear
            }
        }
        .background(GlobalBackground())
        .scrollIndicators(.hidden)
        .scrollContentBackground(.hidden)
        .environment(nav)
        .environment(activeBoard)
    }

    struct GlobalBackground: View {
        @Environment(ActiveBoard.self) private var activeBoard: ActiveBoard

        var body: some View {
            VStack {
                if let board = activeBoard.board {
                    board.globalBackground
                        .scaleEffect(x: -1)
                } else {
                    MeshGradient(width: 3, height: 3, points: [
                        [0, 0], [0, 0.5], [0, 1],
                        [0.5, 0], [0.5, 0.5], [0.5, 1],
                        [1, 0], [1, 0.5], [1, 1],
                    ], colors: [.gray.opacity(0.8), .clear, .clear, .clear, .clear, .clear, .clear,
                                .clear, .gray.opacity(0.8)]).blur(radius: 80)
                }
            }.overlay(.ultraThinMaterial)
                .ignoresSafeArea()
                .allowsHitTesting(false)
        }
    }
}

struct TimeLineScreen: View {
    @Environment(\.modelContext) private var modelContext: ModelContext
    @Environment(ActiveTheme.self) private var activeTheme: ActiveTheme
    @Environment(ActiveBoard.self) private var activeBoard: ActiveBoard
    @Environment(Navigator.self) private var nav: Navigator
    @Query(filter: #Predicate<Item> { $0.parent == nil && !$0.archived }, sort: \.timestamp) var items: [Item]
    @State var days: [Date: [Item]] = [:]
    var todayDate: Date {
        Calendar.current.startOfDay(for: Date())
    }

    @State private var loaded: Bool = false

    var body: some View {
        ScrollViewReader { proxy in
            VStack {
                if loaded {
                    ScrollView {
                        LazyVStack(pinnedViews: [.sectionHeaders]) {
                            ForEach(days.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                                Section(header: sectionHeader(key)) {
                                    Item.DGroups(items: value)
                                        .scrollTransition(.interactive.threshold(.visible.inset(by: 75))) { content, phase in
                                            content.opacity(phase.isIdentity ? 1 : 0)
                                                .blur(radius: phase.isIdentity ? 0 : 40)
                                                .scaleEffect(x: 1, y: phase.isIdentity ? 1 : 0, anchor: .bottom)
                                        }
                                }
                            }
                            Spacer().frame(height: 80)
                        }
                        .id(activeBoard.board?.id.description ?? "all")
                    }
                    .onAppear {
                        Task {
                            if days[nav.selectedDate] == nil {
                                let sortedKeys = days.keys.sorted()
                                if let next = sortedKeys.first(where: { $0 >
                                        nav.selectedDate
                                }) {
                                    proxy.scrollTo(next, anchor: .top)
                                }
                            } else {
                                proxy.scrollTo(nav.selectedDate, anchor: .top)
                            }
                        }
                    }
                    .onChange(of: nav.selectedDate) {
                        if days[nav.selectedDate] == nil {
                            let sortedKeys = days.keys.sorted()
                            if let next = sortedKeys.first(where: { $0 >
                                    nav.selectedDate
                            }) {
                                withAnimation {
                                    proxy.scrollTo(next, anchor: .top)
                                }
                            }

                            if !nav.onTimeline { return }
                            withAnimation {
                                nav.goToDayScreen()
                            }
                        } else {
                            withAnimation {
                                proxy.scrollTo(nav.selectedDate, anchor: .top)
                            }
                        }
                    }
                    .safeAreaPadding(.top, 30)
                    .safeAreaPadding(.bottom, 100)
                    .safeAreaPadding(.horizontal, 60)
                    .coordinateSpace(name: "scroll")
                    .defaultScrollAnchor(.top)
                    .clipShape(.rect(cornerRadius: 10))
                } else {
                    ProgressView().progressViewStyle(.circular)
                        .task {
                            days = await loadFilteredDays()
                        }
                }
            }
        }
        .hideSystemBackground()
        .onChange(of: items) {
            Task {
                days = await loadFilteredDays()
            }
        }.onChange(of: activeBoard.board) {
            Task {
                days = await loadFilteredDays()
            }
        }.task {
            for i in items.filter({ $0.text.isEmpty }) {
                modelContext.delete(i)
            }
            days = await loadFilteredDays()
        }
    }

    func loadFilteredDays() async -> [Date: [Item]] {
        withAnimation {
            loaded = false
        }

        let d = await filterDays()

        withAnimation {
            loaded = true
        }
        return d
    }

    func filterDays() async -> [Date: [Item]] {
        let days = Dictionary(grouping: items, by: { Calendar.current.startOfDay(for: $0.timestamp) })
        return days.filter { _, items in
            guard let board = activeBoard.board else { return true }
            return items.contains { item in
                item.tags.contains(where: board.tags.contains)
            }
        }
    }

    func isToday(_ date: Date) -> Bool {
        return date == todayDate
    }

    func isFuture(_ date: Date) -> Bool {
        return date >= todayDate
    }

    @ViewBuilder
    func sectionHeader(_ key: Date) -> some View {
        AniButton {
            nav.selectedDate = key
            nav.path.append(.dayScreen)
        } label: {
            HStack {
                if key == nav.selectedDate {
                    Image(systemName: "asterisk")
                        .font(.system(size: 16))
                        .foregroundStyle(.white)
                        .shadow(color: .white, radius: 2)
                }

                Text(key.formatted(date: .abbreviated, time: .omitted))
                    .font(.system(size: 16))
                    .foregroundStyle(.white)
                    .shadow(color: .white, radius: 2)

                Spacer()

                Text(key.formatted(.dateTime.weekday()))
                    .font(.system(size: 16))
                    .foregroundStyle(.white)
                    .shadow(color: .white, radius: 2)
            }
            .padding(.vertical, 30)
        }
        .scrollTransition(.interactive.threshold(.visible)) { content, phase in
            content.opacity(phase.isIdentity ? 1 : 0)
                .blur(radius: phase.isIdentity ? 0 : 40)
                .scaleEffect(x: 1, y: phase.isIdentity ? 1 : 0, anchor:
                    phase.value > 0 ? .top : .bottom)
        }
    }

    @ViewBuilder
    func archiveButton(_ item: Item) -> some View {
        AniButton {
            archive(item)
        } label: {
            Image(systemName: "archivebox.fill")
        }
    }

    func archive(_ item: Item) {
        checkEventData(item)

        item.archived = true
        item.archivedAt = Date()
    }

    @ViewBuilder
    func deleteButton(_ item: Item) -> some View {
        AniButton {
            delete(item)
        } label: {
            Image(systemName: "trash.fill")
        }
    }

    func delete(_ item: Item) {
        checkEventData(item)
        modelContext.delete(item)
    }

    func checkEventData(_ item: Item) {
        if let event = item.eventData {
            Task {
                let eh = EventHandler(item, event)
                _ = eh.processEventData()
            }
        }
    }
}

struct DayScreen: View {
    @Environment(\.modelContext) private var modelContext: ModelContext
    @Environment(Navigator.self) private var nav: Navigator
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedDate: Date
    @Query var items: [Item]

    var boardFilter: Board?

    @State var filteredItems: [Item] = []

    init(selectedDate: Binding<Date>, boardFilter: Board?) {
        _selectedDate = selectedDate
        self.boardFilter = boardFilter

        let start = Calendar.current.startOfDay(for: selectedDate.wrappedValue)
        let end = Calendar.current.startOfDay(for: start.advanced(by: 86400))
        _items = Query(filter: #Predicate<Item> { $0.parent == nil && !$0.archived && start <= $0.timestamp && $0.timestamp < end }, sort: \.position)
    }

    @State private var loaded: Bool = false

    @ViewBuilder
    func sectionHeader() -> some View {
        HStack {
            Image(systemName: "asterisk")
                .font(.system(size: 16))
                .foregroundStyle(.white)
                .shadow(color: .white, radius: 2)

            Text(nav.selectedDate.formatted(date: .abbreviated, time: .omitted))
                .font(.system(size: 16))
                .foregroundStyle(.white)
                .shadow(color: .white, radius: 2)

            Spacer()

            Text(nav.selectedDate.formatted(.dateTime.weekday()))
                .font(.system(size: 16))
                .foregroundStyle(.white)
                .shadow(color: .white, radius: 2)
        }
        .padding(.vertical, 30)
    }

    var body: some View {
        VStack {
            if loaded {
                if filteredItems.isEmpty {
                    Image(systemName: "plus.circle.dashed")
                        .fontWeight(.ultraLight)
                } else {
                    sectionHeader()
                    List {
                        Item.DGroups(items: items, animated: true, withSwipe: true)
                            .listRowSpacing(10)
                    }
                    .listStyle(.plain)
                    .padding(0)
                    .safeAreaPadding(.top, 100)
                }
            } else {
                ProgressView().progressViewStyle(.circular)
                    .task { await loadedFilteredItems() }
            }
        }
        .onChange(of: nav.selectedDate) {
            Task {
                await loadedFilteredItems()
            }
        }
        .onChange(of: items) {
            Task {
                await loadedFilteredItems()
            }
        }
        .hideSystemBackground()
        .safeAreaPadding(.horizontal, 40)
        .padding(.vertical, 10)
        .safeAreaPadding(.top, 30)
        .safeAreaPadding(.bottom, 100)
    }

    func loadedFilteredItems() async {
        withAnimation {
            loaded = false
        }
        await filterItems()
        withAnimation {
            loaded = true
        }
    }

    func filterItems() async {
        if let boardFilter {
            filteredItems = items.filter { $0.tags.contains { boardFilter.tags.contains($0) } }
        } else {
            filteredItems = items
        }
    }
}

struct BoardSheet: View {
    @Environment(Navigator.self) private var nav: Navigator
    @Environment(ActiveBoard.self) private var activeBoard: ActiveBoard
    @Query var boards: [Board]
    @State var editBoards: Bool = false

    var body: some View {
        List {
            AniButton {
                activeBoard.board = nil
                activeBoard.showBoard = false
            } label: {
                Text("none_")
            }

            Section(header:
                HStack {
                    Text("boards_")
                    Spacer()

                    AniButton {
                        editBoards.toggle()
                    } label: {
                        Image(systemName: editBoards ? "checkmark" : "pencil")
                    }
                }
            ) {
                ForEach(boards.sorted(by: {
                    if let firstClick = $0.lastClicked, let secondClick = $1.lastClicked {
                        return firstClick > secondClick
                    } else {
                        return $0.timestamp < $1.timestamp
                    }
                })) { board in
                    AniButton {
                        if editBoards {
                            nav.path.append(.boardDetails(board: board))
                        } else {
                            activeBoard.board = board
                        }
                        activeBoard.showBoard = false
                    } label: {
                        HStack {
                            Text(board.name)
                        }
                    }
                }
            }
        }
    }
}

struct ToolbarLogo: View {
    @Environment(ActiveBoard.self) private var activeBoard: ActiveBoard

    var board: Board? {
        activeBoard.board
    }

    var body: some View {
        ToolbarButton(clipShape: Capsule()) {
            activeBoard.showBoard = true
        } label: {
            LogoBoardButton()
        }
    }
}

struct LogoBoardButton: View {
    @Environment(ActiveBoard.self) private var activeBoard: ActiveBoard
    @Environment(Navigator.self) private var nav: Navigator

    var board: Board? {
        activeBoard.board
    }

    var body: some View {
        HStack(spacing: 12) {
            Image("Logo")
                .resizable()
                .scaledToFit()
                .frame(width: 14, height: 14)

            if let board {
                Text(board.name)
            }
        }
    }
}

protocol UITheme {
    var toolbarBlur: UIBlurEffect { get }
    var toolbarForegroundColor: Color { get }
    var toolbarBackgroundColor: Color { get }

    var headerMaterial: Material { get }
    var headerBackgroundColor: Color { get }
    var headerForegroundColor: Color { get }

    var contentMaterial: Material { get }
    var contentBackgroundColor: Color { get }
    var contentForegroundColor: Color { get }

    var symbolMaterial: Material { get }
    var symbolBackgroundColor: Color { get }
    var symbolForegroundColor: Color { get }
}

struct DefaultTheme: UITheme {
    var toolbarBlur: UIBlurEffect { .init(style: .systemUltraThinMaterial) }
    var toolbarForegroundColor: Color { .white }
    var toolbarBackgroundColor: Color { .black }

    var headerMaterial: Material { .ultraThinMaterial }
    var headerBackgroundColor: Color { .gray }
    var headerForegroundColor: Color { .white }

    var contentMaterial: Material { .thickMaterial }
    var contentBackgroundColor: Color { .black }
    var contentForegroundColor: Color { .white }

    var symbolMaterial: Material { .ultraThinMaterial }
    var symbolBackgroundColor: Color { .white }
    var symbolForegroundColor: Color { .black }
}

struct SectionContent: ViewModifier {
    var fontWeight: Font.Weight?
    var prominence: Prominence

    var background: some ShapeStyle {
        switch prominence {
        case .secondary:
            AnyShapeStyle(Color.clear)
        default:
            AnyShapeStyle(Material.regularMaterial.opacity(0.2))
        }
    }

    var weight: Font.Weight? {
        if fontWeight == nil, prominence == .regular {
            return nil
        }

        if fontWeight != nil {
            return fontWeight
        }

        switch prominence {
        case .regular:
            return .light
        case .primary:
            return .regular
        case .secondary:
            return .light
        }
    }

    var overlay: some View {
        switch prominence {
        case .regular:
            AnyView(Color.clear)
        case .primary:
            AnyView(Color.clear)
        case .secondary:
            AnyView(Color.clear.overlay(
                Material.regularMaterial.opacity(0.2)
            ))
        }
    }

    var foreground: some ShapeStyle {
        switch prominence {
        case .regular:
            Color.white
        case .primary:
            Color.white
        case .secondary:
            Color.white.opacity(0)
        }
    }

    func body(content: Content) -> some View {
        content
            .fontWeight(weight)
            .padding()
            .padding(.leading, 20)
            .background(background)
            .overlay(overlay.allowsHitTesting(false))
            .clipShape(.rect(cornerRadius: 10))
    }
}

struct SectionHeader: ViewModifier {
    var fontWeight: Font.Weight?
    var prominence: Prominence

    var background: some ShapeStyle {
        switch prominence {
        case .secondary:
            AnyShapeStyle(Color.clear)
        default:
            AnyShapeStyle(Material.regularMaterial.opacity(0.2))
        }
    }

    var weight: Font.Weight? {
        if fontWeight == nil, prominence == .regular {
            return nil
        }

        if fontWeight != nil {
            return fontWeight
        }

        switch prominence {
        case .regular:
            return .light
        case .primary:
            return .regular
        case .secondary:
            return .light
        }
    }

    var overlay: some View {
        switch prominence {
        case .regular:
            AnyView(Color.clear)
        case .primary:
            AnyView(Color.clear)
        case .secondary:
            AnyView(Color.clear.overlay(
                Material.regularMaterial.opacity(0.2)
            ))
        }
    }

    func body(content: Content) -> some View {
        content
            .fontWeight(weight)
            .padding()
            .background(background)
            .overlay(overlay.allowsHitTesting(false))
            .clipShape(.rect(cornerRadius: 10))
    }
}

enum Prominence {
    case regular, primary, secondary
}

struct HiddenSystemBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .introspect(
                .navigationStack, on: .iOS(.v18),
                scope: .ancestor
            ) { something in
                let allsubviews = something.view.allSubViews
                for view in allsubviews {
                    if view.backgroundColor == .systemBackground,
                       view.debugDescription.contains(
                           "NavigationStackHostingController")
                    {
                        view.backgroundColor = nil
                    }
                }
            }
    }
}

extension View {
    func sectionHeader(_ prominence: Prominence = .regular, _ fontWeight: Font.Weight? = nil) -> some View {
        modifier(SectionHeader(fontWeight: fontWeight, prominence: prominence))
    }

    func sectionContent(_ prominence: Prominence = .regular, _ fontWeight: Font.Weight? = nil) -> some View {
        modifier(SectionContent(fontWeight: fontWeight, prominence: prominence))
    }

    func hideSystemBackground() -> some View {
        modifier(HiddenSystemBackground())
    }
}
