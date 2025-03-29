import SwiftUI

struct ToolbarButton<Content: View, S: Shape>: View {
    @Environment(ThemeStateService.self) private var theme
    var toggledOn: Bool? = nil
    var padding: CGFloat
    var clipShape: S

    let action: (() -> Void)?
    @ViewBuilder var label: () -> Content

    init(
        padding: CGFloat = Spacing.s,
        toggledOn: Bool? = nil,
        clipShape: S = Circle(),
        action: (() -> Void)? = nil,
        @ViewBuilder label: @escaping () -> Content
    ) {
        self.padding = padding
        self.toggledOn = toggledOn
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

    var body: some View {
        AniButton(padding: padding) {
            if let action {
                action()
            }
        } label: {
            if clipShape as? Circle != nil {
                label()
                    .toolbarButtonLabelStyler()
            } else {
                label()
                    .toolbarButtonLabelStyler(padding: (x: 6, y: 6))
            }
        }
        .background {
            clipShape.fill(theme.activeTheme.backgroundMaterialOverlay)
                .blur(radius: t ? 50 : 0)
                .blendMode(.luminosity)
        }
        .animation(.smooth, value: t)
    }
}
