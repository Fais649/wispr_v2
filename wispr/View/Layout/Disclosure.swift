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
    @Environment(\.modelContext) private var modelContext: ModelContext
    @Environment(\.editMode) var editMode
    var animation: Namespace.ID
    @State var wasExpanded = false
    @State var isExpanded = false
    @State var childMoving = false

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

    var bg: some View {
        UnevenRoundedRectangle(cornerRadii: .init(
            topLeading: 4,
            bottomLeading: isExpanded || !expandable ? 0 : 4,
            bottomTrailing: !expandable ? 4 : isExpanded ? 2 : 30,
            topTrailing: 4
        )).fill(
            expandable ? AnyShapeStyle(item.shadowTint) :
                AnyShapeStyle(item.shadowTint.gradient)
        )
        .opacity(0.2)
    }

    func childBg(isLast: Bool) -> some View {
        UnevenRoundedRectangle(cornerRadii: .init(
            topLeading: 0,
            bottomLeading: isLast ? 2 : 0,
            bottomTrailing: isLast ? 2 : 0,
            topTrailing: 0
        )).fill(item.shadowTint)
            .opacity(0.2)
            .ignoresSafeArea()
    }

    var body: some View {
        HStack {
            HStack {
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
            .background(bg)
            .matchedTransitionSource(id: item.id, in: animation)
        }
        .onDrag {
            withAnimation {
                wasExpanded = isExpanded
                isExpanded = false // collapse on drag start
            }
            return NSItemProvider(object: "lol" as NSString)
        }
        .contentShape(RoundedRectangle(cornerRadius: 10))
        .onTapGesture {
            if expandable {
                withAnimation {
                    isExpanded.toggle()
                }
            }
        }
        .padding(.top, Spacing.xs)

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
                .onDrag {
                    withAnimation {
                        childMoving = true // collapse on drag start
                    }
                    return NSItemProvider(object: "lol" as NSString)
                }
                .padding(
                    .leading,
                    reversed ? Spacing.none : Spacing.l
                )
                .listRowBackground(childBg(isLast: children.last == item))
                .padding(
                    .bottom,
                    item == children.last ? Spacing.xs : childMoving ?
                        Spacing.xs : Spacing.none
                )
            }
            .onMove(perform: { indexSet, newIndex in
                if let onMoveChild {
                    onMoveChild(
                        item,
                        indexSet,
                        newIndex
                    )
                }
                withAnimation {
                    childMoving = false
                }
            })
        }
    }
}

struct MyDisclosureStyle: DisclosureGroupStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack {
            Button {
                withAnimation {
                    configuration.isExpanded.toggle()
                }
            } label: {
                HStack(alignment: .firstTextBaseline) {
                    configuration.label
                    Spacer()
                    Text(configuration.isExpanded ? "hide" : "show")
                        .foregroundColor(.accentColor)
                        .font(.caption.lowercaseSmallCaps())
                        .animation(nil, value: configuration.isExpanded)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            if configuration.isExpanded {
                configuration.content
            }
        }
    }
}
