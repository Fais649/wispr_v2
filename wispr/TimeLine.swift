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

    @State var day: ScrollPosition = .init()

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack {
                    ForEach(days.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                        if showAllDays || !value.isEmpty {
                            listRow(key, value)
                        }
                    }.opacity(hideAll ? 0 : 1)
                        .onAppear { listAppear(proxy: proxy) }
                        .scrollTransition(.interactive.threshold(.centered.interpolated(towards:
                            .hidden, amount: 0.4)))
                    { content, phase in
                        content
                            .opacity(phase.isIdentity ? 1 : -0.2)
                            .scaleEffect(phase.isIdentity ? 1 : 0.2)
                            .blur(radius: phase.isIdentity ? 0 : 10)
                    }
                }.padding()
                    .scrollTargetLayout()
            }
            .overlay(alignment: .bottom) {
                Button(action: {
                    withAnimation {
                        proxy.scrollTo(todayDate, anchor: .center)
                    }
                }) {
                    Image(systemName: "circle.dotted.circle")
                        .font(.custom("GohuFont11NFM", size: 40))
                        .foregroundStyle(.white)
                }.buttonStyle(.plain)
                    .background {
                        Circle().fill(.black)
                    }
                    .frame(width: 100, height: 100)
                    .padding()
            }
            .scrollPosition($day, anchor: .center)
            .padding()
            .defaultScrollAnchor(.center)
            .scrollTargetBehavior(.viewAligned)
        }
        .toolbarBackgroundVisibility(.hidden, for: .bottomBar)
        .toolbarBackground(.clear, for: .bottomBar)
        .background(Color.black.ignoresSafeArea())
        .preferredColorScheme(.dark)
    }

    @ViewBuilder
    private func listRow(_ date: Date, _ items: [Item]) -> some View {
        Button(action: { resetNavigationPath(date: date) }) {
            VStack {
                if Calendar.current.isDateInToday(date) {
                    HStack {
                        DayHeader(date: date, isEmpty: items.isEmpty)
                            .font(.custom("GohuFont11NFM", size: 20))
                            .padding(.horizontal)
                    }
                    .background(.white)
                    .foregroundStyle(.black)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                } else {
                    HStack {
                        DayHeader(date: date, isEmpty: items.isEmpty)
                            .font(.custom("GohuFont11NFM", size: 18))
                    }
                }

                rowBody(date, items)
                    .padding(.leading)
                    .font(.custom("GohuFont11NFM", size: 16))
            }
        }
        .padding()
        .opacity(Calendar.current.isDateInToday(date) || date > Date() ? 1 :
            0.3)
        .listRowBackground(Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private func resetNavigationPath(date: Date) {
        withAnimation {
            conductor.date = date
            path.removeAll()
        }
    }

    @ViewBuilder
    private func rowBody(_: Date, _ items: [Item]) -> some View {
        VStack {
            ForEach(items) { item in
                TimeLineItemListRow(path: $path, item: item)
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
            proxy.scrollTo(Calendar.current.startOfDay(for: conductor.date), anchor: .center)
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
                            ImageDataRowLabel(imageData: imageData, namespace: namespace, disabled: true)
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

struct TimeLineItemListRow: View {
    @Environment(DayDetailsConductor.self) private var conductor: DayDetailsConductor
    @Environment(\.modelContext) private var modelContext: ModelContext
    @Environment(CalendarService.self) private var calendarService: CalendarService
    @Binding var path: [NavDestination]

    var item: Item
    init(path: Binding<[NavDestination]>, item: Item) {
        _path = path
        self.item = item
        let item = item
        taskData = item.taskData
        subtasks = item.taskData?.subtasks ?? []
        noteData = item.noteData
        eventData = item.eventData
        imageData = item.imageData
        audioData = item.audioData
    }

    var assignedTags: [Tag] = []
    var noteData: NoteData = .init(text: "")
    var taskData: TaskData? = nil
    var subtasks: [SubTaskData] = []
    var eventData: EventData? = nil
    var imageData: ImageData? = nil
    var audioData: AudioData? = nil

    @Query var tags: [Tag]

    @State var showTag: Bool = false
    @State var tagSearchTerm: String = ""
    @State private var image: Image?
    @Namespace var namespace

    var tagSearchResults: [Tag] {
        if tagSearchTerm.isEmpty {
            return tags.filter { !assignedTags.contains($0) }
        } else {
            return tags.filter { $0.name.contains(tagSearchTerm) && !assignedTags.contains($0) }
        }
    }

    @FocusState var noteFocus: Bool
    @FocusState var childFocus: Bool
    @FocusState var tagSearchFocus: Bool

    @State var expand: Bool = false
    var hasSubTasks: Bool {
        if let task = taskData { return task.subtasks.isNotEmpty } else { return false }
    }

    @ViewBuilder
    func relateiveStartString(_ time: Date) -> some View {
        if let event = eventData, Calendar.current.isDateInToday(event.startDate) {
            if time < event.startDate {
                HStack {
                    Image(systemName: "clock")
                    Text(formatter.localizedString(for: event.startDate, relativeTo: time))
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                }
            } else if time < event.endDate {
                HStack {
                    Image(systemName: "timer")
                    Text(time, format: .timer(countingDownIn: event.startDate ..< event.endDate))
                }
            }
        }
    }

    var formatter: RelativeDateTimeFormatter {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter
    }

    var startString: String {
        if let event = eventData {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            return formatter.string(from: event.startDate)
        }
        return ""
    }

    var endString: String {
        if let event = eventData {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            return formatter.string(from: event.endDate)
        }
        return ""
    }

    func isActiveItem(_ item: Item, _ date: Date) -> Bool {
        if let eventData = item.eventData {
            return eventData.startDate <= date && date < eventData.endDate && item.taskData?.completedAt == nil
        } else {
            return false
        }
    }

    @ViewBuilder
    var rowBackgroundView: some View {
        if let imageData = item.imageData {
            ImageDataListRow(imageData: imageData, namespace: namespace)
        } else {
            TimelineView(.periodic(from: .now, by: 1)) { time in
                RoundedRectangle(cornerRadius: 20).fill(isActiveItem(item, time.date) ? .white : .clear)
            }
        }
    }

    @ViewBuilder
    func subtaskView(time: Date) -> some View {
        DisclosureGroup(isExpanded: $expand) {
            if subtasks.isNotEmpty {
                ForEach(
                    subtasks.sorted(by: { first, second in first.position < second.position }).indices,
                    id: \.self
                ) { index in
                    SubTaskDataListRow(
                        item: item,
                        subtask: subtasks[index]
                    ).scrollTargetLayout()
                        .fixedSize(horizontal: false, vertical: true)
                        .scrollClipDisabled(subtasks.count > 0)
                }
            }
        } label: {
            labelView(time: time)
        }
    }

    @ViewBuilder
    func labelView(time: Date) -> some View {
        HStack {
            TaskDataListRow(item: item, taskData: taskData)
                .fixedSize(horizontal: false, vertical: true)

            Text(noteData.text)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()

            if eventData != nil {
                VStack {
                    relateiveStartString(time)
                    HStack {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(isActiveItem(item, time) && item.imageData == nil ? .black : .white)
                            .frame(width: 1, height: 20)
                            .padding(.horizontal, 8)
                        Spacer()
                        VStack {
                            Text(startString)
                            Text(endString)
                        }
                    }
                }
                .font(.custom("GohuFont11NFM", size: 12))
                .frame(width: 58)
            }
        }.background {
            if let imageData = item.imageData {
                TimeLineImageDataListRow(imageData: imageData)
            }
        }
    }

    var body: some View {
        TimelineView(.everyMinute) { time in
            VStack {
                if hasSubTasks {
                    subtaskView(time: time.date)
                } else {
                    labelView(time: time.date)
                }
            }
            .padding()
            .background {
                if isActiveItem(item, time.date) {
                    RoundedRectangle(cornerRadius: 20).fill(.white)
                }
            }
            .foregroundStyle(isActiveItem(item, time.date) ? .black : .white)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            // AudioRecordingView(audioData: $audioData)
            // TagDataRow(tags: $assignedTags)
        }
        .listRowBackground(Color.clear)
        .tint(.white)
    }
}

struct TimeLineImageDataListRow: View {
    var imageData: ImageData
    var disabled: Bool = false
    @State var showImage: Bool = false

    @ViewBuilder
    var imageView: some View {
        if let image = imageData.image {
            image.resizable().scaledToFill()
                .aspectRatio(CGSize(width: 4, height: 3), contentMode: .fill)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay {
                    LinearGradient(gradient: Gradient(colors: [.clear, .black]), startPoint: .top, endPoint: .bottom)
                }
        }
    }

    var body: some View {
        imageView
            .padding(2)
            .padding(.horizontal, 12)
    }
}
