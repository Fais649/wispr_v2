//
//  Audio.swift
//  wispr
//
//  Created by Faisal Alalaiwat on 21.03.25.
//
import AppIntents
import AudioKit
import AVFoundation
import EventKit
import EventKitUI
import Foundation
import SwiftData
import SwiftUI
import SwiftWhisper

class AudioPlayer {
    var audioSession: AVAudioSession
    var audioPlayer: AVAudioPlayer?

    init(url: URL) {
        let audioSession = AVAudioSession.sharedInstance()
        try? audioSession.setCategory(.playback, mode: .spokenAudio)
        try? audioSession
            .overrideOutputAudioPort(AVAudioSession.PortOverride.speaker)
        try? audioSession.setActive(true)

        self.audioSession = audioSession
        audioPlayer = try? AVAudioPlayer(contentsOf: url)
    }
}

@Observable
class AudioHardwareService {
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
            try? audioSession
                .overrideOutputAudioPort(AVAudioSession.PortOverride.speaker)
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
        let recordingSettings: [String: Any] = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
        ]
        recordedURL = audioFilename
        audioRecorder = try AVAudioRecorder(
            url: audioFilename,
            settings: recordingSettings
        )
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

    func extractTextFromAudio(
        _ audioURL: URL,
        completionHandler: @escaping (Result<String, Error>) -> Void
    ) {
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
