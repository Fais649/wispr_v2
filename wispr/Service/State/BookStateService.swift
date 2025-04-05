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
    var chapter: Tag?
    var showBook = false

    func dismissBook() {
        book = nil
        chapter = nil
    }

    func setBook(from chapters: [Tag]) async {
        guard let chapter = chapters.first else {
            return
        }

        guard let book = await BookStore.loadBook(by: chapter) else {
            return
        }

        self.book = book
        self.chapter = chapter
    }
}
