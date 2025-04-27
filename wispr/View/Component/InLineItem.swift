import PhotosUI
import SwiftUI
import SwiftWhisper

struct InLineItem: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(NavigationStateService.self) private var navigationState
    @FocusState.Binding var focus: FocusedField?
    @Binding var highlight: FocusedField?

    @Namespace var animation
    var activeDate: Date? = nil
    @Bindable var item: Item
    @State private var text: String
    @State private var timestamp: Date
    @State private var eventFormData: EventData.FormData?
    @State private var imageItems: [PhotosPickerItem] = []
    @State private var audioData: AudioData?

    @State private var showRecordingShelf: Bool = false
    @State private var showPhotoPicker = false
    @State private var showDateShelf: Bool = false

    init(
        activeDate: Date? = nil,
        item: Item,
        focus: FocusState<FocusedField?>.Binding,
        highlight: Binding<FocusedField?>
    ) {
        self.activeDate = activeDate
        _focus = focus
        _highlight = highlight
        _item = Bindable(item)
        text = item.text
        timestamp = item.timestamp
        audioData = item.audioData
        eventFormData = item.eventData?.formData()
    }

    var noFocus: Bool {
        focus == nil
    }

    var noHighlight: Bool {
        highlight == nil
    }

    var isHighlighted: Bool {
        highlight == .item(id: item.id)
    }

    var isFocused: Bool {
        focus == .item(id: item.id) ||
            item.children.contains(where: { focus == .item(id: $0.id) })
    }

    var bgRect: some Shape {
        UnevenRoundedRectangle(cornerRadii: .init(
            topLeading: 4,
            bottomLeading: 4,
            bottomTrailing: 4,
            topTrailing: 4
        ))
    }

    var bg: some View {
        bgRect
            .fill(.ultraThinMaterial)
            .overlay(
                bgRect
                    .fill(item.colorTint.gradient)
                    .opacity(0.4)
            )
    }

    var showAttachments: Bool {
        if let images = item.imageData {
            return images.isNotEmpty || audioData != nil
        }
        return audioData != nil
    }

    fileprivate func commitChanges() {
        if text.isEmpty {
            withAnimation {
                item.delete()
            }
            return
        }

        withAnimation {
            if item.children.isNotEmpty {
                for c in item.children.filter({ $0.text.isEmpty }) {
                    item._children.removeAll { $0.id == c.id }
                    modelContext.delete(c)
                }

                for c in item.children {
                    modelContext.insert(c)
                }
            }
            focus = nil
        }

        item.setText(text)
        item.setAudioData(audioData)

        withAnimation {
            item.setTimestamp(timestamp)
            item.setEvent(eventFormData)
            modelContext.insert(item)
        }
    }

    fileprivate func resetFocus() {
        withAnimation {
            highlight = nil
        }
        focus = nil
    }

    fileprivate func addChild() {
        let newChild = ItemStore.create(
            day: item.day,
            timestamp: timestamp,
            parent: item,
            position: item.children.count,
            taskData: item.taskData
        )

        withAnimation {
            item.appendChild(newChild)
        }
    }

    func addImages() {
        Task {
            if item.imageData?.isEmpty == false {
                item.deleteImageData()
            }

            var newImages: [ImageData] = []
            for item in imageItems {
                if
                    let data = try? await item
                        .loadTransferable(type: Data.self)
                {
                    newImages.append(ImageData(data))
                }
            }

            withAnimation {
                self.item.imageData = newImages
            }

            imageItems = []
        }
    }

    func formattedDate(_ date: Date) -> String {
        guard let eventFormData else {
            return ""
        }

        let calendar = Calendar.current
        if calendar.isDate(date, inSameDayAs: eventFormData.startDate) {
            return date.formatted(.dateTime.hour().minute())
        } else {
            let daysDifference = calendar.dateComponents(
                [.day],
                from: calendar.startOfDay(for: eventFormData.startDate),
                to: calendar.startOfDay(for: date)
            ).day ?? 0
            return date
                .formatted(.dateTime.hour().minute()) + "+\(daysDifference)"
        }
    }

    func deleteAudioData() {
        if let audioData {
            do {
                try FileManager.default.removeItem(at: audioData.url)
                print("File deleted: \(audioData.url)")
                withAnimation {
                    self.audioData = nil
                }
            } catch {
                print("Failed to delete file: \(error)")
                withAnimation {
                    self.audioData = nil
                }
            }
        }
    }

    func focusItem(_ i: Item) {
        if isHighlighted {
            focus = .item(id: i.id)
        } else {
            withAnimation {
                highlight = .item(id: self.item.id)
            }
        }
    }

    func unarchive(_ item: Item) {
        Task { @MainActor in
            guard let activeDate else { return }
            guard let day = DayStore.loadDay(by: activeDate)
            else { return }
            day.unarchive(item: item)
        }
    }

    func onEnterKey(_ item: Item) {
        if item.text.isEmpty || item._children.isEmpty {
            resetFocus()
            return
        }

        addChild()
    }

    @State var loaded: Bool = false
    @State var startDateString: String = ""
    @State var endDateString: String = ""

    struct TaskButton: View {
        @Bindable var item: Item

        var body: some View {
            ToolbarButton {
                withAnimation {
                    item.toggleTaskDataCompletedAt()
                }
            } label: {
                Image(
                    systemName: item.isTaskCompleted ? "square.fill" :
                        "square.dotted"
                )
            }
        }
    }

    struct TextRow: View {
        @Environment(\.modelContext) private var modelContext
        @Bindable var parent: Item
        @Bindable var item: Item
        @FocusState.Binding var focus: FocusedField?
        @State private var text: String
        @Binding var highlight: FocusedField?

        init(
            _ parent: Item,
            _ item: Item,
            focus: FocusState<FocusedField?>.Binding,
            highlight: Binding<FocusedField?>
        ) {
            _parent = Bindable(parent)
            _item = Bindable(item)
            _focus = focus
            _highlight = highlight
            text = item.text
        }

        var isFocused: Bool {
            focus == .item(id: item.id)
        }

        var isHighlighted: Bool {
            highlight == .item(id: item.id)
        }

        func onEnterKey(_ item: Item) {
            if text.isEmpty {
                focus = nil
                withAnimation {
                    highlight = nil
                }
                return
            }

            item.setText(text)

            let newChild = ItemStore.create(
                day: parent.day,
                timestamp: parent.timestamp,
                parent: parent,
                position: parent.children.count,
                taskData: parent.taskData
            )

            withAnimation {
                parent.appendChild(newChild)
            }
        }

        fileprivate func commitChanges() {
            // if text.isEmpty {
            //     withAnimation {
            //         item.delete()
            //     }
            //     return
            // }

            item.setText(text)
            // modelContext.insert(item)
        }

        var body: some View {
            TextField("...", text: $text, axis: .vertical)
                .focused($focus, equals: .item(id: item.id))
                .onChange(of: highlight) {
                    if text != item.text {
                        commitChanges()
                    }
                }
                .onEnterKey($text) {
                    onEnterKey(item)
                }
        }
    }

    @ViewBuilder
    var toolbar: some View {
        HStack(spacing: Spacing.m) {
            DateShelfButton(date: $timestamp) {
                ItemFormDateShelfView(
                    $eventFormData,
                    $timestamp
                )
            }

            BookShelfButton(
                book: $item.book,
                chapter: $item.chapter
            ) {
                ItemFormBookShelfView(
                    animation: animation,
                    book: $item.book,
                    chapter: $item.chapter
                )
            }

            ToolbarButton {
                focus = nil

                withAnimation {
                    highlight = nil
                }
            } label: {
                HStack {
                    Spacer()
                    Image(systemName: "chevron.up")
                    Spacer()
                }.contentShape(.rect)
            }

            if item.children.isEmpty {
                ToolbarButton {
                    let newChild = Item(parent: item)

                    withAnimation {
                        item._children.append(newChild)
                    }
                } label: {
                    Image(systemName: "text.justify.leading")
                }
            }

            ToolbarButton {
                withAnimation {
                    item.toggleTaskData()

                    for c in item.children {
                        c.taskData = item.taskData
                    }
                }
            } label: {
                Image(
                    systemName: item
                        .isTask ? "square.slash.fill" : "square.dotted"
                )
            }

            PhotosPicker(
                selection: $imageItems,
                matching: .images,
                photoLibrary: .shared()
            ) {
                Image(systemName: "photo")
            }
            .onChange(of: imageItems) {
                if imageItems.isNotEmpty {
                    addImages()
                }
            }

            ToolbarButton {
                if audioData == nil {
                    showRecordingShelf.toggle()
                } else {
                    deleteAudioData()
                }
            } label: {
                Image(
                    systemName: audioData == nil ? "microphone" :
                        "microphone.slash.fill"
                )
            }
            .sheet(isPresented: $showRecordingShelf) {
                AudioRecorderShelfView(audioData: $audioData)
            }
        }
        .inlineItemButtonStyle()
        .padding(.top, Spacing.m)
    }

    @ViewBuilder
    var content: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            HStack(spacing: Spacing.s * 1.5) {
                if item.isTask {
                    TaskButton(item: item)
                }

                TextField(
                    "...",
                    text: $text,
                    axis: .vertical
                )
                .parentItem()
                .focused($focus, equals: .item(id: item.id))
                .onAppear {
                    if text.isEmpty {
                        focus = .item(id: item.id)
                        withAnimation {
                            highlight = .item(id: item.id)
                        }
                    }
                }
                .onEnterKey($text) {
                    onEnterKey(item)
                }
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        if focus == .item(id: item.id) {
                            HStack {
                                ToolbarButton {
                                    resetFocus()
                                } label: {
                                    Image(
                                        systemName: "chevron.down"
                                    )
                                }
                                Spacer()
                            }
                        }
                    }
                }
                .allowsHitTesting(isHighlighted)

                Spacer()

                if let eventFormData {
                    VStack {
                        Text(startDateString)
                            .eventTimeFontStyle()
                        Text(endDateString)
                            .eventTimeFontStyle()
                    }
                    .task {
                        startDateString = formattedDate(
                            eventFormData
                                .startDate
                        )

                        endDateString = formattedDate(
                            eventFormData
                                .endDate
                        )
                    }
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                focusItem(item)
            }

            if item._children.isNotEmpty {
                ForEach($item._children, id: \.id) { $child in
                    HStack {
                        if child.isTask {
                            TaskButton(item: child)
                        }

                        TextRow(
                            item,
                            child,
                            focus: $focus,
                            highlight: $highlight
                        )
                        .childItem()
                        Spacer()
                    }
                    .contentShape(.rect(cornerRadius: 4))
                    .onAppear {
                        if child.text.isEmpty {
                            focus = .item(id: child.id)
                            highlight = .item(id: item.id)
                        }
                    }
                    .allowsHitTesting(isHighlighted)
                    .onTapGesture {
                        focusItem(child)
                    }
                    .toolbar {
                        ToolbarItemGroup(placement: .keyboard) {
                            if focus == .item(id: child.id) {
                                HStack {
                                    ToolbarButton { resetFocus() } label: {
                                        Image(
                                            systemName: "chevron.down"
                                        )
                                    }

                                    Spacer()
                                }
                            }
                        }
                    }
                    .contextMenu {
                        Button(
                            "Delete",
                            systemImage: "trash.fill"
                        ) {
                            withAnimation {
                                child.delete()
                            }
                        }

                        if !child.archived {
                            Button(
                                "Archive",
                                systemImage: "tray.and.arrow.down.fill"
                            ) {
                                withAnimation {
                                    item.archive(child)
                                    self.item._children
                                        .removeAll { $0.id == child.id }
                                }
                            }
                        }
                    }
                }
            }

            if
                item.imageData?.isNotEmpty == true,
                let imageDataArray = item.imageData
            {
                ImageRowView(
                    imageDataArray: imageDataArray,
                    animation: animation,
                    animationID: item.id
                )
            }

            if audioData != nil {
                AudioPlayerView(
                    audioData: $audioData,
                    itemID: item.id,
                    focus: $focus
                )
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        if focus == .audioData(id: item.id) {
                            HStack {
                                ToolbarButton { resetFocus() } label: {
                                    Image(
                                        systemName: "chevron.down"
                                    )
                                }

                                Spacer()
                            }
                        }
                    }
                }
            }
        }
    }

    @State private var isExpanded: Bool = false

    var body: some View {
        VStack {
            content
            if isHighlighted {
                toolbar
                    .transition(
                        .asymmetric(
                            insertion:
                            .move(edge: .top)
                                .animation(.snappy)
                                .combined(
                                    with: .opacity
                                        .animation(.snappy.delay(0.2))
                                ),
                            removal:
                            .move(edge: .top)
                                .animation(
                                    .snappy
                                )
                                .combined(
                                    with: .opacity
                                        .animation(.snappy.speed(1))
                                )
                        )
                    )
            }
        }
        .allowsHitTesting(isHighlighted)
        .onChange(of: isHighlighted) {
            withAnimation {
                isExpanded = isHighlighted
                if !isHighlighted {
                    commitChanges()
                }
            }
        }
        .contentShape(RoundedRectangle(cornerRadius: 4))
        .padding(Spacing.m)
        .background(bg)
        .opacity(
            isHighlighted || noHighlight ?
                1 :
                0.2
        )
        .onTapGesture {
            if !isHighlighted {
                withAnimation {
                    highlight = .item(id: item.id)
                }
            }
        }
        .sheet(isPresented: $showDateShelf) {
            ItemFormDateShelfView(
                $eventFormData,
                $timestamp
            )
        }
        .animation(.smooth, value: highlight)
        .transition(
            .move(edge: .top).combined(with: .scale(0.9, anchor: .bottom))
                .combined(with: .opacity)
        )
    }
}

