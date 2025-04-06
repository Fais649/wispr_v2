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
    @State var isExpanded = false
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
        }

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
        HStack(spacing: -Spacing.s) {
            if reversed {
                reverse()
                item.shadowTint
                    .frame(width: 2)
                    .clipShape(
                        RoundedRectangle(cornerRadius: 1)
                    )
                    .opacity(0.4)
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
        .background {
            UnevenRoundedRectangle(cornerRadii: .init(
                topLeading: 4,
                bottomLeading: isExpanded ? 0 : 4,
                bottomTrailing: !expandable ? 4 : isExpanded ? 20 : 30,
                topTrailing: 4
            )).fill(
                expandable ? AnyShapeStyle(item.shadowTint) :
                    AnyShapeStyle(item.shadowTint.gradient)
            )
            .overlay(alignment: .bottomTrailing) {
                if expandable {
                    Circle().fill(item.shadowTint).frame(width: Spacing.xs)
                        .padding(isExpanded ? .top : .vertical, Spacing.xs)
                        .offset(y: isExpanded ? Spacing.xxs : 0)
                }
            }
            .opacity(0.2)
            .padding(isExpanded ? .top : .vertical, Spacing.xs)
        }

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
                    reversed ? Spacing.none : Spacing.l
                )
                .background {
                    UnevenRoundedRectangle(cornerRadii: .init(
                        topLeading: 0,
                        bottomLeading: item == children.last ? 2 : 0,
                        bottomTrailing: item == children.last ? 2 : 0,
                        topTrailing: item == children.first ? 20 : 0
                    )).fill(self.item.shadowTint)
                        .opacity(0.2)
                }
                .padding(
                    .bottom,
                    item == children.last ? Spacing.xs : Spacing.none
                )
                .mask {
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(
                                color: .black,
                                location: 0.7
                            ),
                            .init(
                                color: item == children.last ? .clear :
                                    .black,
                                location: 1
                            ),
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }

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
