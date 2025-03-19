
import AppIntents
import AudioKit
import AVFoundation
import EventKit
import EventKitUI
import Foundation
import SwiftData
import SwiftUI
import SwiftWhisper

public extension Calendar {
    func combineDateAndTime(date: Date, time: Date) -> Date {
        var comps = Calendar.current.dateComponents([.year, .month, .day], from: date)
        comps.hour = Calendar.current.component(.hour, from: time)
        comps.minute = Calendar.current.component(.minute, from: time)
        let d = Calendar.current.date(from: comps)
        return d ?? time
    }
}

public extension Date {
    var defaultIntentParameter: IntentParameter<Date> {
        let i = IntentParameter<Date>(title: "Date", default: self)
        i.wrappedValue = self
        return i
    }
}

class AudioPlayer {
    var audioSession: AVAudioSession
    var audioPlayer: AVAudioPlayer?

    init(url: URL) {
        let audioSession = AVAudioSession.sharedInstance()
        try? audioSession.setCategory(.playback, mode: .spokenAudio)
        try? audioSession.overrideOutputAudioPort(AVAudioSession.PortOverride.speaker)
        try? audioSession.setActive(true)

        self.audioSession = audioSession
        audioPlayer = try? AVAudioPlayer(contentsOf: url)
    }
}

@Observable
class AudioService {
    var hasPermission = false
    var isRecording = false
    var recorderPrepared = false
    var recordedURL: URL?
    var audioPlayer: AVAudioPlayer?

    private var audioEngine: AVAudioEngine?
    private var audioFile: AVAudioFile?
    private var audioSession: AVAudioSession?

    private var audioRecorder: AVAudioRecorder?

    func requestRecordPermission() async {
        if await AVAudioApplication.requestRecordPermission() {
            hasPermission = true
        } else {
            hasPermission = false
        }
    }

    func setupAudioSession() async throws {
        if !hasPermission {
            await requestRecordPermission()
        }

        if audioSession == nil {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .spokenAudio)
            try? audioSession.overrideOutputAudioPort(AVAudioSession.PortOverride.speaker)
            try audioSession.setActive(true)
            self.audioSession = audioSession
        }
    }

    func setupPlayer() {
        if let url = recordedURL {
            audioPlayer = try? AVAudioPlayer(contentsOf: url)
            audioPlayer?.prepareToPlay()
        }
    }

    func setupRecorder(audioFilename: URL) async throws {
        try? await setupAudioSession()
        let recordingSettings: [String: Any] = [AVFormatIDKey: kAudioFormatMPEG4AAC, AVSampleRateKey: 12000, AVNumberOfChannelsKey: 1, AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue]
        recordedURL = audioFilename
        audioRecorder = try AVAudioRecorder(url: audioFilename, settings: recordingSettings)
        audioRecorder?.prepareToRecord()
    }

    func startRecording() {
        audioRecorder?.record()
        isRecording = true
    }

    func stopRecording() {
        audioRecorder?.stop()

        if isRecording {
            isRecording = false
        }

        try? audioSession?.setActive(false)
    }

    func extractTextFromAudio(_ audioURL: URL, completionHandler: @escaping (Result<String, Error>) -> Void) {
        let modelURL = Bundle.main.url(forResource: "tiny", withExtension: "bin")!
        let whisper = Whisper(fromFileURL: modelURL)
        convertAudioFileToPCMArray(fileURL: audioURL) { result in
            switch result {
            case let .success(success):
                Task {
                    do {
                        let segments = try await whisper.transcribe(audioFrames: success)
                        completionHandler(.success(segments.map(\.text).joined()))
                    } catch {
                        completionHandler(.failure(error))
                    }
                }
            case let .failure(failure):
                completionHandler(.failure(failure))
            }
        }
    }

    func convertAudioFileToPCMArray(fileURL: URL, completionHandler: @escaping (Result<[Float], Error>) -> Void) {
        var options = FormatConverter.Options()
        options.format = .wav
        options.sampleRate = 16000
        options.bitDepth = 16
        options.channels = 1
        options.isInterleaved = false

        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        let converter = FormatConverter(inputURL: fileURL, outputURL: tempURL, options: options)
        converter.start { error in
            if let error {
                completionHandler(.failure(error))
                return
            }

            let data = try! Data(contentsOf: tempURL)

            let floats = stride(from: 44, to: data.count, by: 2).map {
                data[$0 ..< $0 + 2].withUnsafeBytes {
                    let short = Int16(littleEndian: $0.load(as: Int16.self))
                    return max(-1.0, min(Float(short) / 32767.0, 1.0))
                }
            }

            try? FileManager.default.removeItem(at: tempURL)

            completionHandler(.success(floats))
        }
    }
}

