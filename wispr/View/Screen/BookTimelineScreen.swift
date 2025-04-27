//
//  BookTimelineScreen.swift
//  wispr
//
//  Created by Faisal Alalaiwat on 21.03.25.
//
import SwiftData
import SwiftUI

struct BookTimelineScreen: View {
    @State var activeDate: Date?

    @FocusState var focus: FocusedField?
    @State private var highlight: FocusedField?

    @Query() var books: [Book]

    func title(_ name: String) -> some View {
        Text(name)
    }

    var body: some View {
        ForEach(books) { book in
            TestBookScreen(
                activeDate: activeDate, book: book
            )
            .tag(book.name)
        }
    }
}

struct TestBookScreen: View {
    @Environment(\.modelContext) private var modelContext: ModelContext

    @Environment(
        NavigationStateService
            .self
    ) private var navigationState:
        NavigationStateService
    @State var activeDate: Date?
    @FocusState var focus: FocusedField?
    @State private var highlight: FocusedField?

    @Bindable var book: Book

    func title(_ name: String) -> some View {
        Text(name)
    }

    @State private var grouped: [Day: [Item]] = [:]

    var bg: some View {
        RandomMeshBackground(color: book.colorTint)
    }

    var body: some View {
        Screen(
            .dayScreen,
            loaded: true,
            title: { title(book.name) },
            backgroundOpacity: 0.2
        ) {
            ScrollView {
                VStack {
                    ForEach(
                        $book.items
                            .sorted(by: {
                                $0.wrappedValue.timestamp > $1.wrappedValue
                                    .timestamp
                            }),
                        id: \.id
                    ) { $item in
                        InLineItem(
                            item: item,
                            focus: $focus,
                            highlight: $highlight
                        )
                    }
                }
            }
            .padding(Spacing.m)
            .onTapGesture {
                if highlight != nil {
                    withAnimation {
                        highlight = nil
                        focus = nil
                    }
                }
            }
        }
        .padding(Spacing.s)
        .containerRelativeFrame(
            [.horizontal],
            count: 1,
            span: 1,
            spacing: 0
        ).task {
            grouped = Dictionary(
                grouping: book.items,
                by: { $0.day ?? Day(date: Date()) }
            )
        }
        .background(bg)
        .onChange(of: navigationState.insertItem.insert) {
            guard navigationState.insertItem.insert else { return }
            let (_, insertItem, _) = navigationState.insertItem
            if let i = insertItem {
                guard let day = DayStore.loadDay(by: Date()) else {
                    return
                }

                withAnimation {
                    i.timestamp = Calendar.current.startOfDay(for: Date())
                    i.day = day
                    i.unarchive()
                    book.items.append(i)
                }
                navigationState.insertItem = (false, nil, nil)
            }
        }
        .onChange(of: navigationState.addItem.add) {
            guard navigationState.addItem.add else { return }
            let (addItem, _) = navigationState.addItem
            if addItem {
                let item =
                    ItemStore.create(
                        timestamp: Date(),
                        book: book,
                        chapter: nil
                    )

                modelContext.insert(item)
                withAnimation {
                    book.items.append(item)
                }

                navigationState.addItem = (false, nil)
            }
        }
    }
}
