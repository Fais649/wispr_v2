//
//  ItemForm.swift
//  wispr
//
//  Created by Faisal Alalaiwat on 21.03.25.
//

import SwiftData
import SwiftUI

struct ItemForm: View {
    @Environment(
        NavigationStateService
            .self
    ) private var navigationStateService: NavigationStateService

    @Environment(
        DayStateService
            .self
    ) private var dayState: DayStateService

    @Environment(
        BookStateService
            .self
    ) private var bookState: BookStateService
    @Environment(
        ThemeStateService
            .self
    ) private var theme: ThemeStateService
    @Environment(\.modelContext) private var modelContext: ModelContext
    @FocusState var focus: FocusedField?

    var animation: Namespace.ID
    var item: Item

    @State private var timestamp: Date
    @State private var text: String
    @State private var taskData: TaskData?
    @State private var eventFormData: EventData.FormData?
    @State private var children: [Item]

    @State private var book: Book?
    @State private var chapter: Chapter?
    @State var showDateShelf: Bool = false
    @State var showBookShelf: Bool = false

    init(animation: Namespace.ID, item: Item) {
        let i = item
        self.item = i
        self.animation = animation
        book = i.book
        timestamp = i.timestamp
        text = i.text
        taskData = i.taskData
        eventFormData = i.eventData?.formData()
        children = i.children
        chapter = i.chapter
    }

    enum ItemFormSheets: String, Identifiable {
        case tags, event
        var id: Self { self }
    }

    @State var isExpanded = true
    @State var appeared = false

    var isToday: Bool {
        Calendar.current.isDateInToday(timestamp)
    }

