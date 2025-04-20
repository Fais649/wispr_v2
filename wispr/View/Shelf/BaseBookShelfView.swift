//
//  BaseBookShelfView.swift
//  wispr
//
//  Created by Faisal Alalaiwat on 21.03.25.
//

import SwiftData
import SwiftUI

struct BaseBookShelfView: View {
    @Environment(
        NavigationStateService
            .self
    ) private var navigationStateService: NavigationStateService
    @Environment(BookStateService.self) private var bookState: BookStateService
    @Environment(ThemeStateService.self) private var theme: ThemeStateService
    @Environment(\.dismiss) var dismiss
    @Query var books: [Book]
    @State var editBooks = false

    @ViewBuilder
    func title() -> some View {
        if bookState.book != nil {
            ToolbarButton(padding: Spacing.none) {
                withAnimation {
                    bookState.book = nil
                    bookState.chapter = nil

                    dismiss()
                }
            } label: {
                Image(systemName: "xmark")
            }
        }
        Text("Books")
    }

    @ViewBuilder
    func trailingTitle() -> some View {
        AniButton {
            editBooks.toggle()
        } label: {
            Image(
                systemName: self
                    .editBooks ? "checkmark" : "pencil"
            )
        }

        AniButton {
            navigationStateService.goToBookForm()
        } label: {
            Image(systemName: "plus")
        }
    }

    @Namespace var animation
    var body: some View {
        Screen(
            .bookShelf,
            loaded: true,
            title: title,
            trailingTitle: trailingTitle
        ) {
            ScrollView {
                VStack {
                    Disclosures(
                        animation: animation,
                        expandable: !editBooks,
                        items: books
                            .sorted(by: {
                                if
                                    let firstClick = $0.lastClicked,
                                    let secondClick = $1.lastClicked
                                {
                                    return firstClick > secondClick
                                } else {
                                    return $0.timestamp < $1.timestamp
                                }
                            }),
                        itemRow: { book in
                            Button {
                                if editBooks {
                                    withAnimation {
                                        navigationStateService
                                            .goToBookForm(book)
                                    }
                                } else {
                                    withAnimation {
                                        bookState.book = book
                                        dismiss()
                                    }
                                }

                                if
                                    navigationStateService
                                        .shelfState
                                        .isShown()
                                {
                                    navigationStateService
                                        .shelfState
                                        .dismissShelf()
                                }
                            } label: {
                                HStack {
                                    Text(book.name)
                                        .truncationMode(.tail)
                                        .lineLimit(1)
                                    Spacer()
                                }
                                .contentShape(Rectangle())
                            }
                            .parentItem()
                            .buttonStyle(.plain)
                            .contentShape(Rectangle())
                            .scrollTransition(.animated) { content, phase in
                                content
                                    .opacity(phase.isIdentity ? 1 : 0)
                                    .scaleEffect(
                                        phase.isIdentity || phase
                                            .value > 0 ? 1 : 0.9, anchor:
                                        .trailing
                                    )
                                    .blur(
                                        radius: phase.isIdentity || phase
                                            .value > 0 ? 0 : 5
                                    )
                            }
                        },
                        childRow: { child in
                            row(child)
                        }
                    )
                }
                .safeAreaPadding(.vertical, Spacing.m)
            }
        }
        .presentationDetents([.fraction(0.6)])
        .presentationCornerRadius(0)
        .presentationBackground {
            Rectangle().fill(
                theme.activeTheme
                    .backgroundMaterialOverlay
            )
            .fade(
                from: .bottom,
                fromOffset: 0.6,
                to: .top,
                toOffset: 1
            )
        }
        .padding(.horizontal, Spacing.m)
        .containerRelativeFrame([
            .horizontal,
            .vertical,
        ])
    }

    func row(_ child: Chapter) -> some View {
        Button {
            withAnimation {
                bookState.book = child.book
                bookState.chapter = child
                dismiss()
            }
        } label: {
            HStack {
                Text(child.name)
                    .truncationMode(.tail)
                    .lineLimit(1)
                Spacer()
            }
            .contentShape(Rectangle())
        }
        .parentItem()
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .scrollTransition(.animated) { content, phase in
            content
                .opacity(phase.isIdentity ? 1 : 0)
                .scaleEffect(
                    phase.isIdentity || phase
                        .value > 0 ? 1 : 0.9, anchor:
                    .trailing
                )
                .blur(
                    radius: phase.isIdentity || phase
                        .value > 0 ? 0 : 5
                )
        }
    }
}
