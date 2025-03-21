//
//  ItemForm.swift
//  wispr
//
//  Created by Faisal Alalaiwat on 21.03.25.
//

import SwiftData
import SwiftUI

struct ItemForm: View {
    @Environment(NavigatorService.self) private var nav: NavigatorService
    @Environment(\.modelContext) private var modelContext: ModelContext
    @Environment(
        CalendarService
            .self
    ) private var calendarService: CalendarService
    @FocusState var focus: FocusedField?

    var item: Item

    @State private var text: String
    @State private var taskData: TaskData?
    @State private var eventData: EventData?
    @State private var children: [Item]
    @State private var tags: [Tag]
    @State private var sheet: ItemFormSheets? = nil

    init(item: Item) {
        let i = item
        self.item = i
        text = i.text
        taskData = i.taskData
        eventData = i.eventData
        children = i.children
        tags = i.tags
    }

    enum ItemFormSheets: String, Identifiable {
        case tags, event
        var id: Self { self }
    }

    @State var isExpanded = true

    var body: some View {
        List {
            DisclosureGroup(isExpanded: $isExpanded) {
                ForEach(
                    children.sorted(by: { $0.position < $1.position }),
                    id: \.self
                ) { child in
                    Child(children: $children, child: child, focus: $focus)
                        .fontWeight(.light)
                }
            } label: {
                TextField("...", text: $text, axis: .vertical)
                    .focused($focus, equals: .item(id: item.id))
                    .background(item.backgroundColor)
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
                    .onChange(of: text) {
                        guard text.contains("\n") else { return }
                        text = text.replacing("\n", with: "")

                        if text.isEmpty {
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
                    .onAppear {
                        if text.isEmpty {
                            focus = .item(id: item.id)
                        }
                    }
            }
            .itemDisclosureGroupStyler(hideExpandButton: true)
        }
        .defaultScrollAnchor(.top)
        .navigatorDatePickerButtonLabel {
            HStack {
                DefaultDatePickerButtonLabel()
                Image(systemName: item.isEvent ? "clock.fill" : "clock")

                if let event = item.eventData {
                    Text(
                        event.startDate
                            .formatted(.dateTime.hour().minute())
                    )
                    Divider().frame(height: 12)
                    Text(event.endDate.formatted(.dateTime.hour().minute()))
                }
            }
        }
        .onDisappear {
            item.commit(
                modelContext,
                text: text,
                taskData: taskData,
                eventData: eventData,
                tags: tags,
                children: children.filter { $0.text.isNotEmpty }
            )
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .sheet(item: $sheet) { _ in
            VStack {
                TagSelector(selectedItemTags: $tags)
            }
        }
        .toolbarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(text.isEmpty)
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
        }.hideSystemBackground()
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

                TextField("", text: $child.text, axis: .vertical)
                    .focused($focus, equals: .item(id: child.id))
                    .onChange(of: child.text) {
                        guard isFocused() else { return }
                        guard child.text.contains("\n") else { return }
                        child.text = child.text.replacing(
                            "\n",
                            with: ""
                        )

                        if child.text.isNotEmpty {
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
                        } else {
                            children.removeAll { $0.id == child.id }
                        }
                    }
            }
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
