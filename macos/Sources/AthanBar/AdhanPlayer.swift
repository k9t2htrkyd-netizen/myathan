import AVFoundation
import Foundation

@MainActor
final class AdhanPlayer: ObservableObject {
    @Published var isArmed = false
    @Published var isPlaying = false
    @Published var statusLine = "Audio: off"

    private var player: AVAudioPlayer?
    private var lastPlayedKey: String?
    private var watchTimer: Timer?
    private weak var prayerService: PrayerService?

    func attach(prayerService: PrayerService) {
        self.prayerService = prayerService
        watchTimer?.invalidate()
        watchTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.checkSchedule() }
        }
        RunLoop.main.add(watchTimer!, forMode: .common)
    }

    func toggleArmed() {
        if isArmed {
            disarm()
        } else {
            arm()
        }
    }

    func arm() {
        guard preparePlayer() else {
            statusLine = "Audio: missing file"
            return
        }
        // Unlock audio session with a silent prime (paused).
        player?.prepareToPlay()
        isArmed = true
        statusLine = "Audio: on"
    }

    func disarm() {
        isArmed = false
        player?.stop()
        isPlaying = false
        statusLine = "Audio: off"
    }

    func playNow() {
        guard preparePlayer() else { return }
        player?.currentTime = 0
        isPlaying = player?.play() ?? false
        if isPlaying {
            statusLine = "Audio: playing"
        }
    }

    private func preparePlayer() -> Bool {
        if player != nil { return true }
        guard let url = Bundle.module.url(forResource: "athan-amman-jordan", withExtension: "mp3") else {
            print("Missing athan-amman-jordan.mp3 in bundle")
            return false
        }
        do {
            let audio = try AVAudioPlayer(contentsOf: url)
            audio.prepareToPlay()
            audio.delegate = PlayerDelegate.shared
            PlayerDelegate.shared.onFinish = { [weak self] in
                Task { @MainActor in
                    self?.isPlaying = false
                    self?.statusLine = self?.isArmed == true ? "Audio: on" : "Audio: off"
                }
            }
            player = audio
            return true
        } catch {
            print("Audio load failed: \(error)")
            return false
        }
    }

    private func checkSchedule() {
        guard isArmed, let prayer = prayerService?.currentAdhanPrayerIfDue() else { return }
        let key = "\(prayerService?.day?.gregorian ?? "")-\(prayer.id)"
        if lastPlayedKey == key { return }
        lastPlayedKey = key
        playNow()
        statusLine = "Audio: \(prayer.name)"
    }
}

private final class PlayerDelegate: NSObject, AVAudioPlayerDelegate {
    static let shared = PlayerDelegate()
    var onFinish: (() -> Void)?

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        onFinish?()
    }
}
