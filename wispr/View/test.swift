//
//  test.swift
//  wispr
//
//  Created by Faisal Alalaiwat on 08.04.25.
//

import SwiftUI

struct ToggleLayoutView: View {
    @State private var isVertical = false

    var body: some View {
        // The ScrollView’s axis changes based on the current layout mode.
        ScrollView(isVertical ? .vertical : .horizontal) {
            // Our custom layout arranges children based on the isVertical flag.
            ToggleLayout(isVertical: isVertical) {
                ForEach(0 ..< 20) { index in
                    Text("Item \(index)")
                        .padding()
                        .background(Color.blue.opacity(0.3))
                        .cornerRadius(8)
                }
            }
            .padding()
        }
        // Tapping anywhere toggles the layout direction.
        .onTapGesture {
            withAnimation {
                isVertical.toggle()
            }
        }
    }
}

struct ToggleLayout: Layout {
    var isVertical: Bool

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache _: inout ()
    ) -> CGSize {
        if isVertical {
            // For a vertical layout, sum up intrinsic heights.
            let intrinsicHeights = subviews
                .map { $0.sizeThatFits(.unspecified).height }
            let totalHeight = intrinsicHeights.reduce(0, +)
            let maxWidth = subviews.map { $0.sizeThatFits(.unspecified).width }
                .max() ?? proposal.width ?? 300
            return CGSize(
                width: proposal.width ?? maxWidth,
                height: totalHeight
            )
        } else {
            // In horizontal mode, let children decide their intrinsic width,
            // but you can propose a height if needed—here we use .unspecified
            // so they only take as much vertical space as required.
            let intrinsicWidths = subviews.map {
                $0.sizeThatFits(.unspecified).width
            }
            let totalWidth = intrinsicWidths.reduce(0, +)
            let intrinsicHeight = subviews
                .map { $0.sizeThatFits(.unspecified).height }.max() ?? proposal
                .height ?? 300
            return CGSize(
                width: totalWidth,
                height: proposal.height ?? intrinsicHeight
            )
        }
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal _: ProposedViewSize,
        subviews: Subviews,
        cache _: inout ()
    ) {
        if isVertical {
            var yOffset = bounds.minY
            for subview in subviews {
                let subviewSize = CGSize(
                    width: bounds.width,
                    height:
                    550
                )
                let x = bounds.midX - subviewSize.width / 2
                subview.place(
                    at: CGPoint(x: x, y: yOffset),
                    proposal: ProposedViewSize(subviewSize)
                )
                yOffset += subviewSize.height
            }
        } else {
            var xOffset = bounds.minX
            for subview in subviews {
                let subviewSize = CGSize(
                    width: 550,
                    height:
                    bounds.height
                )
                let y = bounds.midY - subviewSize.height / 2
                subview.place(
                    at: CGPoint(x: xOffset, y: y),
                    proposal: ProposedViewSize(subviewSize)
                )
                xOffset += subviewSize.width
            }
        }
    }
}

#Preview {
    ToggleLayoutView()
}
