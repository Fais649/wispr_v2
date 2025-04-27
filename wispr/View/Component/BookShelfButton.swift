import SwiftUI

struct BookShelfButton<Shelf: View>: View {
    @State private var showBookShelf: Bool = false
    @Binding var book: Book?
    @Binding var chapter: Chapter?

    var shelf: (() -> Shelf)? = nil

    func dismissBook() {
        dismissChapter()
        book = nil
    }

    func dismissChapter() {
        chapter = nil
    }

    var body: some View {
        ToolbarButton {
            showBookShelf.toggle()
        } label: {
            Image(systemName: "asterisk.circle.fill")
        }
        .sheet(isPresented: $showBookShelf) {
            if let shelf {
                shelf()
            }
        }
    }
}