struct Inline<Content: View>: View {
    var colorTint: Color
    var content: () -> Content

    var bgRect: some Shape {
        RoundedRectangle(cornerRadius: 4)
    }

    var bg: some View {
        bgRect
            .fill(.ultraThinMaterial)
            .overlay(
                bgRect
                    .fill(colorTint.gradient)
                    .opacity(0.4)
            )
    }

    var body: some View {
        VStack(spacing: Spacing.s * 1.5) {
            content()
        }
        .contentShape(RoundedRectangle(cornerRadius: 4))
        .padding(Spacing.m)
        .background(bg)
    }
}

import AudioKit
import AudioKitEX
import AudioKitUI
import AVFoundation

@Observable
class AudioRecorder {
    var audioData: AudioData?

    private var engine = AudioEngine()
    private var mic: AudioEngine.InputNode?
    private var recorder: NodeRecorder?
    private var file: AVAudioFile?
    private var mixer = Mixer()
    private var stopTimer: Timer?
    var onStop: (() -> Void)?

    init() {
        try? AVAudioSession.sharedInstance().setCategory(
            .ambient,
            options: [.mixWithOthers]
        )
    }

    func startRecording() {
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .playAndRecord,
                mode: .spokenAudio,
                options: [
                    .duckOthers,
                    .interruptSpokenAudioAndMixWithOthers,
                ]
            )
            try AVAudioSession.sharedInstance().setActive(true)

