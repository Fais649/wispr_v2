import SwiftUI

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

    init(
        divider: @escaping () -> Divider = { EmptyView() },
        header: @escaping () -> Header = { EmptyView() },
        subHeader: @escaping () -> SubHeader = { EmptyView() },
        trailingHeader: @escaping () -> TrailingHeader = { EmptyView() }
    ) {
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
            .titleTextStyle()

            HStack {
                subHeader()
            }
            .subTitleTextStyle()
        }
    }
}
