import SwiftData
import SwiftUI
import UniformTypeIdentifiers

@Observable
class TimeLine {
    var id: UUID = .init()
    var items: [Item]
    var today: Day
    var activeDay: Day
    var firstDay: Day
    var lastDay: Day
    var days: [Day]

    init(date: Date = Date(), items: [Item] = []) {
        self.items = items
        var cal = Calendar.current
        cal.firstWeekday = 2

        let days = (-365 ... 365).map { dayInt in
            let time = cal.startOfDay(for: date).advanced(by: TimeInterval(86400 * dayInt))
            var day = Day(offset: dayInt, date: time)
            guard let itms = try? items.filter(day.itemPredicate) else {
                return day
            }

            day.items.insert(contentsOf: itms.sorted(by: { $0.position < $1.position }), at: 0)
            return day
        }

        self.days = days
        firstDay = days.first!
        lastDay = days.last!
        let today = days.first(where: { $0.offset == 0 })!

        self.today = today
        activeDay = today
    }

    var itemPredicate: Predicate<Item> {
        let start = today.date
        let end = today.date.advanced(by: 604_800)
        return #Predicate<Item> { start <= $0.timestamp && end > $0.timestamp }
    }

    func refreshDays(date: Date) {
        var cal = Calendar.current
        cal.firstWeekday = 2
        let days = (-365 ... 365).map { dayInt in
            let time = cal.startOfDay(for: date).advanced(by: TimeInterval(86400 * dayInt))
            var day = Day(offset: dayInt, date: time)
            guard let itms = try? self.items.filter(day.itemPredicate) else {
                return day
            }

            day.items.insert(contentsOf: itms, at: 0)
            return day
        }

        self.days = days
        firstDay = days.first!
        lastDay = days.last!
        activeDay = days.first(where: { $0.date == cal.startOfDay(for: date) })!
    }

    func updateDays(date: Date) {
        var cal = Calendar.current
        cal.firstWeekday = 2
        let newDate = date

        if newDate < firstDay.date || newDate > lastDay.date {
            let days = (-365 ... 365).map { dayInt in
                let time = cal.startOfDay(for: date).advanced(by: TimeInterval(86400 * dayInt))
                var day = Day(offset: dayInt, date: time)
                guard let itms = try? self.items.filter(day.itemPredicate) else {
                    return day
                }

                day.items.insert(contentsOf: itms, at: 0)
                return day
            }

            self.days = days
            firstDay = days.first!
            lastDay = days.last!
            activeDay = days.first(where: { $0.date == cal.startOfDay(for: date) })!
        } else {
            activeDay = days.first(where: { $0.date == cal.startOfDay(for: date) })!
        }
    }
}