            mic = engine.input
            recorder = try NodeRecorder(node: mic!)
            try recorder?.record()
            engine.output = Fader(mic!, gain: 0)
            try engine.start()

            stopTimer = Timer.scheduledTimer(
                withTimeInterval: 120,
                repeats: false
            ) { _ in
                self.stopRecording()
            }
        } catch {
            print("Recording start error: \(error)")
        }
    }

    func stopRecording() {
        recorder?.stop()
        engine.stop()
        stopTimer?.invalidate()
        file = recorder?.audioFile
        saveAudioData()

        try? AVAudioSession.sharedInstance().setActive(
            false,
            options: .notifyOthersOnDeactivation
        )
        try? AVAudioSession.sharedInstance().setCategory(
            .ambient,
            options: [.mixWithOthers]
        )

        onStop?()
    }

    func cancelRecording() {
        recorder?.stop()
        engine.stop()
        stopTimer?.invalidate()
        try? AVAudioSession.sharedInstance().setActive(
            false,
            options: .notifyOthersOnDeactivation
        )
        try? AVAudioSession.sharedInstance().setCategory(
            .ambient,
            options: [.mixWithOthers]
        )
    }

    private func saveAudioData() {
        guard let fileURL = file?.url else { return }
        audioData = AudioData(url: fileURL)
    }
}

