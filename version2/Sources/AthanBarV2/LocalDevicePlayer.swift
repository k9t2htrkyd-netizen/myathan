import AudioToolbox
import AVFoundation
import CoreAudio
import Foundation

/// Plays a file on one or more Core Audio output devices without changing
/// the Mac's system default speaker.
final class LocalDevicePlayer {
    var onAllFinished: (() -> Void)?

    private var engines: [AudioDeviceID: AVAudioEngine] = [:]
    private var players: [AudioDeviceID: AVAudioPlayerNode] = [:]
    private var pending = 0
    private let lock = NSLock()

    var isPlaying: Bool {
        lock.lock()
        defer { lock.unlock() }
        return pending > 0
    }

    func stop() {
        lock.lock()
        pending = 0
        let running = Array(zip(engines.values, players.values))
        engines.removeAll()
        players.removeAll()
        lock.unlock()

        for (engine, player) in running {
            player.stop()
            engine.stop()
            engine.reset()
        }
    }

    func setVolume(_ volume: Float) {
        lock.lock()
        let list = Array(engines.values)
        lock.unlock()
        for engine in list {
            engine.mainMixerNode.outputVolume = volume
        }
    }

    func play(fileURL: URL, devices: [SystemAudioDevice], volume: Float) throws {
        stop()
        guard !devices.isEmpty else { return }

        let file = try AVAudioFile(forReading: fileURL)
        var started: [SystemAudioDevice] = []

        for device in devices {
            do {
                try start(file: file, fileURL: fileURL, device: device, volume: volume)
                started.append(device)
            } catch {
                print("Could not route to \(device.name): \(error)")
            }
        }

        lock.lock()
        pending = started.count
        lock.unlock()

        if started.isEmpty {
            throw CastError.loadFailed("Could not route audio to the selected Mac/Bluetooth speakers.")
        }
    }

    private func start(file: AVAudioFile, fileURL: URL, device: SystemAudioDevice, volume: Float) throws {
        let engine = AVAudioEngine()
        let player = AVAudioPlayerNode()
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: file.processingFormat)
        engine.mainMixerNode.outputVolume = volume

        engine.prepare()
        try route(engine, to: device.id)
        try engine.start()

        // Each engine needs its own file handle; AVAudioFile is not shared-safe.
        let scheduled = try AVAudioFile(forReading: fileURL)
        player.scheduleFile(scheduled, at: nil) { [weak self] in
            DispatchQueue.main.async {
                self?.noteFinished()
            }
        }
        player.play()

        lock.lock()
        engines[device.id] = engine
        players[device.id] = player
        lock.unlock()
    }

    private func route(_ engine: AVAudioEngine, to deviceID: AudioDeviceID) throws {
        guard let audioUnit = engine.outputNode.audioUnit else {
            throw CastError.loadFailed("No audio output unit.")
        }
        var id = deviceID
        let status = AudioUnitSetProperty(
            audioUnit,
            kAudioOutputUnitProperty_CurrentDevice,
            kAudioUnitScope_Global,
            0,
            &id,
            UInt32(MemoryLayout<AudioDeviceID>.size)
        )
        guard status == noErr else {
            throw CastError.loadFailed("Audio route failed (\(status)).")
        }
    }

    private func noteFinished() {
        lock.lock()
        pending = max(0, pending - 1)
        let done = pending == 0
        lock.unlock()
        if done {
            onAllFinished?()
        }
    }
}
