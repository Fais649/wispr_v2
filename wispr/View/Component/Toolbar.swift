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

            BaseBookShelfLabelView()
            BaseDateShelfLabelView()

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
        .frame(height: Spacing.l)
        .padding(Spacing.s)
        .background {
            Color.clear
        }
        .safeAreaPadding(.bottom, Spacing.m)
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
                .contentShape(Rectangle())
                .frame(width: 16, height: 16)
                .foregroundStyle(.white)
                .blendMode(.hardLight)

            if let book {
                VStack(alignment: .leading) {
                    Text(book.name)
                        .fontWeight(.regular)
                    if let chapter = activeBook.chapter {
                        Text(chapter.name)
                            .fontWeight(.ultraLight)
                    }
                }.decorationFontStyle()
            }
        }
    }
}
