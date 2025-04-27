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

    @State private var images: [ImageData]

    @State private var book: Book?
    @State private var chapter: Chapter?

    @State var showDateShelf: Bool = false
    @State var showBookShelf: Bool = false
    @State var showArchiveShelf: Bool = false

    init(animation: Namespace.ID, item: Item) {
        let i = item
        self.item = i
        self.animation = animation
        book = i.book
        chapter = i.chapter
        timestamp = i.timestamp
        text = i.text
        taskData = i.taskData
        eventFormData = i.eventData?.formData()
        children = i.children
        images = i.imageData ?? []
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

    var isFocused: Bool {
        focus == .item(id: item.id)
    }

    func title() -> some View {
        HStack {
            if item.isTask {
                Button {
                    withAnimation {
                        item.toggleTaskDataCompletedAt()
                        taskData = item.taskData
                    }
                } label: {
                    Image(
                        systemName: item.isTaskCompleted ? "square.fill" :
                            "square.dotted"
                    )
                    .scaleEffect(0.8)
                }
            }

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
                if navigationStateService.pathState.onItemForm {
                    ToolbarItemGroup(placement: .bottomBar) {
                        HStack {
                            ToolbarButton {
                                withAnimation {
                                    item.archive()
                                }
                            } label: {
                                Image(
                                    systemName: "tray.and.arrow.down.fill"
                                )
                            }

                            Spacer()

                            ToolbarButton {
                                navigationStateService.goBack()
                            } label: {
                                Image(
                                    systemName: "chevron.down"
                                )
                            }

                            Spacer()

                            ToolbarButton {
                                withAnimation {
                                    item.delete()
                                }
                            } label: {
                                Image(
                                    systemName: "trash.fill"
                                )
                            }
                        }.padding(.horizontal, Spacing.s)
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

                    BookShelfButton(
                        book: $book,
                        chapter: $chapter
                    ) {
                        ItemFormBookShelfView(
                            animation: animation,
                            book: $book,
                            chapter: $chapter
                        )
                    }

                    DateShelfButton(date: $timestamp) {
                        ItemFormDateShelfView(
                            $eventFormData,
                            $timestamp
                        )
                    }

                    Divider()
                    Spacer()

                    if isFocused {
                        ToolbarButton {
                            withAnimation {
                                item.toggleTaskData()
                                taskData = item.taskData
                            }
                        } label: {
                            Image(
                                systemName: item.isTask ? "square.fill" :
                                    "square.dotted"
                            )
                        }
                    }
                }
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
    func subtitle() -> some View {
        VStack {
            HStack {
                DateTrailingTitleLabel(
                    date: timestamp,
                    withWeekday: true
                )

                Text(
                    timestamp
                        .formatted(
                            .dateTime.day().month().year(.twoDigits)
                        )
                )
                Spacer()

                if let eventFormData {
                    VStack {
                        HStack(alignment: .top) {
                            Text(formattedDate(eventFormData.startDate))
                                .eventTimeFontStyle()
                        }

                        HStack(alignment: .bottom) {
                            Text(formattedDate(eventFormData.endDate))
                                .eventTimeFontStyle()
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    func trailingFooter() -> some View {
        HStack {
            EmptyView()
        }
        .frame(
            width: showFooter ? Spacing.xxl * 1.5 : Spacing.xl,
            height: showFooter ? Spacing.xxl * 1.5 : Spacing.l
        )
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation {
                showFooter.toggle()
            }
        }
    }

    @State var showFooter: Bool = false
    var body: some View {
        Screen(
            .itemForm(item: item),
            title: title,
            subtitle: subtitle,
            trailingFooter: trailingFooter,
            backgroundOpacity: 0
        ) {
            ScrollView {
                VStack {
                    ForEach(
                        children.sorted(by: { $0.position < $1.position }),
                        id: \.self
                    ) { child in
                        Child(children: $children, child: child, focus: $focus)
                    }
                }
                .safeAreaPadding(Spacing.m)
                .safeAreaPadding(.bottom, Spacing.l)
            }
        }
        .task {
            focus = .item(id: item.id)

            if text.isEmpty {
                book = bookState.book
            }
        }
        .onDisappear {
            withAnimation {
                // item.commit(
                //     timestamp: timestamp,
                //     text: text,
                //     taskData: taskData,
                //     eventFormData: eventFormData,
                //     book: book,
                //     chapter: chapter,
                //     children: children.filter { $0.text.isNotEmpty },
                //     images: images
                // )
            }
        }.background {
            Rectangle()
                .fill(.ultraThinMaterial)
                .overlay {
                    if let book {
                        Rectangle()
                            .fill(book.color)
                            .opacity(0.3)
                    } else {
                        Rectangle()
                            .fill(item.shadowTint)
                            .opacity(0.3)
                    }
                }
                .ignoresSafeArea()
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
                    Button {
                        withAnimation {
                            child.toggleTaskDataCompletedAt()
                        }
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
            .padding(.vertical, Spacing.s)
            .childItem()
            .toolbar {
                if isFocused {
                    ToolbarItemGroup(placement: .keyboard) {
                        HStack {
                            AniButton {
                                withAnimation {
                                    child.toggleTaskData()
                                }
                            } label: {
                                Image(
                                    systemName: child
                                        .isTask ? "square.fill" :
                                        "square.dotted"
                                )
                            }
                        }
                    }
                }
            }
        }
    }
}
