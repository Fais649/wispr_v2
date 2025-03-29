//
//  ContentView.swift
//  wispr
//
//  Created by Faisal Alalaiwat on 10.01.25.
//
import NavigationTransitions
import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(ThemeStateService.self) private var theme: ThemeStateService

    @State var navigationStateService: NavigationStateService = .init()
    @State var flashService: FlashStateService = .init()
    @Namespace var namespace

    var activePath: Path {
        navigationStateService.activePath
    }

    @State var showShelf: Bool = false
    var body: some View {
        VStack {
            NavigationStack(path: $navigationStateService.pathState.path) {
                TimeLineScreen()
                    .navigationDestination(for: Path.self) { path in
                        navigationStateService.destination(path)
                    }
            }.overlay {
                flashService.flashMessage

                if showShelf {
                    Rectangle()
                        .fill(theme.activeTheme.backgroundMaterialOverlay)
                        .mask {
                            LinearGradient(
                                gradient: Gradient(stops: [
                                    .init(
                                        color: .black,
                                        location: 0
                                    ),
                                    .init(
                                        color: .black,
                                        location: 0.6
                                    ),
                                    .init(
                                        color: .clear,
                                        location: 1
                                    ),
                                ]),
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        }
                        .onTapGesture {
                            if showShelf {
                                withAnimation {
                                    navigationStateService.shelfState
                                        .dismissShelf()
                                }
                            }
                        }
                        .ignoresSafeArea()
                }
            }
        }
        .overlay(alignment: .bottom) {
            VStack {
                if showShelf {
                    navigationStateService.shelfState.display()
                }

                Toolbar()
                    .onChange(of: navigationStateService.shelfState.isShown()) {
                        withAnimation {
                            showShelf = navigationStateService.shelfState
                                .isShown()
                        }
                    }
            }
            .background {
                // if showShelf {
                //     Rectangle()
                //         .fill(.ultraThinMaterial)
                //         .frame(width: 500)
                //         .blur(radius: 5)
                //         .ignoresSafeArea()
                // }
            }
        }
        .background(GlobalBackground())
        .scrollIndicators(.hidden)
        .scrollContentBackground(.hidden)
        .environment(navigationStateService)
        .environment(navigationStateService.bookState)
        .environment(navigationStateService.shelfState)
        .environment(flashService)
    }
}

struct GlobalBackground: View {
    @Environment(ThemeStateService.self) private var theme: ThemeStateService
    @Environment(BookStateService.self) private var activeBook: BookStateService

    var body: some View {
        VStack {
            if let book = activeBook.book {
                book.globalBackground
            } else {
                MeshGradient(width: 3, height: 3, points: [
                    [0, 0], [0, 0.5], [0, 1],
                    [0.5, 0], [0.5, 0.5], [0.5, 1],
                    [1, 0], [1, 0.5], [1, 1],
                ], colors: [
                    theme.activeTheme.defaultBackgroundColor
                        .opacity(.random(in: 0 ... 1)),
                    theme.activeTheme.defaultBackgroundColor
                        .opacity(.random(in: 0 ... 1)),
                    theme.activeTheme.defaultBackgroundColor
                        .opacity(.random(in: 0 ... 1)),
                    theme.activeTheme.defaultBackgroundColor
                        .opacity(.random(in: 0 ... 1)),
                    theme.activeTheme.defaultBackgroundColor
                        .opacity(.random(in: 0 ... 1)),
                    theme.activeTheme.defaultBackgroundColor,
                    theme.activeTheme.defaultBackgroundColor
                        .opacity(.random(in: 0 ... 1)),
                    theme.activeTheme.defaultBackgroundColor
                        .opacity(.random(in: 0 ... 1)),
                    theme.activeTheme.defaultBackgroundColor
                        .opacity(.random(in: 0 ... 1)),
                ])
                .blur(radius: 30)
            }
        }
        .overlay(theme.activeTheme.backgroundMaterialOverlay)
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}
