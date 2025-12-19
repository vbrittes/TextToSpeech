//
//  RecorderNoiseMeter.swift
//  TextToSpeech
//
//  Created by Victor Brittes on 15/12/25.
//

import Foundation
import Combine
import AVFAudio

final class RecorderNoiseMeter: ObservableObject {
    private var recorder: AVAudioRecorder?
    private var timer: Timer?

    var power: CGFloat = 0

    func start() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker]) // measurement reduces processing :contentReference[oaicite:1]{index=1}
        try session.setActive(true)

        let url = URL(fileURLWithPath: "/dev/null")
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatAppleLossless),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.min.rawValue
        ]

        let r = try AVAudioRecorder(url: url, settings: settings)
        r.isMeteringEnabled = true // :contentReference[oaicite:2]{index=2}
        r.record()

        recorder = r

        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            guard let self, let r = self.recorder else { return }
            r.updateMeters() // :contentReference[oaicite:3]{index=3}
//            let db = r.averagePower(forChannel: 0) // dBFS :contentReference[oaicite:4]{index=4}
            let db = r.peakPower(forChannel: 0) // dBFS :contentReference[oaicite:4]{index=4}
            power = CGFloat(db)
            print(power)
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        recorder?.stop()
        recorder = nil
        try? AVAudioSession.sharedInstance().setActive(false)
    }
}
