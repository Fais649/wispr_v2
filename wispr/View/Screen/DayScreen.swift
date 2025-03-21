//
//  DayScreen.swift
//  wispr
//
//  Created by Faisal Alalaiwat on 21.03.25.
//
import SwiftData
import SwiftUI

@Observable
class DayScreenReader {
    var minY: CGFloat = 0
    var maxY: CGFloat = 0
    var minX: CGFloat = 0
    var maxX: CGFloat = 0

    func populate(_ geo: GeometryProxy) {
        minY = geo.frame(in: .global).minY
        maxY = geo.frame(in: .global).maxY
        minX = geo.frame(in: .global).minX
        maxX = geo.frame(in: .global).maxX
    }
}

struct DayScreen: View {
    @Environment(\.modelContext) private var modelContext: ModelContext
    @Environment(NavigatorService.self) private var nav: NavigatorService
    @Environment(
        DayScreenReader
            .self
    ) private var dayScreenReader: DayScreenReader
    @Environment(\.dismiss) private var dismiss

    @Query var items: [Item]

    var boardFilter: Board?

    @State var filteredItems: [Item] = []

    init(activeDate: Date, boardFilter: Board?) {
        self.boardFilter = boardFilter
        _items = Query(
            filter: ItemStore.activeItemsPredicated(for: activeDate),
            sort: \.position
        )
    }

    @State private var loaded = false

    @ViewBuilder
    func sectionHeader() -> some View {
        HStack {
            Image(systemName: "asterisk").font(.system(size: 16))
                .foregroundStyle(.white).shadow(color: .white, radius: 2)

            Text(self.nav.activeDate.formatted(
                date: .abbreviated,
                time: .omitted
            ))
            .font(.system(size: 16))
            .foregroundStyle(.white)
            .shadow(color: .white, radius: 2)

            Spacer()

            Text(self.nav.activeDate.formatted(.dateTime.weekday()))
                .font(.system(size: 16))
                .foregroundStyle(.white)
                .shadow(color: .white, radius: 2)
        }
        .padding(.vertical, 30)
    }

    var body: some View {
        VStack {
            self.sectionHeader()
            if self.loaded {

                GeometryReader { geo in
                    List {
                        DGroups(
                            items: filteredItems,
                            animated: true,
                            withSwipe: true
                        )
                    }
                    .listStyle(.plain)
                    .safeAreaPadding(.top, 30)
                    .onAppear {
                        dayScreenReader.populate(geo)
                    }.onChange(of: geo.frame(in: .global).minY) {
                        dayScreenReader.populate(geo)
                    }
                }.overlay(alignment: .center) {

                if self.filteredItems.isEmpty {
                    Image(systemName: "plus.circle.dashed")
                        .fontWeight(.ultraLight)
                }
                    }
            } else {
                Spacer()
                ProgressView().progressViewStyle(.circular)
                    .task { await self.loadedFilteredItems() }
                Spacer()
            }
        }
        .onChange(of: nav.activeBoard.board) {
            Task {
                await self.loadedFilteredItems()
            }
        }
        .onChange(of: nav.activeDate) {
            Task {
                await self.loadedFilteredItems()
            }
        }
        .onChange(of: items) {
            Task {
                await self.loadedFilteredItems()
            }
        }
        .hideSystemBackground()
    }

    func loadedFilteredItems() async {
        withAnimation {
            self.loaded = false
        }
        await filterItems()
        withAnimation {
            self.loaded = true
        }
    }

    func filterItems() async {
        filteredItems = ItemStore.filterByBoard(
            items: items,
            board: boardFilter
        )
    }
}
