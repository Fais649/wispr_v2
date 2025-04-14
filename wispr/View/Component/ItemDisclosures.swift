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

    var expandable: Bool = true
    var defaultExpanded: Bool = false
    var items: [Item]
    var prefix: Int? = nil

    func onMove(_ indexSet: IndexSet, _ newIndex: Int) {
        let _ = ItemStore.updatePositions(
            items: items,
            indexSet: indexSet,
            newIndex: newIndex
        )
    }

    func onMoveChild(_ item: Item, _ indexSet: IndexSet, _ newIndex: Int) {
        var c = item.children
        c.move(fromOffsets: indexSet, toOffset: newIndex)
        for (index, child) in c.enumerated() {
            child.position = index
        }
        item.setChildren(c)
    }

    var body: some View {
        Disclosures(
            animation: animation,
            expandable: expandable,
            defaultExpanded: defaultExpanded,
            items: items,
            prefix: prefix,
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

    func formattedDate(from d: Date, _ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDate(date, inSameDayAs: d) {
            return date.formatted(.dateTime.hour().minute())
        } else {
            let daysDifference = calendar.dateComponents(
                [.day],
                from: calendar.startOfDay(for: d),
                to: calendar.startOfDay(for: date)
            ).day ?? 0
            return date
                .formatted(.dateTime.hour().minute()) + "+\(daysDifference)"
        }
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
                        HStack(spacing: 0) {
                            Text(formattedDate(from: e.startDate, e.startDate))
                                .eventTimeFontStyle()
                            Text("-")
                                .eventTimeFontStyle()
                            Text(formattedDate(from: e.startDate, e.endDate))
                                .eventTimeFontStyle()
                        }
                    }
                }
            }
        }
        .parentItem()
        .padding(Spacing.s)
        .buttonStyle(.plain)
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

                Text(child.text)
                    .multilineTextAlignment(.leading)
            }.buttonStyle(.plain)

            Spacer()
        }
        .contentShape(Rectangle())
        .padding(Spacing.xxs)
        .childItem()
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
