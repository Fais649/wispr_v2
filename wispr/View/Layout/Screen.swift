import SwiftUI

struct Screen<
    TitleDivider: View,
    MainTitle: View,
    SubTitle: View,
    TrailingTitle: View,
    Content: View,
    Footer: View,
    TrailingFooter: View,
    DateShelf: View,
    BookShelf: View
>: View {
    @Environment(NavigationStateService.self) private var navigationStateService
    @Environment(ThemeStateService.self) private var theme

    var path: Path = .dayScreen
    var loaded: Bool = true
    var divider: () -> TitleDivider
    var title: () -> MainTitle
    var titleStyle: TitleStyle = .regular
    var onTapTitle: (() -> Void)? = nil
    var trailingTitle: () -> TrailingTitle
    var subtitle: () -> SubTitle
    @ViewBuilder var content: () -> Content

    var footer: () -> Footer
    var trailingFooter: () -> TrailingFooter
    var dateShelf: DateShelf
    var bookShelf: BookShelf

    @State private var showShelf = false
    var backgroundTint: Color
    var backgroundOpacity: CGFloat
    var onTapBackground: (() -> Void)? = nil
    var shelfEnabled = true

    var body: some View {
        VStack {
            Title(
                titleStyle,
                header: title,
                subHeader: subtitle,
                trailingHeader: trailingTitle,
            ).onTapGesture {
                if let onTapTitle {
                    onTapTitle()
                }
            }

            if !loaded {
                Spacer()
                ProgressView()
                    .progressViewStyle(.circular)
                    .toolbarBackground(.hidden)
                    .toolbarBackgroundVisibility(.hidden)
                    .toolbarVisibility(.hidden)
                Spacer()
            } else {
                content()
                    .baseShadowStyle()
            }
        }
        .overlay(alignment: .bottomTrailing) {
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    trailingFooter()
                        .transition(
                            .scale(scale: 0, anchor: .bottomTrailing)
                                .combined(with: .opacity)
                        )
                        .background {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(.ultraThickMaterial)
                                .stroke(.thinMaterial)
                        }
                }
            }
        }.overlay(alignment: .bottom) {
            footer()
                .transition(
                    .scale(scale: 0, anchor: .bottomTrailing)
                        .combined(with: .opacity)
                )
        }
        .safeAreaPadding(Spacing.m)
        .background {
            if path.isShelf {
                RoundedRectangle(cornerRadius: 10).fill(.ultraThickMaterial)
                    .stroke(.thinMaterial)
                    .opacity(backgroundOpacity)
            } else {
                RoundedRectangle(cornerRadius: 10)
                    .fill(.regularMaterial)
                    .stroke(.ultraThinMaterial)
                    .opacity(backgroundOpacity)
                    .overlay {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(backgroundTint)
                            .opacity(0.3)
                    }
            }
        }
        .screenStyle()
        .navigationBarBackButtonHidden()
    }
}

extension Screen {
    init(
        _ path: Path,
        loaded: Bool = true,
        divider: @escaping () -> TitleDivider = { EmptyView() },
        title: @escaping () -> MainTitle = { EmptyView() },
        titleStyle: TitleStyle = .regular,
        onTapTitle: (() -> Void)? = nil,
        trailingTitle: @escaping () -> TrailingTitle = { EmptyView() },
        subtitle: @escaping () -> SubTitle = { EmptyView() },
        footer: @escaping () -> Footer = { EmptyView() },
        trailingFooter: @escaping () -> TrailingFooter = { EmptyView() },
        dateShelf: DateShelf = BaseDateShelfView(),
        bookShelf: BookShelf = BaseBookShelfView(),
        backgroundTint: Color = .clear,
        backgroundOpacity: CGFloat = 1,
        onTapBackground: (() -> Void)? = nil,
        shelfEnabled: Bool = true,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.path = path
        self.loaded = loaded
        self.divider = divider
        self.onTapTitle = onTapTitle
        self.title = title
        self.titleStyle = titleStyle
        self.trailingTitle = trailingTitle
        self.subtitle = subtitle
        self.footer = footer
        self.trailingFooter = trailingFooter
        self.content = content
        self.dateShelf = dateShelf
        self.bookShelf = bookShelf
        self.backgroundTint = backgroundTint
        self.backgroundOpacity = backgroundOpacity
        self.onTapBackground = onTapBackground
        self.shelfEnabled = shelfEnabled
    }
}