extension UIColor {
    convenience init(hex: String) {
        var hexString = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if hexString.hasPrefix("#") {
            hexString.removeFirst()
        }

        let scanner = Scanner(string: hexString)

        var rgbValue: UInt64 = 0
        var red, green, blue, alpha: UInt64
        if scanner.scanHexInt64(&rgbValue) {
            switch hexString.count {
            case 6:
                red = (rgbValue >> 16)
                green = (rgbValue >> 8 & 0xFF)
                blue = (rgbValue & 0xFF)
                alpha = 255
            case 8:
                red = (rgbValue >> 16)
                green = (rgbValue >> 8 & 0xFF)
                blue = (rgbValue & 0xFF)
                alpha = rgbValue >> 24
            default:
                red = 0
                green = 0
                blue = 0
                alpha = 0
            }
        } else {
            red = 0
            green = 0
            blue = 0
            alpha = 0
        }

        self.init(red: CGFloat(red) / 255, green: CGFloat(green) / 255, blue: CGFloat(blue) / 255, alpha: CGFloat(alpha) / 255)
    }

    // Returns a hex string representation of the UIColor instance
    func toHex(includeAlpha: Bool = false) -> String? {
        // Get the red, green, and blue components of the UIColor as floats between 0 and 1
        guard let components = cgColor.components else {
            // If the UIColor's color space doesn't support RGB components, return nil
            return nil
        }

        // Convert the red, green, and blue components to integers between 0 and 255
        let red = Int(components[0] * 255.0)
        let green = Int(components[1] * 255.0)
        let blue = Int(components[2] * 255.0)

        // Create a hex string with the RGB values and, optionally, the alpha value
        let hexString: String
        if includeAlpha, let alpha = components.last {
            let alphaValue = Int(alpha * 255.0)
            hexString = String(format: "#%02X%02X%02X%02X", red, green, blue, alphaValue)
        } else {
            hexString = String(format: "#%02X%02X%02X", red, green, blue)
        }

        // Return the hex string
        return hexString
    }
}

struct HeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat?

    static func reduce(value: inout CGFloat?, nextValue: () -> CGFloat?) {
        guard let nextValue = nextValue() else { return }
        value = nextValue
    }
}

private struct ReadHeightModifier: ViewModifier {
    private var sizeView: some View {
        GeometryReader { geometry in
            Color.clear.preference(
                key: HeightPreferenceKey.self,
                value: geometry.size.height
            )
        }
    }

    func body(content: Content) -> some View {
        content.background(sizeView)
    }
}

extension View {
    func readHeight() -> some View {
        modifier(ReadHeightModifier())
    }
}

struct FlippedUpsideDown: ViewModifier {
    func body(content: Content) -> some View {
        content
            .rotationEffect(.degrees(180))
            .scaleEffect(x: -1, y: 1, anchor: .center)
    }
}

extension View {
    func flippedUpsideDown() -> some View {
        modifier(FlippedUpsideDown())
    }
}

extension Calendar {
    func startOfWeek(_ date: Date) -> Date? {
        guard let sunday = self.date(from: dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)) else { return nil }
        return self.date(byAdding: .day, value: 1, to: sunday)
    }

    func endOfWeek(_ date: Date) -> Date? {
        guard let sunday = self.date(from: dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)) else { return nil }
        return self.date(byAdding: .day, value: 7, to: sunday)
    }
}

enum DateTimeString {
    static func toolbarDateString(date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        let today = Calendar.current.startOfDay(for: Date())
        formatter.unitsStyle = .short
        let date = Calendar.current.startOfDay(for: date)
        if date != today {
            return "\(date.formatted(.dateTime.weekday(.short))). \(date.formatted(date: .abbreviated, time: .omitted))"
        }

        return "\(date.formatted(date: .abbreviated, time: .omitted)) "
    }

    static func bottoBarWeekDay(date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return "\(date.formatted(.dateTime.weekday(.short)))"
    }

    static func relativeToToday(date: Date) -> String {
        let relativeToToday = RelativeDateTimeFormatter()
        let today = Calendar.current.startOfDay(for: Date())
        relativeToToday.unitsStyle = .abbreviated
        return "\(relativeToToday.localizedString(for: date, relativeTo: today))"
    }

    static func leftDateString(date: Date) -> String {
        return date.formatted(.dateTime.day().month().year(.twoDigits))
    }

    static func rightDateString(date: Date) -> String {
        if Calendar.current.isDateInToday(date) {
            return "Today - " + date.formatted(.dateTime.weekday(.abbreviated))
        }

        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date()) + " - " + date.formatted(.dateTime.weekday(.abbreviated))
    }
}

@Observable
class CalendarService {
    var accessToCalendar: Bool = false
    var synced: Bool = false

    let eventStore: EKEventStore = .init()

    init() {}