struct TimeLineView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(DayDetailsConductor.self) private var conductor: DayDetailsConductor

    @Namespace var namespace
    @Binding var path: [NavDestination]

    @State var firstLoad: Bool = true
    @State var todayHidden: Bool = false
    @State var selectDay: Bool = false
    @Query var items: [Item]
    @State var listId: UUID = .init()
    @State var showAllDays: Bool = false

    @State var hideAll: Bool = false

    let todayDate: Date = Calendar.current.startOfDay(for: Date())

    var days: [Date: [Item]] {
        var days: [Date: [Item]] = [:]
        for dayInt in -365 ... 365 {
            let date = Calendar.current.startOfDay(for: conductor.date)
            let start = date.advanced(by: TimeInterval(dayInt * 86400))
            let end = start.advanced(by: TimeInterval(86400))
            days[start] = items.filter { start <= $0.timestamp && $0.timestamp < end }.sorted(by: { $0.position < $1.position })
        }
        return days
    }

    var body: some View {
        ScrollViewReader { proxy in
            VStack {
                List(days.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                    if showAllDays || !value.isEmpty {
                        listRow(key, value)
                    }
                }.opacity(hideAll ? 0 : 1)
                    .animation(.snappy(duration: 0.1), value: hideAll)
                    .onAppear {
                        listAppear(proxy: proxy)
                    }.overlay(alignment: .bottomTrailing) {
                        Button(action: { toggleDaysFilter(proxy) }) {
                            Image(systemName: showAllDays ? "line.3.horizontal.decrease.circle" : "line.3.horizontal.decrease.circle.fill")
                        }
                        .frame(width: 50, height: 50)
                        .padding()
                        .tint(.white)
                    }
            }
        }
        .toolbarBackgroundVisibility(.hidden, for: .bottomBar)
        .toolbarBackground(.clear, for: .bottomBar)
        .background(Color.black.ignoresSafeArea())
        .preferredColorScheme(.dark)
    }

    @ViewBuilder
    private func listRow(_ date: Date, _ items: [Item]) -> some View {
        Button(action: { resetNavigationPath(date: date) }) {
            HStack {
                if Calendar.current.isDateInToday(date) {
                    Image(systemName: "play.fill")
                        .tint(.white)
                }
                DayHeader(date: date, isEmpty: items.isEmpty)
                    .font(.custom("GohuFont11NFM", size: 14))
            }
            rowBody(date, items)
                .padding(.leading)
                .font(.custom("GohuFont11NFM", size: 14))
        }
        .opacity(Calendar.current.isDateInToday(date) || date > Date() ? 1 : 0.6)
        .listRowBackground(Color.clear)
    }

    private func resetNavigationPath(date: Date) {
        conductor.date = date
        path.removeAll()
    }

    @ViewBuilder
    private func rowBody(_ date: Date, _ items: [Item]) -> some View {
        VStack {
            ForEach(items) { item in
                Button {
                    self.conductor.date = date
                    self.path.removeAll()
                    SharedState.dayDetailsConductor.editItem = item
                } label: {
                    TimeLineItemRowLabel(item: item)
                        .onChange(of: item.position) {
                            try! modelContext.save()
                        }
                        .disabled(true)
                }
            }
        }
    }

    private func toggleDaysFilter(_ proxy: ScrollViewProxy) {
        withAnimation {
            hideAll.toggle()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation {
                showAllDays.toggle()
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation {
                listAppear(proxy: proxy)
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            hideAll.toggle()
        }
    }

    fileprivate func listAppear(proxy: ScrollViewProxy) {
        withAnimation {
            proxy.scrollTo(todayDate, anchor: .top)
        }
    }
}

struct TimeLineItemRowLabel: View {
    @Environment(\.modelContext) private var modelContext: ModelContext
    @State var item: Item
    @Namespace var namespace

    func isActiveItem(_ item: Item, _ date: Date) -> Bool {
        if let eventData = item.eventData {
            return eventData.startDate <= date && date < eventData.endDate && item.taskData?.completedAt == nil
        } else {
            return false
        }
    }

    var body: some View {
        HStack {
            VStack {
                TimelineView(.everyMinute) { time in
                    HStack {
                        VStack {
                            if item.hasImage {
                                Spacer()
                            }

                            HStack {
                                TimeLineTaskDataRowLabel(item: item)
                                TimeLineNoteDataRowLabel(item: item)
                                TimeLineEventDataRowLabel(item: item)
                            }
                            .padding(.vertical, item.isEvent || item.hasImage ? 10 : 4)
                            .padding(.horizontal, item.isEvent ? 32 : 20)
                            .tint(isActiveItem(item, time.date) ? .black : .white)
                            .frame(alignment: .bottom)
                        }
                    }
                    .background {
                        if let imageData = item.imageData {
                            ImageDataRowLabel(imageData: imageData, namespace: namespace)
                        }

                        RoundedRectangle(cornerRadius: 8)
                            .stroke(item.isEvent ? .white : .clear)
                            .fill(isActiveItem(item, time.date) ? .white : .clear).padding(2)
                            .padding(.horizontal, 12)
                    }
                    .foregroundStyle(isActiveItem(item, time.date) ? .black : .white)
                }
            }
        }
    }
}

struct TimeLineTaskDataRowLabel: View {
    var item: Item

    var body: some View {
        if item.isTask, let task = item.taskData {
            Image(systemName: task.completedAt == nil ? "square" : "square.fill")
        }
    }
}

struct TimeLineNoteDataRowLabel: View {
    var item: Item

    var body: some View {
        HStack {
            Text(item.noteData.text)
            Spacer()
        }
        .scaleEffect(item.taskData?.completedAt != nil ? 0.8 : 1, anchor: .leading)
    }
}

struct TimeLineEventDataRowLabel: View {
    var item: Item

    var body: some View {
        if let eventData = item.eventData {
            VStack {
                HStack {
                    Spacer()
                    if eventData.startDate == Calendar.current.startOfDay(for: eventData.startDate) && eventData.endDate == Calendar.current.startOfDay(for: eventData.endDate).advanced(by: -60) {
                        Image(systemName: "square.fill.and.line.vertical.and.square.fill")
                    } else {
                        Text(eventData.startDate.formatted(.dateTime.hour().minute()) + " | " + eventData.endDate.formatted(.dateTime.hour().minute()))
                            .fixedSize()
                            .lineLimit(1)
                    }
                }
            }
        }
    }
}
