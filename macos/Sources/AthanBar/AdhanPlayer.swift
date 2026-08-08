import AVFoundation
import Foundation

@MainActor
final class AdhanPlayer: ObservableObject {
    @Published var isArmed = false
    @Published var isPlaying = false
    @Published var statusLine = "Audio: off"
    @Published var volume: Float = 0.85 {
        didSet {
            player?.volume = volume
            alarmPlayer?.volume = volume
            UserDefaults.standard.set(volume, forKey: "adhanVolume")
        }
    }
    @Published var secondaryAlerts: [String: SecondaryAlertConfig] = SecondaryAlertDefaults.values

    private var player: AVAudioPlayer?
    private var alarmPlayer: AVAudioPlayer?
    private var lastPlayedKey: String?
    private var watchTimer: Timer?
    private weak var prayerService: PrayerService?

    init() {
        let saved = UserDefaults.standard.object(forKey: "adhanVolume") as? Float
        volume = saved ?? 0.85
        loadSecondaryAlerts()
    }

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
        Task { @MainActor in
            _ = await prepareAlarmPlayer(soundId: AlarmSound.all[0].id)
        }
        player?.prepareToPlay()
        isArmed = true
        statusLine = "Audio: on"
    }

    func disarm() {
        isArmed = false
        stopAndReset()
        statusLine = "Audio: off"
    }

    func playNow() {
        guard preparePlayer() else { return }
        alarmPlayer?.stop()
        player?.volume = volume
        player?.currentTime = 0
        isPlaying = player?.play() ?? false
        if isPlaying {
            statusLine = "Audio: playing"
        }
    }

    func playAlarmPreview(soundId: String) {
        statusLine = "Audio: loading…"
        Task { @MainActor in
            guard await prepareAlarmPlayer(soundId: soundId) else {
                statusLine = "Audio: alarm missing"
                return
            }
            player?.stop()
            alarmPlayer?.volume = volume
            alarmPlayer?.currentTime = 0
            isPlaying = alarmPlayer?.play() ?? false
            if isPlaying {
                statusLine = "Audio: alarm preview"
            }
        }
    }

    /// Stop playback and rewind to the beginning.
    func stopAndReset() {
        player?.stop()
        player?.currentTime = 0
        player?.prepareToPlay()
        alarmPlayer?.stop()
        alarmPlayer?.currentTime = 0
        isPlaying = false
        statusLine = isArmed ? "Audio: on" : "Audio: off"
    }

    func setSecondaryEnabled(_ key: String, enabled: Bool) {
        var next = secondaryAlerts
        var cfg = next[key] ?? SecondaryAlertDefaults.values[key]!
        cfg.enabled = enabled
        next[key] = cfg
        secondaryAlerts = next
        saveSecondaryAlerts()
    }

    func setSecondarySound(_ key: String, soundId: String) {
        var next = secondaryAlerts
        var cfg = next[key] ?? SecondaryAlertDefaults.values[key]!
        cfg.soundId = soundId
        next[key] = cfg
        secondaryAlerts = next
        saveSecondaryAlerts()
    }

    private func loadSecondaryAlerts() {
        guard let data = UserDefaults.standard.data(forKey: "secondaryAlerts"),
              let decoded = try? JSONDecoder().decode([String: SecondaryAlertConfig].self, from: data)
        else { return }
        secondaryAlerts = SecondaryAlertDefaults.values.merging(decoded) { _, new in new }
    }

    private func saveSecondaryAlerts() {
        if let data = try? JSONEncoder().encode(secondaryAlerts) {
            UserDefaults.standard.set(data, forKey: "secondaryAlerts")
        }
    }

    private func preparePlayer() -> Bool {
        if let player {
            player.volume = volume
            return true
        }
        guard let url = Bundle.module.url(forResource: "athan-amman-jordan", withExtension: "mp3") else {
            print("Missing athan-amman-jordan.mp3 in bundle")
            return false
        }
        do {
            let audio = try AVAudioPlayer(contentsOf: url)
            audio.volume = volume
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

    private func prepareAlarmPlayer(soundId: String) async -> Bool {
        let sound = AlarmSound.all.first(where: { $0.id == soundId }) ?? AlarmSound.all[0]
        do {
            let audio: AVAudioPlayer
            if let remote = sound.remoteURL, let remoteURL = URL(string: remote) {
                let (data, _) = try await URLSession.shared.data(from: remoteURL)
                audio = try AVAudioPlayer(data: data)
            } else if let fileName = sound.fileName,
                      let url = Bundle.module.url(forResource: fileName, withExtension: "mp3", subdirectory: "alarms")
                        ?? Bundle.module.url(forResource: fileName, withExtension: "mp3") {
                audio = try AVAudioPlayer(contentsOf: url)
            } else {
                print("Missing alarm sound \(sound.id)")
                return false
            }
            audio.volume = volume
            audio.prepareToPlay()
            audio.delegate = AlarmDelegate.shared
            AlarmDelegate.shared.onFinish = { [weak self] in
                Task { @MainActor in
                    self?.isPlaying = false
                    self?.statusLine = self?.isArmed == true ? "Audio: on" : "Audio: off"
                }
            }
            alarmPlayer = audio
            return true
        } catch {
            print("Alarm load failed: \(error)")
            return false
        }
    }

    private func checkSchedule() {
        guard isArmed, let service = prayerService else { return }
        let dayKey = service.day?.gregorian ?? "day"

        if let prayer = service.currentAdhanPrayerIfDue() {
            let key = "\(dayKey)-\(prayer.id)-adhan"
            if lastPlayedKey == key { return }
            lastPlayedKey = key
            playNow()
            statusLine = "Audio: \(prayer.name)"
            return
        }

        if let alert = service.currentSecondaryAlertIfDue(configs: secondaryAlerts) {
            let key = "\(dayKey)-\(alert.id)-alarm"
            if lastPlayedKey == key { return }
            lastPlayedKey = key
            playAlarmPreview(soundId: alert.soundId)
            statusLine = "Audio: \(alert.name)"
        }
    }
}

private final class PlayerDelegate: NSObject, AVAudioPlayerDelegate {
    static let shared = PlayerDelegate()
    var onFinish: (() -> Void)?

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        onFinish?()
    }
}

private final class AlarmDelegate: NSObject, AVAudioPlayerDelegate {
    static let shared = AlarmDelegate()
    var onFinish: (() -> Void)?

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        onFinish?()
    }
}
