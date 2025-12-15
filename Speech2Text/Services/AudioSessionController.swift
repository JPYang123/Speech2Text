//
//  AudioSessionController.swift
//  Speech2Text
//
//  Created by Jiping Yang on 12/14/25.
//

import AVFoundation

/// Lightweight centralized audio session configuration.
/// (You can expand this later to handle interruptions / route changes.)
final class AudioSessionController {
    static let shared = AudioSessionController()

    private let session: AVAudioSession

    private init(session: AVAudioSession = .sharedInstance()) {
        self.session = session
    }

    func configureForRecording() throws {
        try session.setCategory(
            .playAndRecord,
            mode: .measurement,
            options: [.defaultToSpeaker, .allowBluetooth]
        )
        try session.setActive(true, options: .notifyOthersOnDeactivation)
    }

    func configureForPlayback() throws {
        try session.setCategory(.playback, mode: .default, options: [])
        try session.setActive(true, options: .notifyOthersOnDeactivation)
    }

    func deactivate() throws {
        try session.setActive(false, options: .notifyOthersOnDeactivation)
    }
}
