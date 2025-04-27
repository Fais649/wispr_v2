
import SwiftUI

struct AudioRecorderShelfView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(ThemeStateService.self) private var theme: ThemeStateService
    @Binding var audioData: AudioData?

    func title() -> some View {
        Text("Record Memo")
    }

    var todayDate: Date {
        Calendar.current.roundToNearestHalfHour(Date())
    }

    var body: some View {
        Screen(
            .audioRecorderShelf,
            title: title
        ) {
            AudioRecorderView(audioData: $audioData)
        }.shelfScreenStyle([.fraction(0.2)])
    }
}
