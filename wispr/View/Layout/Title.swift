import SwiftUI

public enum TitleStyle {
    case regular, small, xlarge
}

struct Title<
    Divider: View,
    Header: View,
    SubHeader: View,
    TrailingHeader: View
>: View {
    var divider: () -> Divider
    var header: () -> Header
    var subHeader: () -> SubHeader
    var trailingHeader: () -> TrailingHeader

    var style: TitleStyle = .regular

    init(
        _ style: TitleStyle = .regular,
        divider: @escaping () -> Divider = { EmptyView() },
        header: @escaping () -> Header = { EmptyView() },
        subHeader: @escaping () -> SubHeader = { EmptyView() },
        trailingHeader: @escaping () -> TrailingHeader = { EmptyView() }
    ) {
        self.style = style
        self.divider = divider
        self.header = header
        self.subHeader = subHeader
        self.trailingHeader = trailingHeader
    }

    var body: some View {
        VStack {
            VStack {
                HStack {
                    divider()
                }

                HStack {
                    header()
                    Spacer()
                    trailingHeader()
                }
            }
            .titleFontStyle(style)

            HStack {
                subHeader()
            }
            .subTitleFontStyle(style)
        }
    }
}
