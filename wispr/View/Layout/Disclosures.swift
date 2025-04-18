//
//  Disclosures.swift
//  wispr
//
//  Created by Faisal Alalaiwat on 25.03.25.
//
import Reorderable
import SwiftUI

struct Disclosures<
    Label: View,
    Item: Listable,
    ItemView: View
>: View {
    var animation: Namespace.ID
    var expandable: Bool = true
    var defaultExpanded: Bool = false
    let items: [Item]
    var prefix: Int? = nil
    var onMove: ((IndexSet, Int) -> Void)? = nil
    var onDelete: ((Item) -> Void)? = nil
    var onMoveChild: ((Item, IndexSet, Int) -> Void)? = nil
    var onDeleteChild: ((Item.Child) -> Void)? = nil
    let itemRow: (Item) -> Label
    let childRow: (Item.Child) -> ItemView

    var prefixedItems: ArraySlice<Item> {
        if let prefix {
            return items.prefix(prefix)
        }
        return ArraySlice(items)
    }

    var body: some View {
        ForEach(prefixedItems) { item in
            Disclosure(
                animation: animation,
                expandable: expandable,
                isExpanded: defaultExpanded,
                item: item,
                onMoveChild: onMoveChild,
                onDelete: onDelete,
                onDeleteChild: onDeleteChild,
                itemRow: itemRow,
                childRow: childRow
            )
            .id(item.id)
        }
    }
}
