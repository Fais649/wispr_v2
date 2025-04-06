import SwiftUI

struct Screen<
    TitleDivider: View,
    MainTitle: View,
    SubTitle: View,
    TrailingTitle: View,
    Content: View,
    DateShelf: View,
    BookShelf: View
>: View {
    @Environment(NavigationStateService.self) private var navigationStateService
    @Environment(ThemeStateService.self) private var theme

    var path: Path = .dayScreen
    var loaded: Bool = true
    var divider: () -> TitleDivider
    var title: () -> MainTitle
    var onTapTitle: (() -> Void)? = nil
    var trailingTitle: () -> TrailingTitle
    var subtitle: () -> SubTitle
    @ViewBuilder var content: () -> Content

    var dateShelf: DateShelf
    var bookShelf: BookShelf

    @State private var showShelf = false
    var backgroundOpacity: CGFloat

    var body: some View {
        VStack {
            Title(
                header: title,
                subHeader: subtitle,
                trailingHeader: trailingTitle
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
                    .fade(from: .top, fromOffset: 0.8, to: .bottom, toOffset: 1)
                    .animation(.smooth, value: loaded)
            }
        }
        .safeAreaPadding(.horizontal, Spacing.m)
        .safeAreaPadding(.top, Spacing.m)
        .background {
            RoundedRectangle(cornerRadius: 20).fill(.ultraThinMaterial)
                .stroke(.thinMaterial)
                .safeAreaPadding(.horizontal, Spacing.s)
                .opacity(backgroundOpacity)
        }
        .safeAreaPadding(.bottom, Spacing.l)
        .sheet(isPresented: $showShelf) {
            if navigationStateService.pathState.active == path {
                navigationStateService.shelfState.display(
                    dateShelf,
                    bookShelf
                )
                .presentationDetents([.fraction(0.55)])
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
            }
        }
        .screenStyle()
        .navigationBarBackButtonHidden()
        .onChange(of: navigationStateService.shelfState.isShown()) {
            if !navigationStateService.shelfState.isShown() {
                withAnimation {
                    navigationStateService.shelfState.dismissShelf()
                    showShelf = navigationStateService.shelfState.isShown()
                }
                return
            }

            if navigationStateService.pathState.active == path {
                withAnimation {
                    showShelf = navigationStateService.shelfState.isShown()
                }
            }
        }
    }
}

extension Screen {
    init(
        _ path: Path,
        loaded: Bool = true,
        divider: @escaping () -> TitleDivider = { EmptyView() },
        title: @escaping () -> MainTitle = { EmptyView() },
        onTapTitle: (() -> Void)? = nil,
        trailingTitle: @escaping () -> TrailingTitle = { EmptyView() },
        subtitle: @escaping () -> SubTitle = { EmptyView() },
        dateShelf: DateShelf = BaseDateShelfView(),
        bookShelf: BookShelf = BaseBookShelfView(),
        backgroundOpacity: CGFloat = 1,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.path = path
        self.loaded = loaded
        self.divider = divider
        self.onTapTitle = onTapTitle
        self.title = title
        self.trailingTitle = trailingTitle
        self.subtitle = subtitle
        self.content = content
        self.dateShelf = dateShelf
        self.bookShelf = bookShelf
        self.backgroundOpacity = backgroundOpacity
    }
}
