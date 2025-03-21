//
//  ContentView.swift
//  wispr
//
//  Created by Faisal Alalaiwat on 10.01.25.
//

import NavigationTransitions
import SwiftData
import SwiftUI

enum ScreenConstant {
    static let paddingTop: CGFloat = 50
    static let paddingBottom: CGFloat = 100
    static let paddingLeading: CGFloat = 60
    static let paddingTrailing: CGFloat = 60

    static let toolbarPaddingBottom: CGFloat = 30
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(ActiveTheme.self) private var activeTheme: ActiveTheme

    @State var nav: NavigatorService = .init()

    @Namespace var namespace

    var activePath: Path {
        nav.activePath
    }

    var body: some View {
        VStack {
            NavigationStack(path: $nav.path) {
                TimeLineScreen()
                    .screenStyler()
                    .navigationTransition(
                        .slide.combined(with: .fade(.in))
                            .combined(with: .fade(.out))
                    )
                    .navigationDestination(for: Path.self) { _ in
                        self.nav.destination
                    }
                    .toolbarBackground(.hidden)
            }
        }
        .sheet(isPresented: $nav.activeBoard.showBoard) {
            BoardSheet()
        }
        .overlay(alignment: .bottom) {
            Toolbar()
        }
        .background(GlobalBackground())
        .scrollIndicators(.hidden)
        .scrollContentBackground(.hidden)
        .environment(nav)
        .environment(nav.activeBoard)
    }

    struct GlobalBackground: View {
        @Environment(ActiveBoard.self) private var activeBoard: ActiveBoard

        var body: some View {
            VStack {
                if let board = activeBoard.board {
                    board.globalBackground
                        .scaleEffect(x: -1)
                } else {
                    MeshGradient(width: 3, height: 3, points: [
                        [0, 0], [0, 0.5], [0, 1],
                        [0.5, 0], [0.5, 0.5], [0.5, 1],
                        [1, 0], [1, 0.5], [1, 1],
                    ], colors: [
                        .gray.opacity(0.8),
                        .clear,
                        .clear,
                        .clear,
                        .clear,
                        .clear,
                        .clear,
                        .clear,
                        .gray.opacity(0.8),
                    ]).blur(radius: 80)
                }
            }.overlay(.ultraThinMaterial)
                .ignoresSafeArea()
                .allowsHitTesting(false)
        }
    }
}
