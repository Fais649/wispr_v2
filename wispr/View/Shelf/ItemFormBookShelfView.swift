
import SwiftData
import SwiftUI

struct ItemFormBookShelfView: View {
    @Environment(
        NavigationStateService
            .self
    ) private var navigationStateService: NavigationStateService
    @Environment(
        ThemeStateService
            .self
    ) private var theme: ThemeStateService
    @Environment(\.dismiss) var dismiss

    @Query var books: [Book]
    var animation: Namespace.ID
    @Binding var book: Book?
    @Binding var chapter: Chapter?

    @ViewBuilder
    func title() -> some View {
        if book != nil {
            ToolbarButton(padding: Spacing.none) {
                book = nil
                chapter = nil
                dismiss()
            } label: {
                Image(systemName: "xmark")
            }
        }
        Text("Books")
    }

    @ViewBuilder
    func trailingTitle() -> some View {
        AniButton {
            navigationStateService.goToBookForm()
        } label: {
            Image(systemName: "plus")
        }
    }

    @FocusState var focus: FocusedField?
    @State private var highlight: FocusedField?

    @State private var showBook: Bool = false
    var body: some View {
        Screen(
            .bookShelf,
            loaded: true,
            title: title,
            trailingTitle: trailingTitle
        ) {
            ScrollView {
                ForEach(books) { book in
                    NavigationLink(value: Path.bookForm(book: book)) {
                        InlineBook(
                            focus: $focus,
                            highlight: $highlight,
                            selectedBook: $book,
                            selectedChapter: $chapter,
                            book: book,
                            chapters: book.chapters
                        )
                    }.matchedTransitionSource(id: book.id, in: animation)
                }
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .shelfScreenStyle([.medium])
    }
}

struct InlineBook: View {
    @Environment(\.modelContext) private var modelContext
    @FocusState.Binding var focus: FocusedField?
    @Binding var highlight: FocusedField?
    @Namespace var animation
    @Binding var selectedBook: Book?
    @Binding var selectedChapter: Chapter?
    @Bindable var book: Book
    @State var chapters: [Chapter]

    func content() -> some View {
        VStack {
            HStack {
                Text(book.name)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                    .contentShape(Rectangle())
                Spacer()
            }
            .inlineItemButtonStyle()

            ForEach($chapters, id: \.id) { $chapter in
                HStack {
                    Text(chapter.name).fontWeight(.light)
                        .lineLimit(1)
                        .inlineSubItemButtonStyle()
                    Spacer()
                }
            }
            .inlineSubItemButtonStyle()
        }
        .contentShape(Rectangle())
        .foregroundStyle(.white)
    }

    @ViewBuilder
    func toolbar() -> some View {
        EmptyView()
    }

    var body: some View {
        content()
            .itemBoxStyle(book.colorTint)
    }
}
