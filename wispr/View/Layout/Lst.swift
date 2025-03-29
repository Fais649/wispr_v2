
import SwiftUI

struct Lst<Content: View>: View {
    @ViewBuilder
    var content: () -> Content

    var body: some View {
        List {
            content()
                .lstRowStyle()
        }
        .lstStyle()
    }
}
