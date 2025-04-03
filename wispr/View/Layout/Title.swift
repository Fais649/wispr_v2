import SwiftUI

struct Title<
    Divider: View,
    Header: View,
    SubHeader: View,
    TrailingHeader: View
>: View {
    var divider: (() -> Divider)? = nil
    var header: (() -> Header)? = nil
    var subHeader: (() -> SubHeader)? = nil
    var trailingHeader: (() -> TrailingHeader)? = nil

    var body: some View {
        if
            divider != nil || header != nil || subHeader != nil ||
            trailingHeader != nil
        {
            VStack {
                VStack {
                    if let divider {
                        HStack { divider() }
                    }
                    HStack {
                        if let header {
                            header()
                        }
                        Spacer()
                        if let trailingHeader {
                            trailingHeader()
                        }
                    }
                }
                .titleTextStyle()

                if let subHeader {
                    HStack {
                        subHeader()
                        Spacer()
                    }
                    .subTitleTextStyle()
                }
            }
        }
    }
}

extension Title
    where
    Divider == Never,
    SubHeader == Never,
    Header == Never,
    TrailingHeader == Never
{
    init() {
        divider = nil
        header = nil
        subHeader = nil
        trailingHeader = nil
    }
}

extension Title
    where
    Divider == Never,
    TrailingHeader == Never,
    SubHeader == Never
{
    init(
        header: (() -> Header)?
    ) {
        divider = nil
        self.header = header
        subHeader = nil
        trailingHeader = nil
    }
}

extension Title
    where
    Divider == Never,
    SubHeader == Never
{
    init(
        header: (() -> Header)?,
        trailingHeader: (() -> TrailingHeader)?
    ) {
        divider = nil
        self.header = header
        subHeader = nil
        self.trailingHeader = trailingHeader
    }
}
