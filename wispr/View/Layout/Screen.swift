import SwiftData
import SwiftUI

struct Screen<
    TitleDivider: View,
    MainTitle: View,
    SubTitle: View,
    TrailingTitle: View,
    Content: View
>: View {
    var divider: (() -> TitleDivider)? = nil
    var title: (() -> MainTitle)? = nil
    var trailingTitle: (() -> TrailingTitle)? = nil
    var subtitle: (() -> SubTitle)? = nil
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack {
            Title(
                divider: divider,
                header: title,
                subHeader: subtitle,
                trailingHeader: trailingTitle
            )
            .titleShadowStyle()
            .background {
                Rectangle().fill(.ultraThinMaterial)
                    .fade(.top, .bottom)
                    .ignoresSafeArea()
            }

            content()
                .baseShadowStyle()
        }
        .screenStyle()
        .toolbarBackground(.hidden)
        .navigationBarBackButtonHidden()
        .navigationTransition(
            .slide.combined(with: .fade(.in))
        )
        .hideSystemBackground()
        .dateShelf {
            BaseDateShelfView()
        }
    }
}

extension Screen
    where
    TitleDivider == Never,
    MainTitle == Never,
    SubTitle == Never,
    TrailingTitle == Never
{
    init(@ViewBuilder content: @escaping () -> Content) {
        divider = nil
        title = nil
        trailingTitle = nil
        subtitle = nil
        self.content = content
    }
}

extension Screen
    where
    TitleDivider == Never,
    SubTitle == Never,
    TrailingTitle == Never
{
    init(
        title: (() -> MainTitle)? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        divider = nil
        self.title = title
        trailingTitle = nil
        subtitle = nil
        self.content = content
    }
}

extension Screen
    where
    SubTitle == Never,
    TrailingTitle == Never
{
    init(
        divider: (() -> TitleDivider)? = nil,
        title: (() -> MainTitle)? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.divider = divider
        self.title = title
        trailingTitle = nil
        subtitle = nil
        self.content = content
    }
}

extension Screen
    where
    TitleDivider == Never
{
    init(
        title: (() -> MainTitle)? = nil,
        trailingTitle: (() -> TrailingTitle)? = nil,
        subtitle: (() -> SubTitle)? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        divider = nil
        self.title = title
        self.trailingTitle = trailingTitle
        self.subtitle = subtitle
        self.content = content
    }
}

extension Screen
    where
    TrailingTitle == Never
{
    init(
        divider: (() -> TitleDivider)? = nil,
        title: (() -> MainTitle)? = nil,
        subtitle: (() -> SubTitle)? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.divider = divider
        self.title = title
        trailingTitle = nil
        self.subtitle = subtitle
        self.content = content
    }
}

extension Screen
    where
    TitleDivider == Never,
    TrailingTitle == Never
{
    init(
        title: (() -> MainTitle)? = nil,
        subtitle: (() -> SubTitle)? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        divider = nil
        self.title = title
        trailingTitle = nil
        self.subtitle = subtitle
        self.content = content
    }
}

extension Screen
    where
    SubTitle == Never
{
    init(
        divider: (() -> TitleDivider)? = nil,
        title: (() -> MainTitle)? = nil,
        trailingTitle: (() -> TrailingTitle)? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.divider = divider
        self.title = title
        self.trailingTitle = trailingTitle
        self.content = content
    }
}
