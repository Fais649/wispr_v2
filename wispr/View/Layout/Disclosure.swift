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
    @Environment(\.editMode) var editMode
    var isEditing: Bool {
        if let editMode {
            return editMode.wrappedValue.isEditing
        }

        return false
    }

    var reversed: Bool = false
    let item: Item

    var children: [Item.Child] {
        item.children
    }

    var onMoveChild: ((Item, IndexSet, Int) -> Void)? = nil
    var onDelete: ((Item) -> Void)? = nil
    var onDeleteChild: ((Item.Child) -> Void)? = nil

    let itemRow: (Item) -> Label
    let childRow: (Item.Child) -> ItemView
    @State var isExpanded = true

    var expandable: Bool {
        children.isNotEmpty
    }

    @ViewBuilder
    func regular() -> some View {
        Group {
            if isEditing, let onDelete {
                AniButton {
                    onDelete(item)
                } label: {
                    Image(systemName: "xmark")
                }
                .buttonStyle(.plain)
            }

            if expandable {
                Image(systemName: "line.diagonal")
                    .buttonFontStyle()
                    .foregroundStyle(.white)
                    .rotationEffect(.degrees(isExpanded ? 90 : 0))
                    .background {
                        RadialGradient(
                            colors: [.clear, item.shadowTint],
                            center: .center,
                            startRadius: 5,
                            endRadius: 10
                        ).blur(radius: 10)
                    }
            } else {
                Image(systemName: "square.fill")
                    .scaleEffect(0.4)
                    .foregroundStyle(.white)
                    .buttonFontStyle()
                    .background {
                        RadialGradient(
                            colors: [.clear, item.shadowTint],
                            center: .center,
                            startRadius: 5,
                            endRadius: 10
                        ).blur(radius: 10)
                    }
            }
        }
        .padding(.leading, Spacing.m)

        VStack(alignment: .leading) {
            itemRow(item)
        }

        Spacer()
        Spacer().frame(width: Spacing.xl)
    }

    @ViewBuilder
    func reverse() -> some View {
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

    var body: some View {
        HStack {
            if reversed {
                reverse()
            } else {
                regular()
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

        // .background {
        //     RoundedRectangle(
        //         cornerRadius:
        //         10
        //     ).fill(item.shadowTint.gradient)
        //         .overlay(.ultraThinMaterial)
        //         .opacity(0.4)
        // }

        if expandable, isExpanded {
            ForEach(children) { item in
                HStack {
                    if isEditing, let onDeleteChild {
                        AniButton {
                            onDeleteChild(item)
                        } label: {
                            Image(systemName: "xmark")
                        }
                        .buttonStyle(.plain)
                    }
                    childRow(item)
                }
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
