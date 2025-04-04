//
//  Disclosure.swift
//  wispr
//
//  Created by Faisal Alalaiwat on 21.03.25.
//

import SwiftData
import SwiftUI

struct AllDay: Listable {
    var id: UUID = .init()
    typealias Child = Item

    var children: [Child] = []
}

@MainActor
struct Disclosure<
    Label: View,
    Item: Listable,
    ItemView: View
>: View {
    var reversed: Bool = false
    let item: Item

    var children: [Item.Child] {
        item.children
    }

    var onMoveChild: ((Item, IndexSet, Int) -> Void)? = nil

    let itemRow: (Item) -> Label
    let childRow: (Item.Child) -> ItemView
    @State var isExpanded = true

    var expandable: Bool {
        children.isNotEmpty
    }

    func regular() -> some View {
        HStack {
            if expandable {
                Image(systemName: "line.diagonal")
                    .buttonFontStyle()
                    .foregroundStyle(.white)
                    .rotationEffect(.degrees(isExpanded ? 90 : 0))
                    .shadow(color: item.shadowTint, radius: 5)
            } else {
                Image(systemName: "square.fill")
                    .scaleEffect(0.4)
                    .foregroundStyle(.white)
                    .buttonFontStyle()
                    .shadow(color: item.shadowTint, radius: 5)
            }

            VStack(alignment: .leading) {
                itemRow(item)
            }

            Spacer()
            Spacer().frame(width: Spacing.xl)
        }
        .padding(.leading, Spacing.m)
        .contentShape(Rectangle())
        .onTapGesture {
            if expandable {
                withAnimation {
                    isExpanded.toggle()
                }
            }
        }
    }

    func reverse() -> some View {
        HStack {
            VStack(alignment: .trailing) {
                itemRow(item)
            }

            if expandable {
                Image(systemName: "line.diagonal")
                    .buttonFontStyle()
                    .rotationEffect(.degrees(isExpanded ? 90 : 0))
            } else {
                Image(systemName: "dot.square")
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white, .clear)
                    .buttonFontStyle()
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if expandable {
                withAnimation {
                    isExpanded.toggle()
                }
            }
        }
    }

    var body: some View {
        if reversed {
            reverse()
        } else {
            regular()
        }

        if expandable, isExpanded {
            ForEach(children) { item in
                childRow(item)
                    .padding(
                        .leading,
                        reversed ? Spacing.none : Spacing.l + Spacing.m
                    )
            }.onMove(perform: { indexSet, newIndex in
                if let onMoveChild {
                    onMoveChild(
                        item,
                        indexSet,
                        newIndex
                    )
                }
            })
        }
    }
}
