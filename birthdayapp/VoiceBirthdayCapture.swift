//
//  VoiceBirthdayCapture.swift
//  birthdayapp
//

import AVFoundation
import Combine
import Foundation
import Speech

@MainActor
final class VoiceBirthdayCapture: NSObject, ObservableObject {
    @Published var transcript = ""
    @Published var isRecording = false
    @Published var errorMessage: String?

    private let audioEngine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: Locale.preferredLanguages.first ?? "en-US"))

    /// Set while `stopRecordingAndFinalizeTranscript()` is waiting for a final `SFSpeech` result.
    private var awaitingStopContinuation: CheckedContinuation<Void, Never>?
    private var finalizeTimeoutTask: Task<Void, Never>?

    func requestPermissions() async -> Bool {
        let speech = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { continuation.resume(returning: $0) }
        }
        guard speech == .authorized else {
            errorMessage = "Speech recognition isn’t allowed. You can enable it in Settings."
            return false
        }

        let mic = await AVAudioApplication.requestRecordPermission()
        guard mic else {
            errorMessage = "Microphone access is needed for voice entry."
            return false
        }
        return true
    }

    func startRecording() async {
        errorMessage = nil
        transcript = ""

        guard await requestPermissions() else { return }
        guard let recognizer, recognizer.isAvailable else {
            errorMessage = "Speech recognition isn’t available right now."
            return
        }

        cancelFinalizeTimeout()
        resumeAwaitingStopIfNeeded()
        tearDownRecognitionSilently()
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)

        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            errorMessage = "Couldn’t set up audio."
            return
        }

        request = SFSpeechAudioBufferRecognitionRequest()
        guard let request else { return }
        request.shouldReportPartialResults = true

        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)

        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            self?.request?.append(buffer)
        }

        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            errorMessage = "Couldn’t start recording."
            return
        }

        isRecording = true

        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            Task { @MainActor in
                guard let self else { return }
                if let result {
                    self.transcript = result.bestTranscription.formattedString
                }
                if error != nil || result?.isFinal == true {
                    self.onRecognitionEnded()
                }
            }
        }
    }

    /// Ends capture and waits until Speech delivers a **final** transcript (or times out). Call this before parsing so short phrases like “add Sonia” are not lost to an immediate `cancel()`.
    func stopRecordingAndFinalizeTranscript() async {
        cancelFinalizeTimeout()

        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        request?.endAudio()
        isRecording = false

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            awaitingStopContinuation = continuation
            scheduleFinalizeTimeout()
        }

        cancelFinalizeTimeout()
    }

    private func scheduleFinalizeTimeout() {
        cancelFinalizeTimeout()
        finalizeTimeoutTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(2.5))
            guard !Task.isCancelled else { return }
            guard self.awaitingStopContinuation != nil else { return }
            self.onRecognitionEnded()
        }
    }

    private func cancelFinalizeTimeout() {
        finalizeTimeoutTask?.cancel()
        finalizeTimeoutTask = nil
    }

    private func onRecognitionEnded() {
        cancelFinalizeTimeout()

        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        isRecording = false

        if let continuation = awaitingStopContinuation {
            awaitingStopContinuation = nil
            continuation.resume()
        }

        tearDownRecognitionSilently()
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    private func resumeAwaitingStopIfNeeded() {
        if let continuation = awaitingStopContinuation {
            awaitingStopContinuation = nil
            continuation.resume()
        }
    }

    private func tearDownRecognitionSilently() {
        request = nil
        recognitionTask?.cancel()
        recognitionTask = nil
    }
}
