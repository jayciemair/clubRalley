//
//  AudioService.swift
//  Club Ralley
//
//  Service for audio playback (meditations, lessons, etc.)
//

import Foundation
import AVFoundation
import SwiftUI

@MainActor
class AudioService: NSObject, ObservableObject {

    // MARK: - Singleton

    static let shared = AudioService()

    // MARK: - Published Properties

    @Published var isPlaying = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var isLoading = false
    @Published var error: Error?

    // MARK: - Computed Properties

    var progress: Double {
        guard duration > 0 else { return 0 }
        return currentTime / duration
    }

    var formattedCurrentTime: String {
        formatTime(currentTime)
    }

    var formattedDuration: String {
        formatTime(duration)
    }

    var formattedRemainingTime: String {
        formatTime(duration - currentTime)
    }

    // MARK: - Private Properties

    private var audioPlayer: AVAudioPlayer?
    private var progressTimer: Timer?
    private var audioSession: AVAudioSession?

    // MARK: - Initialization

    private override init() {
        super.init()
        setupAudioSession()
    }

    // MARK: - Audio Session Setup

    private func setupAudioSession() {
        do {
            audioSession = AVAudioSession.sharedInstance()
            try audioSession?.setCategory(.playback, mode: .default, options: [.allowAirPlay, .allowBluetooth])
            try audioSession?.setActive(true)
            print("AudioService: Audio session configured for playback")
        } catch {
            print("AudioService: Failed to configure audio session: \(error)")
            self.error = error
        }
    }

    // MARK: - Load Audio

    /// Load audio from a local file
    func loadFromFile(named fileName: String, extension ext: String = "mp3") {
        isLoading = true
        error = nil

        guard let url = Bundle.main.url(forResource: fileName, withExtension: ext) else {
            isLoading = false
            error = AudioError.fileNotFound
            print("AudioService: Audio file not found: \(fileName).\(ext)")
            return
        }

        loadFromURL(url)
    }

    /// Load audio from a URL
    func loadFromURL(_ url: URL) {
        isLoading = true
        error = nil

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()

            duration = audioPlayer?.duration ?? 0
            currentTime = 0
            isPlaying = false
            isLoading = false

            print("AudioService: Loaded audio, duration: \(duration) seconds")
        } catch {
            isLoading = false
            self.error = error
            print("AudioService: Failed to load audio: \(error)")
        }
    }

    /// Load audio from remote URL (downloads first)
    func loadFromRemoteURL(_ url: URL) async {
        isLoading = true
        error = nil

        do {
            let (localURL, _) = try await URLSession.shared.download(from: url)
            await MainActor.run {
                loadFromURL(localURL)
            }
        } catch {
            await MainActor.run {
                isLoading = false
                self.error = error
                print("AudioService: Failed to download audio: \(error)")
            }
        }
    }

    // MARK: - Playback Controls

    /// Play or resume audio
    func play() {
        guard let player = audioPlayer else {
            print("AudioService: No audio loaded")
            return
        }

        do {
            try audioSession?.setActive(true)
        } catch {
            print("AudioService: Failed to activate audio session: \(error)")
        }

        player.play()
        isPlaying = true
        startProgressTimer()
        print("AudioService: Playing")
    }

    /// Pause audio
    func pause() {
        audioPlayer?.pause()
        isPlaying = false
        stopProgressTimer()
        print("AudioService: Paused")
    }

    /// Toggle play/pause
    func togglePlayPause() {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }

    /// Stop audio and reset to beginning
    func stop() {
        audioPlayer?.stop()
        audioPlayer?.currentTime = 0
        currentTime = 0
        isPlaying = false
        stopProgressTimer()
        print("AudioService: Stopped")
    }

    /// Seek to a specific time
    func seek(to time: TimeInterval) {
        audioPlayer?.currentTime = max(0, min(time, duration))
        currentTime = audioPlayer?.currentTime ?? 0
    }

    /// Seek to a percentage (0.0 - 1.0)
    func seek(toProgress progress: Double) {
        let time = duration * max(0, min(progress, 1.0))
        seek(to: time)
    }

    /// Skip forward by seconds
    func skipForward(seconds: TimeInterval = 15) {
        let newTime = currentTime + seconds
        seek(to: min(newTime, duration))
    }

    /// Skip backward by seconds
    func skipBackward(seconds: TimeInterval = 15) {
        let newTime = currentTime - seconds
        seek(to: max(newTime, 0))
    }

    // MARK: - Progress Timer

    private func startProgressTimer() {
        stopProgressTimer()
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateProgress()
            }
        }
    }

    private func stopProgressTimer() {
        progressTimer?.invalidate()
        progressTimer = nil
    }

    private func updateProgress() {
        currentTime = audioPlayer?.currentTime ?? 0
    }

    // MARK: - Helpers

    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    // MARK: - Cleanup

    func cleanup() {
        stop()
        audioPlayer = nil
        try? audioSession?.setActive(false)
    }

    deinit {
        audioPlayer?.stop()
        audioPlayer = nil
        progressTimer?.invalidate()
        progressTimer = nil
        try? audioSession?.setActive(false)
    }
}

// MARK: - AVAudioPlayerDelegate

extension AudioService: AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            isPlaying = false
            stopProgressTimer()
            currentTime = duration
            print("AudioService: Playback finished")
        }
    }

    nonisolated func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: (any Error)?) {
        Task { @MainActor in
            isPlaying = false
            stopProgressTimer()
            self.error = error
            print("AudioService: Decode error: \(error?.localizedDescription ?? "unknown")")
        }
    }
}

// MARK: - Audio Errors

enum AudioError: LocalizedError {
    case fileNotFound
    case playbackFailed
    case sessionError

    var errorDescription: String? {
        switch self {
        case .fileNotFound:
            return "Audio file not found"
        case .playbackFailed:
            return "Failed to play audio"
        case .sessionError:
            return "Audio session error"
        }
    }
}
