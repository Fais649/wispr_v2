//
//  ItemDisclosureGroup.swift
//  wispr
//
//  Created by Faisal Alalaiwat on 21.03.25.
//
import SwiftData
import SwiftUI

struct DGroups: View {
    @Environment(\.modelContext) private var modelContext: ModelContext
    var items: [Item]
    var animated = false
    var withSwipe = false
    @State var flash: Flash? = nil

    var body: some View {
        if let flash {
            HStack {
                flash.icon.font(.system(size: 32))
                Text(flash.message)
            }.onAppear {
                DispatchQueue.main.asyncAfter(
                    deadline: .now() +
                        2.5
                ) {
                    withAnimation {
                        self.flash = nil
                    }
                }
            }.listRowBackground(Color.clear)
        }

        ForEach(items) { item in
            DGroup(
                item: item,
                animated: self.animated,
                withSwipe: self.withSwipe
            )
        }
        .onMove { indexSet, newIndex in
            let (success, message) = ItemStore.updatePositions(
                items: items,
                indexSet: indexSet,
                newIndex: newIndex
            )

            if !success {
                self.flash = Flash(type: .error, message: message)
            }
        }
        .opacity(flash != nil ? 0 : 1)
    }
}

struct DGroup: View {
    @Environment(\.modelContext) private var modelContext: ModelContext
    @Environment(NavigatorService.self) private var nav: NavigatorService
    var item: Item
    var animated = false
    var withSwipe = false
    @State var opacity: CGFloat = 1
    @State var blur: CGFloat = 0

    var body: some View {
        DisclosureGroup {
            ForEach(self.item.children) { child in
                self.row(child)
            }.onMove { indexSet, newIndex in
                self.item.children.move(
                    fromOffsets: indexSet,
                    toOffset: newIndex
                )
                for (index, child) in self.item.children.enumerated() {
                    child.position = index
                }
            }
        } label: {
            self.label
        }
        .itemDisclosureGroupStyler(
            isAnimated: animated,
            hideExpandButton: item.children.isEmpty
        )
    }

    var label: some View {
        AniButton {
            self.nav.activeDate = self.item.timestamp
            self.nav.path.append(.itemForm(item: self.item))
        } label: {
            HStack(alignment: .firstTextBaseline, spacing: 0) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(self.item.text).lineLimit(1)

                    if let e = item.eventData {
                        HStack(alignment: .firstTextBaseline, spacing: 2) {
                            Text(
                                e.startDate
                                    .formatted(.dateTime.hour().minute())
                            ).font(.system(size: 12)).fontWeight(.thin)
                            Text("-").font(.system(size: 12)).fontWeight(.thin)
                            Text(e.endDate.formatted(.dateTime.hour().minute()))
                                .font(.system(size: 12)).fontWeight(.thin)
                        }
                    }
                }
                Spacer()
            }
        }
        .contentShape(Rectangle())
        .background(item.backgroundColor)
        .buttonStyle(.plain)
        .swipeActions(edge: .leading) {
            self.archiveButton(self.item)
        }.swipeActions(edge: .trailing) {
            self.deleteButton(self.item)
        }
    }

    func row(_ child: Item) -> some View {
        HStack(spacing: 0) {
            if var task = child.taskData {
                AniButton {
                    task.completedAt = task
                        .completedAt == nil ? Date() : nil
                    child.taskData = task
                } label: {
                    Image(
                        systemName: task
                            .completedAt == nil ? "circle.dotted" :
                            "circle.fill"
                    )
                }
            }

            Text(child.text)
            Spacer()
        }
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
        AniButton {
            self.delete(item)
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

    func delete(_ item: Item) {
        checkEventData(item)
        withAnimation {
            self.modelContext.delete(item)
        }
    }

    func checkEventData(_ item: Item) {
        if item.isEvent {
            Task {
                item.toggleEventData()
            }
        }
    }
}

struct DGroupHeader: View {
    @Environment(NavigatorService.self) private var nav: NavigatorService
    var item: Item

    var body: some View {
        AniButton {
            self.nav.activeDate = self.item.timestamp
            self.nav.path.append(contentsOf: [
                .dayScreen,
                .itemForm(item: self.item),
            ])
        } label: {
            Text(self.item.text)
        }.background(item.backgroundColor)
            .buttonStyle(.plain)
    }
}

struct DGroupContent: View {
    @Environment(\.modelContext) private var modelContext: ModelContext
    @Environment(NavigatorService.self) private var nav: NavigatorService
    var item: Item

    var body: some View {
        ForEach(item.children) { child in
            HStack(spacing: 0) {
                if var task = child.taskData {
                    AniButton {
                        task.completedAt = task
                            .completedAt == nil ? Date() : nil
                        child.taskData = task
                    } label: {
                        Text(task.completedAt == nil ? "[ ]" : "[x]")
                    }
                }

                Text(child.text)
                Spacer()
            }
        }
    }
}
