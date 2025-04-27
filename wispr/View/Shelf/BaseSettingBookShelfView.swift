
import SwiftData
import SwiftUI

struct BaseSettingShelfView: View {
    @Environment(\.modelContext) private var modelContext: ModelContext
    @Environment(NavigationStateService.self) private var navigationStateService
    @Environment(CalendarSyncService.self) private var calendarSyncService
    @Environment(ThemeStateService.self) private var theme: ThemeStateService
    @State var loaded: Bool = false

    @State var eventCalendars: [String: [EventCalendar]] = [:]

    func title() -> some View {
        Text("Settings")
    }

    @State var resetting: Bool = false
    var body: some View {
        Screen(.settingShelf, loaded: loaded, title: title) {
            Title(header: { Text("Synced Calendars") })

            Lst {
                ForEach(
                    eventCalendars
                        .sorted(by: { $0.key < $1.key }),
                    id: \.key
                ) { key, calendars in
                    HStack {
                        Text(key)
                        Spacer()
                    }

                    ForEach(calendars) { calendar in
                        AniButton {
                            calendar.enabled.toggle()
                            Task {
                                if calendar.enabled {
                                    await calendarSyncService
                                        .sync(for: calendar)
                                } else {
                                    await EventCalendarStore
                                        .deleteAllItems(
                                            for: calendar
                                        )
                                }
                            }
                        } label: {
                            HStack {
                                Image(
                                    systemName: calendar
                                        .enabled ?
                                        "square.fill" :
                                        "square.dotted"
                                )
                                .scaleEffect(0.8)
                                Text(calendar.name)
                                Spacer()
                            }
                        }
                        .contentShape(Rectangle())
                        .parentItem()
                    }
                }

            }.padding(Spacing.m)

            Button(role: .destructive) {
                resetting = true
            } label: {
                HStack {
                    Text("Mash op evriting")
                        .alert(isPresented: $resetting) {
                            Alert(
                                title:
                                Text(
                                    "Mash it op???"
                                ),
                                message: Text(
                                    " Yuh really sure yuh waan delete everyting yuh build yah bredda? "
                                ),
                                primaryButton: .destructive(Text("Mi sure")) {
                                    withAnimation {
                                        let items = ItemStore.loadItems()
                                        for i in items {
                                            modelContext.delete(i)
                                        }

                                        let days = DayStore.loadDays()
                                        for d in days {
                                            modelContext.delete(d)
                                        }

                                        let books = BookStore.loadBooks()
                                        for b in books {
                                            modelContext.delete(b)
                                        }
                                    }

                                    resetting = false
                                },
                                secondaryButton: .cancel()
                            )
                        }
                    Spacer()
                }.padding(Spacing.l)
            }
        }
        .task {
            load()
        }
        .shelfScreenStyle([.fraction(0.75), .fraction(1)])
    }

    func load() {
        withAnimation {
            self.loaded = false
        }
        Task {
            await loadCalendars()
            withAnimation {
                self.loaded = true
            }
        }
    }

    func loadCalendars() async {
        await CalendarSyncService.syncCalendars()
        eventCalendars = EventCalendarStore.loadGroupedCalendars()
        loaded = true
    }
}
