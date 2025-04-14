//
//  Disclosure.swift
//  wispr
//
//  Created by Faisal Alalaiwat on 21.03.25.
//

import Reorderable
import SwiftData
import SwiftUI

@MainActor
struct Disclosure<
    Label: View,
    Item: Listable,
    ItemView: View
>: View {
    init(
        animation: Namespace.ID,
        wasExpanded: Bool = false,
        expandable: Bool = true,
        isExpanded: Bool = false,
        childMoving: Bool = false,
        reversed: Bool = false,
        item: Item,
        onMoveChild: ((Item, IndexSet, Int) -> Void)? = nil,
        onDelete: ((Item) -> Void)? = nil,
        onDeleteChild: ((Item.Child) -> Void)? = nil,
        itemRow: @escaping (Item) -> Label,
        childRow: @escaping (Item.Child) -> ItemView
    ) {
        self.animation = animation
        self.wasExpanded = wasExpanded
        expandble = expandable
        self.isExpanded = isExpanded
        self.childMoving = childMoving
        self.reversed = reversed
        self.item = item
        self.onMoveChild = onMoveChild
        self.onDelete = onDelete
        self.onDeleteChild = onDeleteChild
        self.itemRow = itemRow
        self.childRow = childRow
    }

    @Environment(\.modelContext) private var modelContext: ModelContext
    @Environment(\.editMode) var editMode
    var animation: Namespace.ID
    @State var wasExpanded = false
    var expandble: Bool = true
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

    @State private var lastMoveFrom: Int?
    @State private var lastMoveTo: Int?

    var _expandable: Bool {
        expandble && children.isNotEmpty
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
    }

    @ViewBuilder
    func reverse() -> some View {
        VStack(alignment: .trailing) {
            itemRow(item)
        }

        if _expandable {
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

    var bgRect: some Shape {
        UnevenRoundedRectangle(cornerRadii: .init(
            topLeading: 4,
            bottomLeading: isExpanded || !_expandable ? 0 : 4,
            bottomTrailing: !_expandable ? 4 : isExpanded ? 2 : 30,
            topTrailing: 4
        ))
    }

    var bg: some View {
        bgRect
            .fill(.ultraThinMaterial)
            .overlay(
                bgRect
                    .fill(item.shadowTint)
                    .opacity(0.4)
                    .overlay {
                        HStack {
                            bgRect
                                .stroke(item.shadowTint.opacity(0.3))
                        }
                        .padding(Spacing.xs)
                        .blur(radius: 5)
                    }
            )
    }

    func childBg(isLast: Bool) -> some View {
        Rectangle()
            .fill(.ultraThinMaterial)
            .overlay(
                Rectangle()
                    .fill(item.shadowTint)
                    .opacity(0.3)
            )
            .ignoresSafeArea()
            .clipShape(
                UnevenRoundedRectangle(cornerRadii: .init(
                    topLeading: 0,
                    bottomLeading: isLast ? 2 : 0,
                    bottomTrailing: isLast ? 2 : 0,
                    topTrailing: 0
                ))
            )
    }

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                HStack {
                    if reversed {
                        reverse()
                        RoundedRectangle(cornerRadius: 1).fill(
                            item.shadowTint
                        )
                        .frame(width: 2)
                        .opacity(0.4)
                    } else {
                        regular()
                    }
                    Spacer()
                }
                .contentShape(Rectangle())

                Spacer().frame(width: Spacing.xl)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                if _expandable {
                    withAnimation {
                        isExpanded.toggle()
                    }
                }
            }

            if _expandable, isExpanded {
                ForEach(children) { item in
                    HStack {
                        if !reversed {
                            Spacer().frame(width: Spacing.l)
                        }

                        if isEditing, let onDeleteChild {
                            AniButton {
                                onDeleteChild(item)
                            } label: {
                                Image(systemName: "xmark")
                            }
                            .buttonStyle(.plain)
                        }
                        childRow(item)
                        Spacer()
                    }
                    .contentShape(Rectangle())
                }
            }
        }
        .frame(minHeight: Spacing.xl)
        .background(bg)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .contentShape(RoundedRectangle(cornerRadius: 10))
        .matchedTransitionSource(id: item.id, in: animation)
        .contextMenu {
            ForEach(item.menuItems) { menuItem in
                Button(menuItem.name, systemImage: menuItem.symbol) {
                    withAnimation {
                        menuItem.action()
                    }
                }
            }
        }
        .scrollTransition(.animated) { content, phase in
            content
                .opacity(phase.isIdentity ? 1 : 0)
                .scaleEffect(
                    phase.isIdentity || phase.value > 0 ? 1 : 0.8, anchor:
                    .bottom
                )
                .offset(
                    y:
                    phase.isIdentity || phase.value > 0 ? 0 : 20
                )
        }
    }
}

final class Debouncer {
    private var workItem: DispatchWorkItem?
    private let queue: DispatchQueue
    private let delay: TimeInterval

    init(delay: TimeInterval, queue: DispatchQueue = .main) {
        self.delay = delay
        self.queue = queue
    }

    func debounce(_ block: @escaping () -> Void) {
        workItem?.cancel()
        workItem = DispatchWorkItem(block: block)
        if let workItem = workItem {
            queue.asyncAfter(deadline: .now() + delay, execute: workItem)
        }
    }
}
