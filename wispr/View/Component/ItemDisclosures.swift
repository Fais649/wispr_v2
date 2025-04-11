//
//  ItemDisclosures.swift
//  wispr
//
//  Created by Faisal Alalaiwat on 21.03.25.
//
import SwiftData
import SwiftUI

struct ItemDisclosures: View {
    @Environment(
        Globals
            .self
    ) private var globals: Globals
    @Environment(
        NavigationStateService
            .self
    ) private var navigationStateService: NavigationStateService
    @Environment(
        FlashStateService
            .self
    ) private var flashService: FlashStateService
    @Environment(\.modelContext) private var modelContext: ModelContext

    @Environment(\.editMode) var editMode
    var isEditing: Bool {
        if let editMode {
            return editMode.wrappedValue.isEditing
        }

        return false
    }

    var animation: Namespace.ID

    var defaultExpanded: Bool = false
    var items: [Item]

    func onMove(_ indexSet: IndexSet, _ newIndex: Int) {
        let (success, message) = ItemStore.updatePositions(
            items: items,
            indexSet: indexSet,
            newIndex: newIndex
        )

        if !success {
            withAnimation {
                flashService.flash = FlashData(type: .error, message: message)
            }
        } else {
            try? modelContext.save()
        }
    }

    func onMoveChild(_ item: Item, _ indexSet: IndexSet, _ newIndex: Int) {
        item.moveChild(from: indexSet, to: newIndex)
    }

    var body: some View {
        Disclosures(
            animation: animation,
            defaultExpanded: defaultExpanded,
            items: items,
            onMove: onMove,
            onDelete: delete,
            onMoveChild: onMoveChild,
            onDeleteChild: delete
        ) { item in
            label(item)
                .id(item.id)
                .padding(Spacing.s)
                .matchedGeometryEffect(id: item.id, in: animation)
        } childRow: { child in
            row(child)
                .padding(Spacing.s)
                .id(child.id)
        }
        .listRowInsets(EdgeInsets())
        .opacity(flashService.isFlashing ? 0 : 1)
    }

    @ViewBuilder
    func label(_ item: Item) -> some View {
        AniButton(padding: Spacing.xxs) {
            navigationStateService.goToItemForm(item)
        } label: {
            HStack {
                VStack(alignment: .leading) {
                    Text(item.text)
                        .truncationMode(.tail)
                        .lineLimit(1)

                    if let e = item.eventData, !e.allDay {
                        HStack {
                            Text(
                                e.startDate
                                    .formatted(
                                        .dateTime.hour()
                                            .minute()
                                    )
                            )
                            .eventTimeFontStyle()
                            Text("-")
                                .eventTimeFontStyle()
                            Text(
                                e.endDate
                                    .formatted(
                                        .dateTime.hour()
                                            .minute()
                                    )
                            )
                            .eventTimeFontStyle()
                        }
                    }
                }
            }
        }
        .parentItem()
        .padding(Spacing.s)
        .buttonStyle(.plain)
        .swipeActions(edge: .leading) {
            self.archiveButton(item)
        }.swipeActions(edge: .trailing) {
            self.deleteButton(item)
        }
    }

    func row(_ child: Item) -> some View {
        HStack {
            AniButton(padding: Spacing.s) {
                if var task = child.taskData {
                    withAnimation {
                        task.completedAt = task
                            .completedAt == nil ? Date() : nil
                        child.taskData = task
                    }
                }
            } label: {
                if let task = child.taskData {
                    Image(
                        systemName: task.completedAt == nil ? "square.dotted" :
                            "square.fill"
                    )
                    .buttonFontStyle()
                    .scaleEffect(0.8)
                }

                Text(child.position.description)
                Text(child.text)
                    .multilineTextAlignment(.leading)
            }.buttonStyle(.plain)

            Spacer()
        }
        .contentShape(Rectangle())
        .padding(Spacing.xxs)
        .childItem()
        .swipeActions(edge: .trailing) {
            self.deleteButton(child)
        }
    }

    @ViewBuilder
    func archiveButton(_ item: Item) -> some View {
        AniButton {
            self.archive(item)
        } label: {
            Image(systemName: "archivebox.fill")
        }
        .tint(.clear)
    }

    @ViewBuilder
    func deleteButton(_ item: Item) -> some View {
        Button(role: .destructive) {
            withAnimation {
                self.delete(item)
            }
        } label: {
            Image(systemName: "trash.fill")
        }
        .tint(.clear)
    }

    func archive(_ item: Item) {
        checkEventData(item)
        withAnimation {
            item.archived = true
            item.archivedAt = Date()
        }
    }

    func onDelete(_ indexSet: IndexSet) {
        guard let index = indexSet.first else {
            return
        }

        let item = items[index]
        checkEventData(item)
        withAnimation {
            self.modelContext.delete(item)
        }
    }

    func delete(_ item: Item) {
        checkEventData(item)
        withAnimation {
            self.modelContext.delete(item)
        }
    }

    func checkEventData(_ item: Item) {
        if item.isEvent {
            Task {
                item.toggleEvent()
            }
        }
    }
}
