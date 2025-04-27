import SwiftData
import SwiftUI

struct BookScreen: View {
    @Environment(\.modelContext) private var modelContext: ModelContext
    @Environment(Globals.self) private var globals: Globals
    @Environment(ThemeStateService.self) private var theme: ThemeStateService
    @Environment(DayStateService.self) private var dayState: DayStateService
    @Environment(BookStateService.self) private var bookState: BookStateService
    @Environment(
        NavigationStateService
            .self
    ) private var navigationStateService: NavigationStateService

    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    @Query var days: [Day]

    var filteredDays: [Day] {
        days.filter { day in
            let d = day.items.filter {
                $0.parent == nil && !$0.archived && $0
                    .text
                    .isNotEmpty && $0.book == book
            }

            if let chapter {
                return d
                    .contains { $0.chapter == chapter }
            }

            return d.isNotEmpty
        }
        .sorted(by: { $0.date < $1.date })
    }

    var todayDate: Date {
        Calendar.current.startOfDay(for: Date())
    }

    var animation: Namespace.ID
    var proxy: ScrollViewProxy

    @State var active: Date? = Calendar.current.startOfDay(for: Date())
    @Binding var selectedDate: Date
    @State var showDateShelf: Bool = false
    @State var showBookShelf: Bool = false

    let today = Calendar.current.startOfDay(for: Date())

    var onForm: Bool {
        navigationStateService.pathState.onForm
    }

    var onBookForm: Bool {
        navigationStateService.pathState.onBookForm
    }

    var bookShelfShown: Bool {
        navigationStateService.shelfState.isBook()
    }

    var isToday: Bool {
        selectedDate == todayDate
    }

    var book: Book
    var chapter: Chapter?

    @State var margin: Bool = true
    @State var hasScrolled: Bool = false
    @State var loaded: Bool = false
    @State var scrollDisabled: Bool = false

    func title() -> some View {
        Text(book.name)
    }

    var body: some View {
        Screen(.dayScreen, loaded: true, title: title, backgroundOpacity: 0.5) {
            ScrollView {
                LazyVStack {
                    ForEach(book.chapters) { chapter in
                        ChapterScreen(
                            animation: animation,
                            name: chapter.name,
                            items: chapter.items
                        )
                    }

                    ChapterScreen(
                        animation: animation,
                        name: "Other",
                        items: book.otherItems
                    )
                }
                .scrollTargetLayout()
            }
        }.contentMargins(.horizontal, 10)
    }
}
