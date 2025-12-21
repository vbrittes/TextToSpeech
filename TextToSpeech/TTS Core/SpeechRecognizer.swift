//
//  SpeechRecognizer.swift
//  TextToSpeech
//
//  Created by Victor Brittes on 16/12/25.
//

import Foundation
import Speech
import AVFoundation
import Combine
import Accelerate

public enum SpeechRecognizerError: LocalizedError {
    case speechPermissionDenied
    case microphonePermissionDenied
    case recognizerUnavailable
    case alreadyRunning
    case audioSessionSetupFailed(underlying: Error)
    case audioEngineStartFailed(underlying: Error)

    public var errorDescription: String? {
        switch self {
        case .speechPermissionDenied:
            return "Speech recognition permission denied."
        case .microphonePermissionDenied:
            return "Microphone permission denied."
        case .recognizerUnavailable:
            return "Speech recognizer is unavailable."
        case .alreadyRunning:
            return "Speech recognition is already running."
        case .audioSessionSetupFailed(let err):
            return "Failed to configure audio session: \(err.localizedDescription)"
        case .audioEngineStartFailed(let err):
            return "Failed to start audio engine: \(err.localizedDescription)"
        }
    }
}

@MainActor
public final class SpeechRecognizer: NSObject, ObservableObject {

    public enum State: Equatable {
        case idle
        case listening
        case stopped
        case denied
        case failed(message: String)
    }

    public enum MicrophonePermission: Equatable {
        case undetermined
        case denied
        case restricted
        case granted
    }

    // MARK: - Observable state

    @Published private(set) var noiseLevel: Float = -1000.0
    @Published private(set) var state: State = .idle
    @Published private(set) var transcript: String = ""
    @Published private(set) var isAvailable: Bool = true

    @Published private(set) var speechAuthStatus: SFSpeechRecognizerAuthorizationStatus =
        SFSpeechRecognizer.authorizationStatus()

    /// Unified mic permission state (no deprecated AVAudioSession.recordPermission usage).
    @Published private(set) var micPermission: MicrophonePermission = .undetermined

    // MARK: - Internals

    private var recognizer: SFSpeechRecognizer?
    private let resources = Resources()

    @MainActor
    public override init() {
        super.init()
        configure(locale: Locale.current)
        micPermission = currentMicrophonePermission()
    }

    public init(locale: Locale) {
        super.init()
        configure(locale: locale)
        micPermission = currentMicrophonePermission()
    }

    // MARK: - Configuration

    public func configure(locale: Locale) {
        let r = SFSpeechRecognizer(locale: locale)
        r?.delegate = self
        recognizer = r
        isAvailable = r?.isAvailable ?? true
    }

    // MARK: - Permissions

    /// Requests both Speech + Microphone permissions.
    /// Returns true only if both are granted.
    public func requestPermissions() async -> Bool {
        let speech = await requestSpeechAuthorization()
        speechAuthStatus = speech
        guard speech == .authorized else { return false }

        let micGranted = await requestMicrophonePermission()
        micPermission = currentMicrophonePermission()
        return micGranted
    }

    public func requestSpeechAuthorization() async -> SFSpeechRecognizerAuthorizationStatus {
        await withCheckedContinuation { cont in
            SFSpeechRecognizer.requestAuthorization { status in
                cont.resume(returning: status)
            }
        }
    }