    func syncCalendar(modelContext: ModelContext) {
        if synced { return }

        let es = eventStore
            .events(
                matching: eventStore
                    .predicateForEvents(
                        withStart: Date().advanced(by: -365 * 24 * 60 * 60),
                        end: Date().advanced(by: 365 * 24 * 60 * 60),
                        calendars: nil
                    )
            )

        let eDict: [Date: [EKEvent]] = Dictionary(grouping: es, by: { Calendar.current.startOfDay(for: $0.startDate) })

        let desc = FetchDescriptor<Item>()

        guard let evs = try? modelContext.fetch(desc) else {
            return
        }

        let events = evs.filter { $0.eventData != nil }

        let eventsDict: [Date: [Item]] = Dictionary(grouping: events, by: { if let ed = $0.eventData {
            return Calendar.current.startOfDay(for: ed.startDate)
        }
        return Calendar.current.startOfDay(for: Date())
        })

        for (date, es) in eDict {
            for e in es {
                if let event = events.filter({ $0.eventData?.eventIdentifier == e.eventIdentifier }).first, var data = event.eventData {
                    data.startDate = e.startDate
                    data.endDate = e.endDate
                    data.calendarIdentifier = e.calendar.calendarIdentifier
                    event.eventData = data
                    event.text = e.title
                } else {
                    let newEvent = Item(position: eventsDict[Calendar.current.startOfDay(for: date)]?.count ?? 0, timestamp: date)
                    newEvent.text = e.title
                    newEvent.eventData = EventData(
                        eventIdentifier: e.eventIdentifier,
                        startDate: e.startDate,
                        endDate: e.endDate,
                        calendarIdentifier: e.calendar.calendarIdentifier
                    )
                    modelContext.insert(newEvent)
                }
            }
        }

        try? modelContext.save()
        synced = true
    }

    func deleteEKEvent(_ eventIdentifier: String) {
        if let ekEvent = eventStore.event(withIdentifier: eventIdentifier) {
            deleteEventInCalendar(event: ekEvent)
        }
    }

    @MainActor
    func updateEKEvent(ekEvent: EKEvent, item: Item, event: EventData) {
        ekEvent.startDate = event.startDate
        ekEvent.endDate = event.endDate
        ekEvent.title = item.text
        try? eventStore.save(ekEvent, span: .thisEvent)
    }

    func requestAccessToCalendar() {
        eventStore.requestFullAccessToEvents { granted, error in
            if granted, error == nil {
                self.accessToCalendar = true
            }
        }
    }

    func createEventInCalendar(title: String, start: Date, end: Date) -> EKEvent? {
        if !accessToCalendar {
            requestAccessToCalendar()
        }

        if accessToCalendar {
            let ekEvent = EKEvent(eventStore: eventStore)
            ekEvent.title = title
            ekEvent.startDate = start
            ekEvent.endDate = end
            ekEvent.calendar = eventStore.defaultCalendarForNewEvents

            try? eventStore.save(ekEvent, span: .thisEvent)
            return ekEvent
        }
        return nil
    }

    func deleteEventInCalendar(event: EKEvent) {
        if !accessToCalendar {
            requestAccessToCalendar()
        }

        if accessToCalendar {
            if let eventToDelete = eventStore.event(withIdentifier: event.eventIdentifier) {
                do {
                    try eventStore.remove(eventToDelete, span: .thisEvent)
                } catch {
                    print("Error deleting event: \(error.localizedDescription)")
                }
            }
        }
    }
}

struct TextFieldLimitModifer: ViewModifier {
    @Binding var value: String
    var length: Int

    func body(content: Content) -> some View {
        content
            .onReceive(value.publisher.collect()) {
                value = String($0.prefix(length))
            }
    }
}

struct ListRowStyler: ViewModifier {
    var rowSpacing: CGFloat = 0
    func body(content: Content) -> some View {
        content
            .listRowBackground(Color.clear)
            .listRowSpacing(rowSpacing)
            .listRowSeparator(.hidden)
            .contentShape(Rectangle())
            .font(.system(size: 16))
            .foregroundStyle(.white)
            .shadow(color: .white, radius: 2)
            .padding(6)
    }
}

struct ToolbarButtonStyler<S: Shape, B: ShapeStyle>: ViewModifier {
    var background: B
    var clipShape: S

    init(background: B = Material.ultraThinMaterial, clipShape: S = Circle()) {
        self.clipShape = clipShape
        self.background = background
    }

    func body(content: Content) -> some View {
        content
            .background(.red)
            .clipShape(clipShape)
    }
}

struct ToolbarButtonLabelStyler: ViewModifier {
    var padding: CGFloat = 6
    var shadowRadius: CGFloat = 2
    var fontSize: CGFloat = 16

    func body(content: Content) -> some View {
        content
            .contentShape(Rectangle())
            .font(.system(size: fontSize))
            .foregroundStyle(.white)
            .shadow(color: .white, radius: shadowRadius)
            .padding(padding)
    }
}

extension View {
    func listRowStyler(_ rowSpacing: CGFloat = 0) -> some View {
        modifier(ListRowStyler(rowSpacing: rowSpacing))
    }

    func toolbarButtonStyler<B: ShapeStyle, S: Shape>(_ background: B, _ shape: S) -> some View {
        modifier(ToolbarButtonStyler(background: background, clipShape: shape))
    }

    func toolbarButtonLabelStyler(padding: CGFloat = 6, shadowRadius: CGFloat = 2, fontSize: CGFloat = 16) -> some View {
        modifier(ToolbarButtonLabelStyler(padding: padding, shadowRadius: shadowRadius, fontSize: fontSize))
    }

    func limitInputLength(value: Binding<String>, length: Int) -> some View {
        modifier(TextFieldLimitModifer(value: value, length: length))
    }
}
