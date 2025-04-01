import SwiftUI

struct ToolbarButton<Content: View, S: Shape>: View {
    @Environment(ThemeStateService.self) private var theme
    var toggledOn: Bool? = nil
    var background: Bool = true
    var padding: CGFloat
    var clipShape: S

    let action: (() -> Void)?
    @ViewBuilder var label: () -> Content

    init(
        padding: CGFloat = Spacing.s,
        toggledOn: Bool? = nil,
        background: Bool = true,
        clipShape: S = Circle(),
        action: (() -> Void)? = nil,
        @ViewBuilder label: @escaping () -> Content
    ) {
        self.padding = padding
        self.toggledOn = toggledOn
        self.background = background
        self.clipShape = clipShape
        self.action = action
        self.label = label
    }

    var t: Bool {
        if let toggledOn {
            return toggledOn
        }
        return false
    }

    @ViewBuilder
    var l: some View {
        if clipShape as? Circle != nil {
            label()
                .toolbarButtonLabelStyler()
        } else {
            label()
                .toolbarButtonLabelStyler(padding: (x: 6, y: 6))
        }
    }
    
    @ViewBuilder
    var b: some View {
        if let action {
            AniButton(padding: padding) {
                action()
            } label: {
                l
            }
        } else {
            l
        }
    }
    
    var body: some View {
        b
            .background {
                clipShape
                    .fill(
                        background
                        ? AnyShapeStyle(theme.activeTheme.backgroundMaterialOverlay)
                        : AnyShapeStyle(Color.clear)
                    )
                    .blur(radius: t ? 50 : 0)
                    .blendMode(.luminosity)
            }
            .animation(.smooth, value: t)
    }
}