    func title() -> some View {
        TxtField(
            label: "...",
            text: $text,
            focusState: $focus,
            focus: .item(id: item.id)
        ) { isTextEmpty in
            if isTextEmpty {
                focus = .item(id: item.id)
                return
            }

            let newChild = ItemStore.create(
                timestamp: item.timestamp,
                parent: item,
                position: children.count,
                taskData: item.taskData
            )
            children.append(newChild)
            DispatchQueue.main.async {
                focus = .item(id: newChild.id)
            }
        }
        .onChange(of: focus) {
            if case let .item(id: id) = focus {
                let toDelete = children
                    .filter { $0.text.isEmpty && $0.id != id }
                children
                    .removeAll {
                        toDelete.map { $0.id }.contains($0.id)
                    }
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .bottomBar) {
                HStack {
                    Spacer()
                    ToolbarButton {
                        navigationStateService.goBack()
                    } label: {
                        Image(
                            systemName: "chevron.down"
                        )
                    }
                    Spacer()
                }
            }

            ToolbarItemGroup(placement: .keyboard) {
                ToolbarButton(padding: 0) {
                    focus = nil
                } label: {
                    Image(
                        systemName: "keyboard.chevron.compact.down"
                    )
                }

                ToolbarButton {
                    navigationStateService.toggleBookShelf()
                } label: {
                    HStack {
                        Image(systemName: "line.diagonal")
                            .opacity(book == nil ? 0.4 : 1)
                            .scaleEffect(
                                book == nil ? 0.6 : 1,
                                anchor: .center
                            )

                        if let book {
                            Text(book.name)
                            if let chapter {
                                Image(systemName: "line.diagonal")
                                Text(chapter.name)
                            }
                        } else {
                            Image(systemName: "asterisk")
                                .resizable()
                                .scaledToFit()
                                .contentShape(Rectangle())
                                .frame(width: 16, height: 16)
                        }
                    }
                }

                ToolbarButton {
                    showDateShelf.toggle()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "line.diagonal")
                            .opacity(isToday ? 0.4 : 1)
                            .scaleEffect(
                                isToday ? 0.6 : 1,
                                anchor: .center
                            )

                        if !isToday {
                            Text(
                                timestamp
                                    .formatted(
                                        .dateTime.day(.twoDigits)
                                            .month(.twoDigits)
                                            .year(.twoDigits)
                                    )
                            )
                        } else {
                            Image(systemName: "circle.fill")
                                .resizable()
                                .scaledToFit()
                                .contentShape(Rectangle())
                                .frame(width: 12, height: 12)
                        }
                    }
                }
                .sheet(isPresented: $showDateShelf) {
                    ItemFormDateShelfView($eventFormData, $timestamp)
                        .presentationDetents([.fraction(0.75)])
                        .presentationCornerRadius(0)
                        .presentationBackground {
                            Rectangle().fill(
                                theme.activeTheme
                                    .backgroundMaterialOverlay
                            )
                            .fade(
                                from: .bottom,
                                fromOffset: 0.6,
                                to: .top,
                                toOffset: 1
                            )
                        }
                }
                Divider()
                Spacer()
            }
        }
    }

    func formattedDate(_ date: Date) -> String {
        guard let eventFormData else {
            return ""
        }

        let calendar = Calendar.current
        if calendar.isDate(date, inSameDayAs: eventFormData.startDate) {
            return date.formatted(.dateTime.hour().minute())
        } else {
            let daysDifference = calendar.dateComponents(
                [.day],
                from: calendar.startOfDay(for: eventFormData.startDate),
                to: calendar.startOfDay(for: date)
            ).day ?? 0
            return date
                .formatted(.dateTime.hour().minute()) + "+\(daysDifference)"
        }
    }

    @ViewBuilder
    func trailingTitle() -> some View {
        DateTrailingTitleLabel(
            date: timestamp
        )
    }

    @ViewBuilder
    func subtitle() -> some View {
        HStack {
            if let eventFormData {
                Text(formattedDate(eventFormData.startDate))
                    .eventTimeFontStyle()
                Text("-")
                    .eventTimeFontStyle()
                Text(formattedDate(eventFormData.endDate))
                    .eventTimeFontStyle()
            }

            Spacer()
            Text(
                timestamp
                    .formatted(
                        .dateTime.weekday(.abbreviated).day().month()
                            .year()
                    )
            )
        }
    }

    var body: some View {
        Screen(
            .itemForm(item: item),
            title: title,
            trailingTitle: trailingTitle,
            subtitle: subtitle,
            bookShelf: ItemFormBookShelfView(
                animation: animation,
                book: $book,
                chapter: $chapter
            ),
            backgroundOpacity: 0
        ) {
            ScrollView {
                ForEach(
                    children.sorted(by: { $0.position < $1.position }),
                    id: \.self
                ) { child in
                    Child(children: $children, child: child, focus: $focus)
                }
            }
            .safeAreaPadding(Spacing.m)
            .safeAreaPadding(.bottom, Spacing.m)
        }
        .safeAreaPadding(Spacing.m)
        .onChange(of: book) {
            if let book {
                withAnimation {
                    navigationStateService.tempBackground = {
                        AnyView(
                            RandomMeshBackground(color: book.color)
                        )
                    }
                }
            }
        }
        .onAppear {
            if text.isEmpty {
                focus = .item(id: item.id)
                book = bookState.book
            }
        }
        .onDisappear {
            Task {
                item.commit(
                    timestamp: timestamp,
                    text: text,
                    taskData: taskData,
                    eventFormData: eventFormData,
                    book: book,
                    chapter: chapter,
                    children: children.filter { $0.text.isNotEmpty }
                )
            }

            withAnimation {
                navigationStateService.tempBackground = nil
            }
        }.background {
            if let book {
                RandomMeshBackground(color: book.color)
                    .ignoresSafeArea()
            }
        }
    }

    struct Child: View {
        @Environment(\.modelContext) private var modelContext: ModelContext
        @Binding var children: [Item]
        @State var child: Item
        @FocusState.Binding var focus: FocusedField?

        var isFocused: Bool {
            focus == .item(id: child.id)
        }

        var body: some View {
            HStack {
                if child.isTask {
                    AniButton {
                        child.toggleTaskDataCompletedAt()
                    } label: {
                        Image(
                            systemName: child.isTaskCompleted ? "square.fill" :
                                "square.dotted"
                        )
                        .scaleEffect(0.8)
                    }
                }

                TxtField(
                    label: "",
                    text: $child.text,
                    focusState: $focus,
                    focus: .item(id: child.id)
                ) { textEmpty in
                    if textEmpty {
                        children.removeAll { $0.id == child.id }
                        return
                    }

                    guard let i = children.firstIndex(of: child) else {
                        return
                    }

                    let index = i + 1 <= children.endIndex
                        ? i + 1
                        : children.count

                    let newChild = ItemStore.create(
                        timestamp: child.timestamp,
                        parent: child.parent,
                        position: index,
                        taskData: child.taskData
                    )

                    children.insert(
                        newChild,
                        at: index
                    )

                    DispatchQueue.main.async {
                        focus = .item(id: newChild.id)
                    }
                }
            }
            .childItem()
            .toolbar {
                if isFocused {
                    ToolbarItemGroup(placement: .keyboard) {
                        Divider()

                        AniButton {
                            child.toggleTaskData()
                        } label: {
                            Image(
                                systemName: child
                                    .isTask ? "square.fill" :
                                    "square.dotted"
                            )
                            .scaleEffect(0.8)
                        }
                    }
                }
            }
        }
    }
}