@Observable
class AudioPlayerManager {
    var isPlaying = false
    var isPaused = false

    private var engine = AudioEngine()
    var player = AudioPlayer()
    private var file: AVAudioFile?

    var onCompletion: (() -> Void)?

    init() {
        engine.output = player
        player.completionHandler = { [weak self] in
            self?.reset()
            self?.onCompletion?()
        }
    }

    func load(_ audioData: AudioData) {
        do {
            try? AVAudioSession.sharedInstance().setCategory(
                .playback,
                options: [.duckOthers, .mixWithOthers]
            )
            file = try AVAudioFile(forReading: audioData.url)
            try engine.start()
            player.file = file
        } catch {
            print("Loading error: \(error)")
        }
    }

    var loaded: Bool {
        player.file != nil
    }

    func play() {
        guard player.file != nil else { return }
        if !isPlaying {
            engine.stop()
            try? engine.start()
            player.play()
            isPlaying = true
            isPaused = false
        }
    }

    func pause() {
        if isPlaying {
            player.pause()
            isPlaying = false
            isPaused = true
        }
    }

    func reset() {
        player.stop()
        isPlaying = false
        isPaused = false
        player.seek(time: 0)
    }

    func seek(to time: Double) {
        player.seek(time: time)
    }

    var duration: Double {
        player.duration
    }

