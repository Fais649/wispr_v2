import SwiftData
import SwiftUI
import SwiftUIIntrospect

public extension View {
    func titleFontStyle(_ t: TitleStyle = TitleStyle.regular) -> some View {
        modifier(TitleFontStyle(titleStyle: t))
    }

    func shelfScreenStyle(_ detents: Set<PresentationDetent>) -> some View {
        modifier(ShelfScreenStyle(detents: detents))
    }

    func subTitleFontStyle(_ t: TitleStyle = TitleStyle.regular) -> some View {
        modifier(SubTitleFontStyle(titleStyle: t))
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

    func onEnterKey(
        _ string: Binding<String>,
        action: @escaping () -> Void
    ) -> some View {
        modifier(OnEnterKey(string: string, action: action))
    }

    func itemBoxStyle(_ colorTint: Color) -> some View {
        modifier(ItemBoxStyle(colorTint: colorTint))
    }

    func inlineItemButtonStyle() -> some View {
        modifier(InlineItemButtonStyle())
    }

    func inlineSubItemButtonStyle() -> some View {
        modifier(InlineSubItemButtonStyle())
    }

    func toolbarButtonLabelStyler(
        padding: (x: CGFloat, y: CGFloat) = (x: Spacing.none, y: Spacing.none),
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

    func fade(
        from: UnitPoint,
        fromOffset: CGFloat = 0,
        to: UnitPoint,
        toOffset: CGFloat = 1
    ) -> some View {
        modifier(FadeModifier(
            from: from,
            fromOffset: fromOffset,
            to: to,
            toOffset: toOffset
        ))
    }
}

struct FadeModifier: ViewModifier {
    var from: UnitPoint
    var fromOffset: CGFloat
    var to: UnitPoint
    var toOffset: CGFloat

    func body(content: Content) -> some View {
        content
            .mask {
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(
                            color: .black,
                            location: fromOffset
                        ),
                        .init(
                            color: .clear,
                            location: toOffset
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
    var titleStyle: TitleStyle = .regular

    func body(content: Content) -> some View {
        switch titleStyle {
            case .small:
                content.environment(
                    \.font,
                    theme.activeTheme.h4.weight(.ultraLight)
                )
            default:
                content.environment(
                    \.font,
                    theme.activeTheme.h3.weight(.light)
                )
        }
    }
}

struct TitleFontStyle: ViewModifier {
    @Environment(ThemeStateService.self) private var theme: ThemeStateService
    var titleStyle: TitleStyle = .regular

    func body(content: Content) -> some View {
        switch titleStyle {
            case .small:
                content.environment(
                    \.font,
                    theme.activeTheme.h4.weight(.regular)
                )
            default:
                content.environment(
                    \.font,
                    theme.activeTheme.h3.weight(.semibold)
                )
        }
    }
}

struct ParentItemFontStyle: ViewModifier {
    @Environment(ThemeStateService.self) private var theme: ThemeStateService

    func body(content: Content) -> some View {
        content.environment(\.font, theme.activeTheme.h4.weight(.light))
    }
}

struct ShelfScreenStyle: ViewModifier {
    @Environment(ThemeStateService.self) private var theme: ThemeStateService

    @FocusState var focus: Bool
    var detents: Set<PresentationDetent>
    func body(content: Content) -> some View {
        content
            .focused($focus)
            .padding(.top, Spacing.m)
            .safeAreaPadding(.bottom, Spacing.l)
            .presentationDetents(detents)
            .presentationCornerRadius(0)
            .presentationBackground {
                Rectangle().fill(
                    theme.activeTheme
                        .backgroundMaterialOverlay
                )
                .fade(
                    from: .bottom,
                    fromOffset: 0.6,
                    to: .top,
                    toOffset: 1
                )
            }
            .padding(.horizontal, Spacing.m)
            .containerRelativeFrame([.horizontal, .vertical])
    }
}

struct ItemBoxStyle: ViewModifier {
    let colorTint: Color

    var bgRect: some Shape {
        RoundedRectangle(cornerRadius: 4)
    }

    var bg: some View {
        bgRect
            .fill(.ultraThinMaterial)
            .overlay(
                bgRect
                    .fill(colorTint.gradient)
                    .opacity(0.4)
            )
    }

    func body(content: Content) -> some View {
        content
            .contentShape(RoundedRectangle(cornerRadius: 4))
            .padding(Spacing.m)
            .background(bg)
    }
}

struct ChildItemFontStyle: ViewModifier {
    @Environment(ThemeStateService.self) private var theme: ThemeStateService

    func body(content: Content) -> some View {
        content.environment(\.font, theme.activeTheme.h4.weight(.ultraLight))
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
        content.environment(\.font, theme.activeTheme.h5.weight(.thin))
    }
}

struct ButtonFontStyle: ViewModifier {
    @Environment(ThemeStateService.self) private var theme: ThemeStateService
    func body(content: Content) -> some View {
        content.environment(\.font, theme.activeTheme.h3.weight(.regular))
    }
}

struct OnEnterKey: ViewModifier {
    @Binding var string: String
    var action: () -> Void

    func body(content: Content) -> some View {
        content.onChange(of: string) {
            guard string.contains("\n") else { return }
            string = string.replacing("\n", with: "")
            action()
        }
    }
}

struct InlineSubItemButtonStyle: ViewModifier {
    @Environment(ThemeStateService.self) private var theme: ThemeStateService
    func body(content: Content) -> some View {
        content.environment(\.font, theme.activeTheme.h4.weight(.light))
    }
}

struct InlineItemButtonStyle: ViewModifier {
    @Environment(ThemeStateService.self) private var theme: ThemeStateService
    func body(content: Content) -> some View {
        content.environment(\.font, theme.activeTheme.h3.weight(.light))
    }
}

struct DecorationFontStyle: ViewModifier {
    @Environment(ThemeStateService.self) private var theme: ThemeStateService
    func body(content: Content) -> some View {
        content.environment(\.font, theme.activeTheme.h6.weight(.bold))
    }
}

private struct ToolbarButtonLabelStyler: ViewModifier {
    var padding: (x: CGFloat, y: CGFloat) = (x: Spacing.none, y: Spacing.none)
    var shadowRadius: CGFloat = Spacing.xxs

    func body(content: Content) -> some View {
        content
            .contentShape(Rectangle())
            .toolbarFontStyle()
            .foregroundStyle(.white)
            .padding(.horizontal, padding.x)
            .padding(.vertical, padding.y)
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
        // .safeAreaPadding(.top, Padding.screenTop)
        // .safeAreaPadding(.bottom, Padding.screenBottom)
        // .safeAreaPadding(.leading, Padding.screenLeading)
        // .safeAreaPadding(.trailing, Padding.screenTrailing)
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
            .contentShape(RoundedRectangle(cornerRadius: 20))
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
                        .threshold(.visible.inset(by: edgeInset * 1))
                ) { content, phase in
                    content.opacity(phase.isIdentity ? 1 : 0)
                        .blur(radius: phase.isIdentity ? 0 : 20)
                    // .scaleEffect(
                    //     x: 1,
                    //     y: phase.isIdentity ? 1 : 0,
                    //     anchor:
                    //     phase.value > 0 ? .top : .bottom
                    // )
                }
        } else {
            content
        }
    }
}

private struct CursorToEndOnFocus: ViewModifier {
    private class CursorBehavior: UIView, UITextFieldDelegate {
        func textFieldDidBeginEditing(_ textField: UITextField) {
            let endPosition = textField.endOfDocument
            textField.selectedTextRange = textField.textRange(
                from: endPosition,
                to: endPosition
            )
        }
    }

    private var cursorBehavior = CursorBehavior()

    func body(content: Content) -> some View {
        content.introspect(
            .textField,
            on: .iOS(.v13, .v14, .v15, .v16, .v17, .v18)
        ) { textField in
            textField.delegate = cursorBehavior
        }
    }
}

extension View {
    func cursorToEndOnFocus() -> some View {
        modifier(CursorToEndOnFocus())
    }
}

private struct TextFieldSubmit: ViewModifier {
    // private class that conforms UITextFieldDelegate
    private class TextFieldKeyboardBehavior: UIView, UITextFieldDelegate {
        var submitAction: (() -> Void)?

        func textFieldShouldReturn(_: UITextField) -> Bool {
            submitAction?() // called when keyboard return button is pressed
            return false // cancel default behavior of return button
        }
    }

    // instance to UITextFieldDelegate
    private var textFieldKeyboardBehavior = TextFieldKeyboardBehavior()

    init(submitAction: @escaping () -> Void) {
        textFieldKeyboardBehavior.submitAction = submitAction
    }

    func body(content: Content) -> some View {
        content.introspect(
            .textField,
            on: .iOS(.v13, .v14, .v15, .v16, .v17, .v18)
        ) { textField in
            // UITextField reached with Introspect
            textField.delegate = textFieldKeyboardBehavior
        }
    }
}

// make the modifier publicly available for use with TextField.
extension TextField {
    func customSubmit(submitAction: @escaping (() -> Void)) -> some View {
        modifier(TextFieldSubmit(submitAction: submitAction))
    }
}

// make the modifier publicly available for use with SecureField.
extension SecureField {
    func customSubmit(submitAction: @escaping (() -> Void)) -> some View {
        modifier(TextFieldSubmit(submitAction: submitAction))
    }
}
