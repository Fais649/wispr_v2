import SwiftUI

struct BookFormColorShelfView: View {
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
    ]

    var colors: [String: [Color]]
    @Binding var color: Color

    func isSelected(_ color: Color) -> Bool {
        if
            let hex = UIColor(color).toHex(),
            let selectedHex = UIColor(self.color).toHex()
        {
            return hex == selectedHex
        }
        return false
    }

    var body: some View {
        Screen(.bookShelf, backgroundOpacity: 1) {
            ScrollView {
                ForEach(
                    Array(colors).sorted { $0.key > $1.key },
                    id: \.key
                ) { name, colors in
                    Section(
                        header: HStack {
                            Text(name)
                            Spacer()
                        }.parentItem()
                            .scrollTransition(.animated) { content, phase in
                                content
                                    .opacity(phase.isIdentity ? 1 : 0)
                                    .scaleEffect(
                                        phase.isIdentity || phase
                                            .value > 0 ? 1 : 0.8,
                                        anchor:
                                        .bottom
                                    )
                                    .offset(
                                        y:
                                        phase.isIdentity || phase
                                            .value > 0 ? 0 : 20
                                    )
                            }
                    ) {
                        LazyVGrid(columns: columns, spacing: 10) {
                            ForEach(
                                colors,
                                id: \.self
                            ) { color in
                                Button {
                                    withAnimation {
                                        self.color = color
                                    }
                                } label: {
                                    Circle().fill(color).stroke(color.mix(
                                        with:
                                        .white,
                                        by:
                                        isSelected(color) ?
                                            0.6 : 0
                                    ), lineWidth: 4)
                                }
                                .scrollTransition(.animated) { content, phase
                                    in
                                    content
                                        .opacity(phase.isIdentity ? 1 : 0)
                                        .scaleEffect(
                                            phase.isIdentity || phase
                                                .value > 0 ? 1 : 0.8,
                                            anchor:
                                            .bottom
                                        )
                                        .offset(
                                            y:
                                            phase.isIdentity || phase
                                                .value > 0 ? 0 : 20
                                        )
                                }
                                .frame(
                                    width: 50,
                                    height: 50
                                )
                                .scaleEffect(
                                    isSelected(color)
                                        ? 1 : 0.9
                                )
                                .buttonStyle(.plain)
                                .shadow(
                                    color: isSelected(color) ? self
                                        .color : .clear,
                                    radius: 2
                                )
                            }
                        }
                    }
                }
            }
        }.shelfScreenStyle([.fraction(0.5)])
    }
}
