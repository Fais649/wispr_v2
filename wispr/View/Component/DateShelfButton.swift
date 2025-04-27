import SwiftUI

struct DateShelfButton<Shelf: View>: View {
    @State private var showDateShelf: Bool = false
    @Binding var date: Date

    var shelf: () -> Shelf

    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }

    var body: some View {
        ToolbarButton {
            showDateShelf.toggle()
        } label: {
            Image(systemName: "circle.grid.3x3.circle.fill")
                .fontWeight(.black)
        }
        .sheet(isPresented: $showDateShelf) {
            shelf()
        }
    }
}
