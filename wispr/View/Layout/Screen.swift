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
    var divider: () -> TitleDivider
    var title: () -> MainTitle
    var trailingTitle: () -> TrailingTitle
    var subtitle: () -> SubTitle
    @ViewBuilder var content: () -> Content

    var dateShelf: DateShelf
    var bookShelf: BookShelf

    @State private var showShelf = false

    var body: some View {
        VStack {
            Title(
                divider: divider,
                header: title,
                subHeader: subtitle,
                trailingHeader: trailingTitle
            )
            .titleShadowStyle()

            content()
                .baseShadowStyle()
                .safeAreaPadding(.bottom, Padding.screenTop)
        }
        .sheet(isPresented: $showShelf) {
            navigationStateService.shelfState.display(
                dateShelf,
                bookShelf
            )
            .presentationDetents([.fraction(0.55)])
            .presentationBackground(
                theme.activeTheme
                    .backgroundMaterialOverlay
            )
        }
        .screenStyle()
        .toolbarBackground(.hidden)
        .navigationBarBackButtonHidden()
        .navigationTransition(.slide.combined(with: .fade(.in)))
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
        .hideSystemBackground()
    }
}

extension Screen {
    init(
        _ path: Path,
        divider: @escaping () -> TitleDivider = { EmptyView() },
        title: @escaping () -> MainTitle = { EmptyView() },
        trailingTitle: @escaping () -> TrailingTitle = { EmptyView() },
        subtitle: @escaping () -> SubTitle = { EmptyView() },
        dateShelf: DateShelf = BaseDateShelfView(),
        bookShelf: BookShelf = BaseBookShelfView(),
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.path = path
        self.divider = divider
        self.title = title
        self.trailingTitle = trailingTitle
        self.subtitle = subtitle
        self.content = content
        self.dateShelf = dateShelf
        self.bookShelf = bookShelf
    }
}
