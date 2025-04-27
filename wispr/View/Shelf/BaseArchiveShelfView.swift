import SwiftData
import SwiftUI

struct ArchiveScreen: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(NavigationStateService.self) private var navigationState
    @Environment(ThemeStateService.self) private var theme: ThemeStateService

    @Query(
        filter: #Predicate<Item> { item in item.archived },
        sort: \Item.timestamp, order: .reverse
    ) var archivedItems: [Item]

    var animation: Namespace.ID

    var timestamp: Date
    var book: Book?
    var chapter: Chapter?

    var todayDate: Date {
        Calendar.current.roundToNearestHalfHour(Date())
    }

    func unarchive(_ item: Item) {
        Task { @MainActor in
            let day = await DayStore.loadOrCreate(by: timestamp)
            day.unarchive(item: item, book: book, chapter: chapter)

            dismiss()
        }
    }

    func title() -> some View {
        Text("Archive")
    }

    @FocusState var focus: FocusedField?
    @State private var highlight: FocusedField?

    var body: some View {
        Screen(
            .archiveShelf,
            title: title,
            backgroundOpacity: 0
        ) {
            ScrollView {
                ForEach(
                    archivedItems,
                    id: \.id
                ) { item in
                    InLineItem(
                        item: item,
                        focus: $focus,
                        highlight: $highlight
                    )
                    .highPriorityGesture(TapGesture().onEnded {
                        if navigationState.insertItem.insert {
                            navigationState.insertItem = (
                                insert: false,
                                item: nil,
                                date: nil
                            )
                        }

                        navigationState.insertItem = (
                            insert: true,
                            item: item,
                            date: timestamp
                        )

                    })
                }
            }
            .scrollBounceBehavior(.basedOnSize, axes: .vertical)
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .padding(.vertical, Spacing.m)
        }
    }
}

struct BaseArchiveShelfView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(NavigationStateService.self) private var navigationState
    @Environment(ThemeStateService.self) private var theme: ThemeStateService

    @Query(
        filter: #Predicate<Item> { item in item.archived },
        sort: \Item.timestamp, order: .reverse
    ) var archivedItems: [Item]

    var animation: Namespace.ID

    var timestamp: Date
    var book: Book?
    var chapter: Chapter?

    var todayDate: Date {
        Calendar.current.roundToNearestHalfHour(Date())
    }

    func title() -> some View {
        Text("Archive")
    }

    @FocusState var focus: FocusedField?
    @State private var highlight: FocusedField?

    var body: some View {
        Screen(
            .archiveShelf,
            title: title
        ) {
            ScrollView {
                ForEach(
                    archivedItems,
                    id: \.id
                ) { item in
                    InLineItem(
                        item: item,
                        focus: $focus,
                        highlight: $highlight
                    )
                    .highPriorityGesture(TapGesture().onEnded {
                        if navigationState.insertItem.insert {
                            navigationState.insertItem = (
                                insert: false,
                                item: nil,
                                date: nil
                            )
                        }

                        navigationState.insertItem = (
                            insert: true,
                            item: item,
                            date: timestamp
                        )

                    })
                }
            }
            .scrollBounceBehavior(.basedOnSize, axes: .vertical)
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .padding(.vertical, Spacing.m)
        }.shelfScreenStyle([.fraction(0.75)])
    }
}
