//
//  Disclosures.swift
//  wispr
//
//  Created by Faisal Alalaiwat on 25.03.25.
//
import SwiftUI

struct Disclosures<
    Label: View,
    Item: Listable,
    ItemView: View
>: View {
    var animation: Namespace.ID
    var defaultExpanded: Bool = false
    let items: [Item]
    var onMove: ((IndexSet, Int) -> Void)? = nil
    var onDelete: ((Item) -> Void)? = nil
    var onMoveChild: ((Item, IndexSet, Int) -> Void)? = nil
    var onDeleteChild: ((Item.Child) -> Void)? = nil
    let itemRow: (Item) -> Label
    let childRow: (Item.Child) -> ItemView

    var body: some View {
        ForEach(items) { item in
            Disclosure(
                animation: animation,
                isExpanded: defaultExpanded,
                item: item,
                onMoveChild: onMoveChild,
                onDelete: onDelete,
                onDeleteChild: onDeleteChild,
                itemRow: itemRow,
                childRow: childRow
            ).id(item.id)
        }
        .onMove(perform: onMove)
    }
}
