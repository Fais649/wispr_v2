//
//  Toolbar.swift
//  wispr
//
//  Created by Faisal Alalaiwat on 21.03.25.
//

import SwiftData
import SwiftUI

struct Toolbar: View {
    @Environment(
        NavigationStateService
            .self
    ) private var navigationStateService: NavigationStateService

    var body: some View {
        HStack {
            if !navigationStateService.onTimeline {
                ToolbarButton {
                    navigationStateService.goBack()
                } label: {
                    Image(
                        systemName: navigationStateService
                            .onDayScreen ? "text.line.magnify" :
                            "chevron.left"
                    )
                }
            }

            if navigationStateService.onItemForm {
                Spacer()
            }

            ToolbarButton(
                toggledOn: navigationStateService.shelfState.isBook(),
                clipShape: navigationStateService.shelfState.isBook()
                    ? AnyShape(Circle())
                    : AnyShape(Capsule())
            ) {
                navigationStateService.toggleBookShelf()
            } label: {
                LogoBookButton()
            }

            navigationStateService.datePickerButton()

            if !navigationStateService.onForm {
                ToolbarButton {
                    navigationStateService.goToItemForm()
                } label: {
                    Image(systemName: "plus")
                }
            }

            if navigationStateService.onTimeline {
                ToolbarButton {
                    navigationStateService.goToDayScreen()
                } label: {
                    Image(systemName: "chevron.right")
                }
            }
        }
        .padding(Spacing.s)
        .background {
            Color.clear
        }
    }
}

struct LogoBookButton: View {
    @Environment(BookStateService.self) private var activeBook: BookStateService

    var book: Book? {
        activeBook.book
    }

    var body: some View {
        HStack(spacing: Spacing.s) {
            Image("Logo")
                .resizable()
                .scaledToFit()
                .frame(width: 12, height: 12)
                .padding(Spacing.xxs)

            if let book {
                Text(book.name)
            }
        }
    }
}