    var currentTime: Double {
        player.currentTime
    }
}

struct AudioRecorderView: View {
    @Environment(\.dismiss) var dismiss
    @State private var recorder = AudioRecorder()
    @Binding var audioData: AudioData?
    @Namespace var animation
    @State private var recording: Bool = false

    var body: some View {
        HStack {
            ToolbarButton {
                if recording {
                    recorder.stopRecording()
                    self.audioData = recorder.audioData
                    dismiss()
                    // startTranscription()
                } else {
                    recorder.startRecording()
                }

                withAnimation {
                    recording.toggle()
                }
            } label: {
                Image(
                    systemName: recording ? "stop.circle.fill" :
                        "circle.fill"
                )
                .resizable()
                .aspectRatio(1, contentMode: .fit)
                .frame(height: 60)
                .foregroundStyle(.red)
            }
        }
        .padding(Spacing.m)
        .onAppear {
            recorder.onStop = {
                self.audioData = recorder.audioData
                dismiss()
            }
        }
        .onDisappear {
            if recording {
                recorder.cancelRecording()
            }
        }
    }

    func startTranscription() {
        guard let audioURL = audioData?.url else { return }
        Task {
            convertAudioFileToPCMArray(fileURL: audioURL) { result in
                let modelURL = Bundle.main.url(
                    forResource: "tiny",
                    withExtension: "bin"
                )!
                let whisper = Whisper(fromFileURL: modelURL)
                switch result {
                    case let .success(success):
                        Task {
                            do {
                                let segments = try await whisper
                                    .transcribe(audioFrames: success)
                                let transcriptText = segments.map(\ .text)
                                    .joined()
                                DispatchQueue.main.async {
                                    self.audioData?.transcript = transcriptText
                                    self.audioData?.transcribed = true
                                }
                            } catch {
                                print("Transcription error: \(error)")
                            }
                        }
                    case let .failure(failure):
                        print("Conversion error: \(failure)")
                }
            }
        }
    }