    /// iOS 17+: AVAudioApplication.requestRecordPermission
    /// iOS < 17: AVCaptureDevice.requestAccess(for: .audio)
    public func requestMicrophonePermission() async -> Bool {
        if #available(iOS 17.0, *) {
            return await withCheckedContinuation { cont in
                AVAudioApplication.requestRecordPermission { granted in
                    cont.resume(returning: granted)
                }
            }
        } else {
            return await withCheckedContinuation { cont in
                AVCaptureDevice.requestAccess(for: .audio) { granted in
                    cont.resume(returning: granted)
                }
            }
        }
    }

    private func currentMicrophonePermission() -> MicrophonePermission {
        if #available(iOS 17.0, *) {
            // AVAudioApplication.shared.recordPermission (recommended in iOS 17+) :contentReference[oaicite:2]{index=2}
            switch AVAudioApplication.shared.recordPermission {
            case .undetermined: return .undetermined
            case .denied:       return .denied
            case .granted:      return .granted
            @unknown default:   return .denied
            }
        } else {
            // Fallback without using deprecated AVAudioSession.recordPermission :contentReference[oaicite:3]{index=3}
            switch AVCaptureDevice.authorizationStatus(for: .audio) {
            case .notDetermined: return .undetermined
            case .denied:        return .denied
            case .restricted:    return .restricted
            case .authorized:    return .granted
            @unknown default:    return .denied
            }
        }
    }

    // MARK: - Public API

    /// Starts live transcription.
    /// - Parameters:
    ///   - requiresOnDevice: Request on-device recognition when supported (iOS 13+).
    ///   - partialResults: If true, you’ll get interim updates before the final result.
    public func startListening(requiresOnDevice: Bool = false, partialResults: Bool = true) async throws {
        guard state != .listening else { throw SpeechRecognizerError.alreadyRunning }

        transcript = ""
        state = .idle

        // Speech permission
        let speech = (speechAuthStatus == .authorized) ? speechAuthStatus : await requestSpeechAuthorization()
        speechAuthStatus = speech
        guard speech == .authorized else {
            state = .denied
            throw SpeechRecognizerError.speechPermissionDenied
        }

        // Mic permission
        let micGranted = await requestMicrophonePermission()
        micPermission = currentMicrophonePermission()
        guard micGranted else {
            state = .denied
            throw SpeechRecognizerError.microphonePermissionDenied
        }

        guard let recognizer, recognizer.isAvailable else {
            throw SpeechRecognizerError.recognizerUnavailable
        }

        // Stop any previous run
        stop()

        // Audio session for recognition
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.record, mode: .measurement, options: [.duckOthers])
            try session.setActive(true, options: [.notifyOthersOnDeactivation])
        } catch {
            state = .failed(message: error.localizedDescription)
            throw SpeechRecognizerError.audioSessionSetupFailed(underlying: error)
        }

        // Build engine + request
        let engine = AVAudioEngine()
        let input = engine.inputNode

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = partialResults
        if #available(iOS 13.0, *) {
            request.requiresOnDeviceRecognition = requiresOnDevice
        }

        // Swift 6: tap closure may be treated as @Sendable; request isn't Sendable => box it.
        final class RequestBox: @unchecked Sendable {
            let request: SFSpeechAudioBufferRecognitionRequest
            init(_ request: SFSpeechAudioBufferRecognitionRequest) { self.request = request }
        }
        let box = RequestBox(request)

        let format = input.outputFormat(forBus: 0)
        input.removeTap(onBus: 0)
        input.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            box.request.append(buffer)
            
            // Compute an approximate input "loudness" from the audio buffer.
            // 1) Extract the first channel's float data (mono or first channel in stereo/multichannel).
            // 2) Use Accelerate's vDSP to compute RMS (root-mean-square) amplitude over the current buffer frames.
            // 3) Convert RMS to decibels relative to full scale (dBFS) via 20 * log10(rms).
            //    Note: This is a rough indicator of input level, not a calibrated SPL in dB.
            // 4) Clamp to a floor value when rms == 0 to avoid -inf and provide a stable floor.
            if let ch = buffer.floatChannelData?.pointee {
                // Number of frames (samples per channel) in this buffer slice
                let n = Int(buffer.frameLength)

                // RMS amplitude of the channel samples in the current buffer window
                var rms: Float = 0
                vDSP_rmsqv(ch, 1, &rms, vDSP_Length(n))

                // Convert amplitude to decibels (dBFS). If rms is zero, use a low floor to avoid -infinity.
                let db = rms > 0 ? 20 * log10f(rms) : -160

                // Publish the current noise level for UI/visualization (e.g., level meter)
                self?.noiseLevel = db
            }
        }

        engine.prepare()
        do {
            try engine.start()
        } catch {
            state = .failed(message: error.localizedDescription)
            throw SpeechRecognizerError.audioEngineStartFailed(underlying: error)
        }

        let task = recognizer.recognitionTask(with: request) { [weak self] result, error in
            let text = result?.bestTranscription.formattedString
            let isFinal = result?.isFinal ?? false
            let errorMessage = error?.localizedDescription

            Task { @MainActor in
                guard let self else { return }

                if let errorMessage {
                    self.state = .failed(message: errorMessage)
                    self.stop()
                    return
                }

                if let text, !text.isEmpty {
                    self.transcript = text
                }

                if isFinal {
                    self.state = .stopped
                    self.stop()
                }
            }
        }

        resources.set(engine: engine, request: request, task: task)
        state = .listening
    }

    /// Stops listening (safe to call multiple times).
    public func stop() {
        resources.teardown()
        try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])

        if state == .listening {
            state = .stopped
        }
    }

    public func reset() {
        transcript = ""
        state = .idle
    }
}

// MARK: - SFSpeechRecognizerDelegate

extension SpeechRecognizer: SFSpeechRecognizerDelegate {
    public nonisolated func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        Task { @MainActor in
            self.isAvailable = available
        }
    }
}

// MARK: - Resources

private final class Resources {
    private var engine: AVAudioEngine?
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?

    func set(engine: AVAudioEngine, request: SFSpeechAudioBufferRecognitionRequest, task: SFSpeechRecognitionTask) {
        self.engine = engine
        self.request = request
        self.task = task
    }

    func teardown() {
        if let engine {
            engine.stop()
            engine.inputNode.removeTap(onBus: 0)
        }

        request?.endAudio()
        task?.cancel()

        task = nil
        request = nil
        engine = nil
    }

    deinit {
        teardown()
    }
}
