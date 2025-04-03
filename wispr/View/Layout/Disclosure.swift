//
//  Disclosure.swift
//  wispr
//
//  Created by Faisal Alalaiwat on 21.03.25.
//

import SwiftData
import SwiftUI

@MainActor
struct Disclosure<
    Label: View,
    Item: Listable,
    ItemView: View
>: View {
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

    var body: some View {
        HStack {
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

        if expandable, isExpanded {
            ForEach(children) { item in
                childRow(item)
                    .padding(.leading, Spacing.l + Spacing.m)
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
