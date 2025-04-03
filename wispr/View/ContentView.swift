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
    @State var calendarSyncService: CalendarSyncService = CalendarSyncService()
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
            }
        }
        .overlay(alignment: .bottom) {
            Toolbar()
        }
        .background(GlobalBackground())
        .scrollIndicators(.hidden)
        .scrollContentBackground(.hidden)
        .environment(navigationStateService)
        .environment(navigationStateService.bookState)
        .environment(navigationStateService.shelfState)
        .environment(flashService)
        .environment(calendarSyncService)
        .task {
            await calendarSyncService.sync()
        }
    }
}

struct GlobalBackground: View {
    @Environment(ThemeStateService.self) private var theme: ThemeStateService
    @Environment(BookStateService.self) private var activeBook: BookStateService

    @State var topRight: CGFloat = .random(in: 0 ... 1)
    @State var topLeft: CGFloat = .random(in: 0 ... 1)
    @State var top: CGFloat = .random(in: 0 ... 1)

    @State var centerRight: CGFloat = .random(in: 0 ... 1)
    @State var centerLeft: CGFloat = .random(in: 0 ... 1)
    @State var center: CGFloat = .random(in: 0 ... 1)

    @State var bottomRight: CGFloat = .random(in: 0 ... 1)
    @State var bottomLeft: CGFloat = .random(in: 0 ... 1)

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
                        .opacity(topRight),
                    theme.activeTheme.defaultBackgroundColor
                        .opacity(topLeft),
                    theme.activeTheme.defaultBackgroundColor
                        .opacity(top),
                    theme.activeTheme.defaultBackgroundColor
                        .opacity(center),
                    theme.activeTheme.defaultBackgroundColor
                        .opacity(centerLeft),
                    theme.activeTheme.defaultBackgroundColor,
                    theme.activeTheme.defaultBackgroundColor
                        .opacity(centerRight),
                    theme.activeTheme.defaultBackgroundColor
                        .opacity(bottomLeft),
                    theme.activeTheme.defaultBackgroundColor
                        .opacity(bottomRight),
                ])
                .blur(radius: 30)
            }
        }
        .overlay(theme.activeTheme.backgroundMaterialOverlay)
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}