    func convertAudioFileToPCMArray(
        fileURL: URL,
        completionHandler: @escaping (Result<[Float], Error>) -> Void
    ) {
        var options = FormatConverter.Options()
        options.format = .wav
        options.sampleRate = 16000
        options.bitDepth = 16
        options.channels = 1
        options.isInterleaved = false

        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(UUID().uuidString)
        let converter = FormatConverter(
            inputURL: fileURL,
            outputURL: tempURL,
            options: options
        )
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

struct ImageRowView: View {
    let imageDataArray: [ImageData]
    var animation: Namespace.ID
    var animationID: UUID

    @State var images: [ImageObject] = []
    @State var thumbnails: [ImageObject] = []

    struct ImageObject: Identifiable {
        let id: UUID = .init()
        let image: Image
    }

    @State var loaded = false
    var body: some View {
        NavigationLink {
            ScrollView(.horizontal) {
                HStack {
                    ForEach(images) { image in
                        image.image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .containerRelativeFrame(
                                .horizontal,
                                count: 1,
                                span: 1,
                                spacing: 0
                            )
                    }
                }.contentMargins(.horizontal, 10)
                    .scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned)
            .scrollIndicators(.hidden)
            .navigationTransition(.zoom(
                sourceID: "photos_" + animationID.description,
                in: animation
            ))
            .navigationBarBackButtonHidden()
        } label: {
            ScrollView(.horizontal) {
                HStack {
                    if loaded {
                        ForEach(thumbnails) { thumbnail in
                            thumbnail.image
                                .aspectRatio(contentMode: .fill)
                                .frame(
                                    width: Spacing.l,
                                    height: Spacing.l
                                )
                                .clipShape(
                                    .rect(cornerRadius: 5)
                                )
                        }
                    } else {
                        ProgressView()
                    }
                }
                .frame(height: Spacing.l)
                .padding(Spacing.xs)
            }
            .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
        .background(.ultraThinMaterial.opacity(0.4))
            .clipShape(.rect(cornerRadius: 4))
            .scrollIndicators(.hidden)
            .matchedTransitionSource(
                id: "photos_" + animationID.description,
                in: animation
            )
        }
        .task {
            thumbnails = imageDataArray
                .compactMap {
                    if let image = $0.loadThumbnail() {
                        return ImageObject(image: image)
                    }
                    return nil
                }

            images = imageDataArray
                .compactMap {
                    if let image = $0.loadImage() {
                        return ImageObject(image: image)
                    }
                    return nil
                }

            loaded = true
        }
    }

    struct ImageView: View {
        let imageData: ImageData
        @State private var image: Image =
            .init(systemName: "exclamationmark.triangle")

        @State private var loaded: Bool = false

        var body: some View {
            Group {
                if loaded {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .containerRelativeFrame(
                            .horizontal,
                            count: 1,
                            span: 1,
                            spacing: 0
                        )
                } else {
                    ProgressView()
                        .progressViewStyle(.circular)
                }
            }
            .task {
                if let image = imageData.loadImage() {
                    self.image = image
                }

                loaded = true
            }
        }
    }

    struct ThumbnailView: View {
        let imageData: ImageData
        @State private var thumbnail: Image =
            .init(systemName: "exclamationmark.triangle")

        @State private var loaded: Bool = false
        var body: some View {
            Group {
                if loaded {
                    thumbnail
                        .aspectRatio(contentMode: .fill)
                        .frame(
                            width: Spacing.l,
                            height: Spacing.l
                        )
                        .clipShape(
                            .rect(cornerRadius: 5)
                        )
                } else {
                    ProgressView()
                        .progressViewStyle(.circular)
                }
            }
            .task(priority: .low) {
                if let image = imageData.loadThumbnail() {
                    thumbnail = image
                }
                loaded = true
            }
        }
    }
}

struct AudioPlayerView: View {
    init(
        audioData: Binding<AudioData?>,
        itemID: UUID,
        focus: FocusState<FocusedField?>.Binding
    ) {
        _audioData = audioData
        _focus = focus
        self.itemID = itemID
        transcript = audioData.wrappedValue?.transcript ?? ""
    }

    let itemID: UUID
    @FocusState.Binding var focus: FocusedField?
    @Binding var audioData: AudioData?
    @State private var playerManager: AudioPlayerManager? = nil
    @State var transcript = ""
    @State var transcribing = false

    var body: some View {
        VStack(spacing: Spacing.m) {
            if audioData?.transcribed == true {
                TextField(
                    "transcript...",
                    text: $transcript,
                    axis: .vertical
                )
                .focused($focus, equals: .audioData(id: itemID))

                HStack {
                    playerControls()
                    Spacer()
                }
            } else {
                HStack {
                    playerControls()
                    Spacer()
                    transcribeControl()
                }
                .inlineItemButtonStyle()
            }
        }
        .padding(Spacing.m)
        .background(.ultraThinMaterial.opacity(0.4))
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }

    // MARK: - Player Controls

    @ViewBuilder
    private func playerControls() -> some View {
        if let manager = playerManager {
            HStack {
                ToolbarButton {
                    if manager.isPlaying {
                        manager.pause()
                    } else {
                        manager.play()
                    }
                } label: {
                    Image(
                        systemName: manager
                            .isPlaying ? "pause.circle.fill" : "play.fill"
                    )
                    // Text(formattedTime(manager.currentTime)).monospacedDigit()
                    // Text("/").monospacedDigit()
                }

                if manager.isPlaying || manager.isPaused {
                    ToolbarButton {
                        manager.reset()
                    } label: {
                        Image(systemName: "stop.fill")
                    }
                }

                Text(formattedTime(manager.duration)).monospacedDigit()
                Spacer()
            }.contentShape(.rect)
        } else {
            ToolbarButton {
                initializePlayerManagerAndPlay()
            } label: {
                Image(systemName: "play.fill")
            }
        }
    }

    // MARK: - Transcribe Control

    @ViewBuilder
    private func transcribeControl() -> some View {
        VStack {
            if transcribing {
                ProgressView()
                    .task {
                        if let audioData {
                            await extractTextFromAudio(audioData.url) { res in
                                switch res {
                                    case let .success(string):
                                        self.transcript = string
                                        self.audioData?.transcribed = true
                                        self.audioData?.transcript = string
                                    case let .failure(error):
                                        print(error.localizedDescription)
                                }
                                transcribing = false
                            }
                        }
                    }
            } else {
                ToolbarButton {
                    transcribing = true
                } label: {
                    Image(systemName: "text.viewfinder")
                }
            }
        }
    }

    // MARK: - Lazy Initialization

    private func initializePlayerManagerAndPlay() {
        guard let audioData else { return }
        let manager = AudioPlayerManager()
        manager.load(audioData)
        manager.onCompletion = { manager.reset() }
        manager.play()
        playerManager = manager
    }

    // MARK: - Helpers

    func formattedTime(_ time: Double) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    func extractTextFromAudio(
        _ audioURL: URL,
        completionHandler: @escaping (Result<String, Error>) -> Void
    ) async {
        let modelURL = Bundle.main.url(
            forResource: "tiny",
            withExtension: "bin"
        )!
        let whisper = Whisper(fromFileURL: modelURL)
        convertAudioFileToPCMArray(fileURL: audioURL) { result in
            switch result {
                case let .success(success):
                    Task {
                        do {
                            let segments = try await whisper
                                .transcribe(audioFrames: success)
                            completionHandler(.success(
                                segments.map(\.text)
                                    .joined()
                            ))
                        } catch {
                            completionHandler(.failure(error))
                        }
                    }
                case let .failure(failure):
                    completionHandler(.failure(failure))
            }
        }
    }

    func convertAudioFileToPCMArray(
        fileURL: URL,
        completionHandler: @escaping (Result<[Float], Error>) -> Void
    ) {
        var options = FormatConverter.Options()
        options.format = .wav
        options.sampleRate = 16000
        options.bitDepth = 16
        options.channels = 1
        options.isInterleaved = false

        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(UUID().uuidString)
        let converter = FormatConverter(
            inputURL: fileURL,
            outputURL: tempURL,
            options: options
        )
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

struct NoButtonDisclosureGroupStyle: DisclosureGroupStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            configuration.label
                .contentShape(Rectangle())

            if configuration.isExpanded {
                configuration.content
                    .transition(
                        .asymmetric(
                            insertion:
                            .move(edge: .top)
                                .animation(.snappy)
                                .combined(
                                    with: .opacity
                                        .animation(.snappy.delay(0.2))
                                ),
                            removal:
                            .move(edge: .top)
                                .animation(
                                    .snappy.delay(0.1)
                                )
                                .combined(
                                    with: .opacity
                                        .animation(.snappy.speed(2))
                                )
                        )
                    )
            }
        }
    }
}
