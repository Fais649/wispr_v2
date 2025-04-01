import SwiftData
import SwiftUI
import SwiftUIIntrospect

public extension View {
    func titleTextStyle() -> some View {
        modifier(TitleTextStyle())
    }

    func subTitleTextStyle() -> some View {
        modifier(SubTitleTextStyle())
    }

    func titleFontStyle() -> some View {
        modifier(TitleFontStyle())
    }

    func subTitleFontStyle() -> some View {
        modifier(SubTitleFontStyle())
    }

    func parentItemFontStyle() -> some View {
        modifier(ParentItemFontStyle())
    }

    func childItemFontStyle() -> some View {
        modifier(ChildItemFontStyle())
    }

    func toolbarFontStyle() -> some View {
        modifier(ToolbarFontStyle())
    }

    func eventTimeFontStyle() -> some View {
        modifier(EventTimeFontStyle())
    }

    func buttonFontStyle() -> some View {
        modifier(ButtonFontStyle())
    }

    func decorationFontStyle() -> some View {
        modifier(DecorationFontStyle())
    }

    func toolbarButtonLabelStyler(
        padding: (x: CGFloat, y: CGFloat) = (x: Spacing.s, y: Spacing.s),
        shadowRadius: CGFloat = Spacing.xxs
    ) -> some View {
        modifier(ToolbarButtonLabelStyler(
            padding: padding,
            shadowRadius: shadowRadius
        ))
    }

    func limitInputLength(value: Binding<String>, length: Int) -> some View {
        modifier(TextFieldLimitModifer(value: value, length: length))
    }

    func hideSystemBackground() -> some View {
        modifier(HiddenSystemBackground())
    }

    func screenStyle() -> some View {
        modifier(ScreenStyle())
    }

    func baseShadowStyle() -> some View {
        modifier(BaseShadowStyle())
    }

    func titleShadowStyle() -> some View {
        modifier(TitleShadowStyle())
    }

    func baseTextStyle() -> some View {
        modifier(BaseTextStyle())
    }

    func lstRowStyle() -> some View {
        modifier(LstRowStyle())
    }

    func lstStyle() -> some View {
        modifier(LstStyle())
    }

    func parentItem(
    ) -> some View {
        modifier(ParentItemStyle())
    }

    func childItem(
    ) -> some View {
        modifier(ChildItemStyle())
    }

    func scrollTransition(
        _ edgeInset: CGFloat = 0,
        enabled: Bool = true
    ) -> some View {
        modifier(ScrollTransition(enabled: enabled, edgeInset: edgeInset))
    }

    func fade(_ from: UnitPoint, _ to: UnitPoint) -> some View {
        modifier(FadeModifier(from: from, to: to))
    }
}

struct FadeModifier: ViewModifier {
    var from: UnitPoint
    var to: UnitPoint
    func body(content: Content) -> some View {
        content
            .mask {
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(
                            color: .black,
                            location: 0
                        ),
                        .init(
                            color: .clear,
                            location: 1
                        ),
                    ]),
                    startPoint: from,
                    endPoint: to
                )
            }
    }
}

private struct TitleTextStyle: ViewModifier {
    func body(content: Content) -> some View {
        content.titleFontStyle()
    }
}

struct SubTitleTextStyle: ViewModifier {
    @Environment(ThemeStateService.self) private var theme: ThemeStateService

    func body(content: Content) -> some View {
        content.subTitleFontStyle()
    }
}

struct SubTitleFontStyle: ViewModifier {
    @Environment(ThemeStateService.self) private var theme: ThemeStateService

    func body(content: Content) -> some View {
        content
            .environment(\.font, theme.activeTheme.h3.weight(.light))
    }
}

struct TitleFontStyle: ViewModifier {
    @Environment(ThemeStateService.self) private var theme: ThemeStateService

    func body(content: Content) -> some View {
        content.environment(\.font, theme.activeTheme.h3.weight(.semibold))
    }
}

struct ParentItemFontStyle: ViewModifier {
    @Environment(ThemeStateService.self) private var theme: ThemeStateService

    func body(content: Content) -> some View {
        content.environment(\.font, theme.activeTheme.h4.weight(.regular))
    }
}

struct ChildItemFontStyle: ViewModifier {
    @Environment(ThemeStateService.self) private var theme: ThemeStateService

    func body(content: Content) -> some View {
        content.environment(\.font, theme.activeTheme.h4.weight(.light))
    }
}

struct ToolbarFontStyle: ViewModifier {
    @Environment(ThemeStateService.self) private var theme: ThemeStateService

    func body(content: Content) -> some View {
        content.environment(\.font, theme.activeTheme.h4.weight(.regular))
    }
}

