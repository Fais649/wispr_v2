//
//  DayScreen.swift
//  wispr
//
//  Created by Faisal Alalaiwat on 21.03.25.
//
import SwiftData
import SwiftUI

struct DayCell: View {
    @Environment(\.modelContext) private var modelContext: ModelContext
    @Environment(
        NavigationStateService
            .self
    ) private var navigationStateService:
        NavigationStateService

    @Environment(
        BookStateService
            .self
    ) private var bookState: BookStateService

    @Environment(
        DayStateService
            .self
    ) private var dayState: DayStateService

    var animation: Namespace.ID

    var day: Day
    var backgroundOpacity: CGFloat = 0.5

    var parentItems: [Item] {
        day.items
            .filter { $0.parent == nil && !$0.archived && $0.text.isNotEmpty }
    }

    var noAllDayEvents: [Item] {
        let items = ItemStore.filterAllDayEvents(from: parentItems)
        if let book = bookState.book {
            return items.filter { $0.book == book }
        }
        return items.sorted(by: { $0.position < $1.position })
    }

    func createGeometryID(date: Date, suffix: String) -> String {
        return date.hashValue.description + suffix
    }

    var bgRect: some Shape {
        RoundedRectangle(cornerRadius: 4)
    }

    @ViewBuilder
    func bg(_ item: Item) -> some View {
        bgRect
            .fill(.ultraThinMaterial)
            .overlay(
                bgRect
                    .fill(item.shadowTint)
                    .opacity(0.4)
                    .overlay {
                        HStack {
                            bgRect
                                .stroke(item.shadowTint.opacity(0.3))
                        }
                        .padding(Spacing.xs)
                        .blur(radius: 5)
                    }
            )
            .ignoresSafeArea()
    }

    var body: some View {
        VStack(alignment: .leading) {
            ForEach(noAllDayEvents) { item in
                HStack {
                    Text(item.text)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .font(.system(size: 10))
                    Spacer()
                }
                .background {
                    bg(item)
                }
            }
            Spacer()
        }
    }
}

struct DayScreen: View {
    @Environment(\.modelContext) private var modelContext: ModelContext
    @Environment(
        NavigationStateService
            .self
    ) private var navigationStateService:
        NavigationStateService

    @Environment(
        BookStateService
            .self
    ) private var bookState: BookStateService

    @Environment(
        DayStateService
            .self
    ) private var dayState: DayStateService

    @FocusState var focus: FocusedField?
    @State private var highlight: FocusedField?

    var animation: Namespace.ID

    var day: Day
    var scrollView: Bool = true
    var titleStyle: TitleStyle = .regular
    var backgroundOpacity: CGFloat = 0.5

    var date: Date {
        day.date
    }

    var book: Book? {
        bookState.book
    }

    var chapter: Chapter? {
        bookState.chapter
    }

    @State var loaded: Bool = false

    @State var items: [Item] = []

    var path: Path {
        navigationStateService.pathState.active
    }

