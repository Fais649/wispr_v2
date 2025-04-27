
//
//  ItemFormDateShelfView.swift
//  wispr
//
//  Created by Faisal Alalaiwat on 29.03.25.
//
import SwiftData
import SwiftUI

struct ItemFormArchiveShelfView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(ThemeStateService.self) private var theme: ThemeStateService

    @Query(
        filter: #Predicate<Item> { item in item.archived },
        sort: \Item.timestamp, order: .reverse
    ) var archivedItems: [Item]

    @Namespace var animation

    func title() -> some View {
        Text("Archive")
    }

    @Binding var text: String
    @Binding var taskData: TaskData?
    @Binding var book: Book?
    @Binding var chapter: Chapter?
    @Binding var children: [Item]

    var todayDate: Date {
        Calendar.current.roundToNearestHalfHour(Date())
    }

    func unarchive(_ item: Item) {
        withAnimation {
            self.taskData = item.taskData
            self.text = item.text
            self.book = item.book
            self.chapter = item.chapter
            self.children = item.children
            item.delete()
            dismiss()
        }
    }

    var body: some View {
        Screen(
            .archiveShelf,
            loaded: true,
            title: title
        ) {
            ScrollView {
                Disclosures(
                    animation: animation,
                    items: archivedItems,
                    itemRow: { item in
                        Button {
                            withAnimation { unarchive(item) }
                        } label: {
                            ItemRowLabel(item: item, editOnClick: false)
                                .contentShape(Rectangle())
                        }
                        .parentItem()
                    },
                    childRow: { item in
                        Button {
                            if let parent = item.parent {
                                withAnimation { unarchive(parent) }
                            }
                        } label: {
                            ItemRowLabel(item: item, editOnClick: false)
                                .contentShape(Rectangle())
                        }
                        .contentShape(Rectangle())
                        .childItem()
                    }
                )
            }.padding(.vertical, Spacing.m)
        }
        .shelfScreenStyle([.fraction(0.6)])
    }
}
