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
    @Environment(\.modelContext) private var modelContext: ModelContext
    @FocusState var focus: FocusedField?

    var item: Item

    @State private var timestamp: Date
    @State private var text: String
    @State private var taskData: TaskData?
    @State private var eventFormData: EventData.FormData?
    @State private var children: [Item]
    @State private var tags: [Tag]
    @State private var initialBook: Book?
    @State private var initialChapter: Tag?

    @State var showDateShelf: Bool = false
    @State var showBookShelf: Bool = false

    init(item: Item) {
        let i = item
        self.item = i
        timestamp = i.timestamp
        text = i.text
        taskData = i.taskData
        eventFormData = i.eventData?.formData()
        children = i.children
        tags = i.tags
    }

    enum ItemFormSheets: String, Identifiable {
        case tags, event
        var id: Self { self }
    }

    @State var isExpanded = true

    func title() -> some View {
        VStack {
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
        }
    }

    @ViewBuilder
    func trailingTitle() -> some View {
        Text(timestamp.formatted(.dateTime.day().month().year()))
    }

    @ViewBuilder
    func subtitle() -> some View {
        if let eventFormData {
            HStack {
                Spacer()
                Text(
                    eventFormData.startDate
                        .formatted(.dateTime.hour().minute())
                )
                Text("-")
                Text(eventFormData.endDate.formatted(.dateTime.hour().minute()))
            }
        }
    }

    var body: some View {
        Screen(
            .itemForm(item: item),
            title: title,
            trailingTitle: trailingTitle,
            subtitle: subtitle,
            dateShelf: ItemFormDateShelfView($eventFormData, $timestamp)
        ) {
            Lst {
                ForEach(
                    children.sorted(by: { $0.position < $1.position }),
                    id: \.self
                ) { child in
                    Child(children: $children, child: child, focus: $focus)
                }
            }
        }.task {
            if tags.isNotEmpty {
                initialBook = navigationStateService.bookState.book
                initialChapter = navigationStateService.bookState.chapter

                await navigationStateService.bookState.setBook(from: tags)
                if text.isEmpty {
                    focus = .item(id: item.id)
                }
            }
        }
        .onDisappear {
            if let book = navigationStateService.bookState.book {
                tags = book.tags
            }

            if let chapter = navigationStateService.bookState.chapter {
                tags = [chapter]
            }

            item.commit(
                timestamp: timestamp,
                text: text,
                taskData: taskData,
                eventFormData: eventFormData,
                tags: tags,
                children: children.filter { $0.text.isNotEmpty }
            )

            withAnimation {
                navigationStateService.bookState.chapter = initialChapter
                navigationStateService.bookState.book = initialBook
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                HStack {
                    AniButton {
                        focus = nil
                    } label: {
                        Image(systemName: "keyboard")
                    }

                    Divider()

                    Spacer()
                }
            }
        }
    }

    struct Child: View {
        @Environment(\.modelContext) private var modelContext: ModelContext
        @Binding var children: [Item]
        @State var child: Item
        @FocusState.Binding var focus: FocusedField?

        func isFocused() -> Bool {
            focus == .item(id: child.id)
        }

        var body: some View {
            HStack {
                if child.isTask {
                    AniButton {
                        child.toggleTaskDataCompletedAt()
                    } label: {
                        Image(
                            systemName: child.isTaskCompleted ? "circle.fill" :
                                "circle.dotted"
                        )
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
                if isFocused() {
                    ToolbarItemGroup(placement: .keyboard) {
                        HStack {
                            Divider()
                            AniButton {
                                print("add_audio")
                            } label: {
                                Image(systemName: "link")
                            }.disabled(child.text.isEmpty)

                            Divider()

                            AniButton {
                                child.toggleTaskData()
                            } label: {
                                Image(
                                    systemName: child
                                        .isTask ? "circle.fill" :
                                        "circle.dotted"
                                )
                            }.disabled(child.text.isEmpty)
                        }
                    }
                }
            }
        }
    }
}
