//
//  ActiveBook.swift
//  wispr
//
//  Created by Faisal Alalaiwat on 27.03.25.
//
import SwiftUI

@Observable
final class BookStateService {
    init(book: Book? = nil, showBook: Bool = false) {
        self.book = book
        self.showBook = showBook
    }

    var book: Book?
    var chapter: Chapter?
    var showBook = false

    func dismissBook() {
        book = nil
        chapter = nil
    }

    func dismissChapter() {
        chapter = nil
    }

    @MainActor
    func setBook(from chapter: Chapter) async {
        guard let book = BookStore.loadBook(by: chapter) else {
            return
        }

        self.book = book
        self.chapter = chapter
    }
}
