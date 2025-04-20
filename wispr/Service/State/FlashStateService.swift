
import SwiftUI

@Observable
class FlashStateService {
    var flash: FlashData?

    var isFlashing: Bool {
        flash != nil
    }

    @ViewBuilder
    var flashMessage: some View {
        if let flash {
            HStack {
                flash.icon.subTitleFontStyle()
                Text(flash.message)
            }.onAppear {
                DispatchQueue.main.asyncAfter(
                    deadline: .now() +
                        1
                ) {
                    withAnimation {
                        self.flash = nil
                    }
                }
            }
        }
    }
}
