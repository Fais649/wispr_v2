//
//  Toolbar.swift
//  wispr
//
//  Created by Faisal Alalaiwat on 21.03.25.
//

import SwiftData
import SwiftUI

struct Toolbar: View {
    @Environment(NavigatorService.self) private var nav: NavigatorService

    var body: some View {
        HStack {
            if !nav.onTimeline {
                ToolbarButton {
                    nav.goBack()
                } label: {
                    Image(
                        systemName: nav.onDayList ? "text.line.magnify" :
                            "chevron.left"
                    )
                }
            }
            if nav.onItemForm {
                Spacer()
            }

            ToolbarButton(
                clipShape: nav.activeBoard
                    .board == nil ? AnyShape(Circle()) : AnyShape(Capsule())
            ) {
                nav.activeBoard.showBoard = true
            } label: {
                LogoBoardButton()
            }

            nav.datePickerButton()

            if !nav.onForm {
                ToolbarButton {
                    nav.goToItemForm()
                } label: {
                    Image(systemName: "plus")
                }
            }

            if nav.onTimeline {
                ToolbarButton {
                    nav.goToDayScreen()
                } label: {
                    Image(systemName: "chevron.right")
                }
            }
        }
        .padding()
        .background {
            Color.clear
        }
    }
}

struct ToolbarLogo: View {
    @Environment(ActiveBoard.self) private var activeBoard: ActiveBoard

    var board: Board? {
        activeBoard.board
    }

    var body: some View {
        ToolbarButton(clipShape: Capsule()) {
            self.activeBoard.showBoard = true
        } label: {
            LogoBoardButton()
        }
    }
}

struct LogoBoardButton: View {
    @Environment(ActiveBoard.self) private var activeBoard: ActiveBoard

    var board: Board? {
        activeBoard.board
    }

    var body: some View {
        HStack(spacing: 12) {
            Image("Logo")
                .resizable()
                .scaledToFit()
                .frame(width: 14, height: 14)
                .padding(2)

            if let board {
                Text(board.name)
            }
        }
    }
}