struct EventTimeFontStyle: ViewModifier {
    @Environment(ThemeStateService.self) private var theme: ThemeStateService
    func body(content: Content) -> some View {
        content.environment(\.font, theme.activeTheme.h4.weight(.thin))
    }
}

struct ButtonFontStyle: ViewModifier {
    @Environment(ThemeStateService.self) private var theme: ThemeStateService
    func body(content: Content) -> some View {
        content.environment(\.font, theme.activeTheme.h4.weight(.thin))
    }
}

struct DecorationFontStyle: ViewModifier {
    @Environment(ThemeStateService.self) private var theme: ThemeStateService
    func body(content: Content) -> some View {
        content.environment(\.font, theme.activeTheme.h6.weight(.bold))
    }
}

private struct ToolbarButtonLabelStyler: ViewModifier {
    var padding: (x: CGFloat, y: CGFloat) = (x: Spacing.s, y: Spacing.s)
    var shadowRadius: CGFloat = Spacing.xxs

    func body(content: Content) -> some View {
        content
            .contentShape(Rectangle())
            .toolbarFontStyle()
            .foregroundStyle(.white)
            .shadow(color: .white, radius: shadowRadius)
            .padding(.horizontal, padding.x)
            .padding(.vertical, padding.y)
            .blendMode(.hardLight)
    }
}

private struct TextFieldLimitModifer: ViewModifier {
    @Binding var value: String
    var length: Int

    func body(content: Content) -> some View {
        content
            .onReceive(value.publisher.collect()) {
                self.value = String($0.prefix(self.length))
            }
    }
}

private struct HiddenSystemBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .introspect(
                .navigationStack,
                on: .iOS(.v18),
                scope: .ancestor
            ) { something in
                let allsubviews = something.view.allSubViews
                for view in allsubviews {
                    if
                        view.backgroundColor == .systemBackground,
                        view.debugDescription
                            .contains("NavigationStackHostingController")
                    {
                        view.backgroundColor = nil
                    }
                }
            }
    }
}

private struct RowStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
    }
}

private struct ScreenStyle: ViewModifier {
    @Environment(
        NavigationStateService
            .self
    ) private var navigationStateService: NavigationStateService
    @Environment(ThemeStateService.self) private var theme: ThemeStateService

    func body(content: Content) -> some View {
        VStack {
            content
        }
        .safeAreaPadding(.top, Padding.screenTop)
        .safeAreaPadding(.bottom, Padding.screenBottom)
        .safeAreaPadding(.leading, Padding.screenLeading)
        .safeAreaPadding(.trailing, Padding.screenTrailing)
    }
}

private struct ParentItemStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .parentItemFontStyle()
            .baseTextStyle()
    }
}

private struct ChildItemStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .childItemFontStyle()
            .baseTextStyle()
    }
}

struct BaseTextStyle: ViewModifier {
    func body(content: Content) -> some View {
        content.foregroundStyle(.white)
    }
}

struct TitleShadowStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .shadow(color: .white.opacity(0.6), radius: Spacing.xxs)
    }
}

struct BaseShadowStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .shadow(color: .white.opacity(0.4), radius: Spacing.xxxs)
    }
}

struct LstStyle: ViewModifier {
    @Environment(
        ThemeStateService
            .self
    ) private var themeService: ThemeStateService
    func body(content: Content) -> some View {
        content
            .listStyle(.plain)
            .defaultScrollAnchor(.top)
            .scrollContentBackground(.hidden)
            .scrollIndicators(.hidden)
    }
}

struct LstRowStyle: ViewModifier {
    @Environment(
        ThemeStateService
            .self
    ) private var themeService: ThemeStateService
    func body(content: Content) -> some View {
        content
            .listRowBackground(Color.clear)
            .listRowSpacing(Spacing.none)
            .contentShape(Rectangle())
            .listRowSeparator(themeService.activeTheme.listRowSeparator)
            .listRowInsets(.init(
                top: Spacing.m,
                leading: 0,
                bottom: Spacing.m,
                trailing: 0
            ))
    }
}

private struct ScrollTransition: ViewModifier {
    var enabled: Bool = true
    var edgeInset: CGFloat = 0

    func body(content: Content) -> some View {
        if enabled {
            content
                .scrollTransition(
                    .interactive
                        .threshold(.visible.inset(by: edgeInset * 1.6))
                ) { content, phase in
                    content.opacity(phase.isIdentity ? 1 : 0)
                        .blur(radius: phase.isIdentity ? 0 : 40)
                        .scaleEffect(
                            x: 1,
                            y: phase.isIdentity ? 1 : 0,
                            anchor:
                            phase.value > 0 ? .top : .bottom
                        )
                }
        } else {
            content
        }
    }
}