    var body: some View {
        Screen(
            .dayScreen,
            loaded: true,
            title: {
                DateTrailingTitleLabel(
                    date: date
                )
            },
            titleStyle: titleStyle,
            trailingTitle: {
                Text(
                    date
                        .formatted(
                            .dateTime
                                .weekday(.wide)
                        )
                )
            },
            subtitle: {
                HStack {
                    DateTitle(
                        date: date,
                        scrollTransition: false,
                        dateStringLeading: date
                            .formatted(
                                date: .long,
                                time: .omitted
                            )
                    )
                    Spacer()
                }

            },
            backgroundOpacity: backgroundOpacity
        ) {
            VStack {
                if loaded {
                    ScrollViewReader { proxy in
                        ScrollView {
                            ForEach(day.allDayEvents, id: \.id) { item in
                                HStack {
                                    Text(item.text)
                                    Spacer()
                                }
                                .fontWeight(.ultraLight)
                            }

                            ForEach(
                                $items,
                                id: \.id
                            ) { $item in
                                InLineItem(
                                    item: item,
                                    focus: $focus,
                                    highlight: $highlight
                                ).id(FocusedField.item(id: item.id))
                                    .contextMenu {
                                        Button(
                                            "Delete",
                                            systemImage: "trash.fill"
                                        ) {
                                            withAnimation {
                                                item.delete()
                                                items
                                                    .removeAll {
                                                        $0.id == item.id
                                                    }
                                            }
                                        }

                                        if !item.archived {
                                            Button(
                                                "Archive",
                                                systemImage: "tray.and.arrow.down.fill"
                                            ) {
                                                withAnimation {
                                                    item.archive()
                                                    items
                                                        .removeAll {
                                                            $0.id == item.id
                                                        }
                                                }
                                            }
                                        }
                                    }
                            }
                        }
                        .onChange(of: highlight) {
                            guard let item = highlight else { return }
                            withAnimation {
                                proxy.scrollTo(item, anchor: .top)
                            }
                        }
                        .onChange(of: focus) {
                            guard let item = focus else { return }
                            withAnimation {
                                proxy.scrollTo(item, anchor: .top)
                            }
                        }
                        .onTapGesture {
                            withAnimation {
                                highlight = nil
                            }
                            focus = nil
                        }
                    }
                    .safeAreaPadding(
                        .bottom,
                        focus == nil ? Spacing.none : Spacing.xl
                    )
                    .onChange(of: highlight) {
                        if highlight == nil {
                            withAnimation {
                                items.removeAll { $0.text.isEmpty }
                            }
                        }
                    }
                    .scrollBounceBehavior(.basedOnSize, axes: .vertical)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                } else {
                    Spacer()
                    HStack {
                        Spacer()
                        ProgressView()
                            .progressViewStyle(.circular)
                            .toolbarBackground(.hidden)
                            .toolbarBackgroundVisibility(.hidden)
                            .toolbarVisibility(.hidden)
                        Spacer()
                    }
                    Spacer()
                }
            }
            .task {
                let i = day.items.filter {
                    if let eventData = $0.eventData {
                        return $0.parent == nil && !$0.archived &&
                            !eventData.allDay
                    }

                    return $0.parent == nil && !$0.archived
                }
                .sorted(by: { $0.position < $1.position })

                items = i
                loaded = true
            }
            .onChange(of: navigationStateService.insertItem.insert) {
                guard navigationStateService.insertItem.insert else { return }
                let (_, insertItem, date) = navigationStateService.insertItem
                guard let date = date else { return }
                if
                    Calendar.current.isDate(
                        date,
                        inSameDayAs:
                        self.date
                    ), let i = insertItem
                {
                    i.timestamp = day.date
                    i.day = day
                    i.unarchive()
                    withAnimation {
                        items.append(i)
                    }
                    navigationStateService.insertItem = (false, nil, nil)
                }
            }
            .onChange(of: navigationStateService.addItem.add) {
                guard navigationStateService.addItem.add else { return }
                let (addItem, date) = navigationStateService.addItem
                if addItem, date == self.date {
                    let item =
                        ItemStore.create(
                            day: day,
                            timestamp: Calendar.current.combineDateAndTime(
                                date: self.date,
                                time: Date()
                            ),
                            book: book,
                            chapter: chapter
                        )

                    withAnimation {
                        items.append(item)
                    }
                    // focus = .item(id: item.id)

                    navigationStateService.addItem = (false, nil)
                }
            }
        }
        .onTapGesture {
            withAnimation {
                highlight = nil
            }
            focus = nil
        }
    }
}

struct TestDay: View {
    @Environment(\.modelContext) private var modelContext: ModelContext
    @Bindable var day: Day

    var body: some View {
        ForEach($day.items) { $item in
            TextField("", text: $item.text)
        }
    }
}
