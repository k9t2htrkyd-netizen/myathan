import AVFoundation
import Foundation

@MainActor
final class AdhanPlayer: ObservableObject {
    @Published var isArmed = false
    @Published var isPlaying = false
    @Published var statusLine = "Audio: off"
    @Published var volume: Float = 0.85 {
        didSet {
            speakers?.applyVolume(volume)
            UserDefaults.standard.set(volume, forKey: "adhanVolume")
        }
    }
    @Published var secondaryAlerts: [String: SecondaryAlertConfig] = SecondaryAlertDefaults.values
    @Published var customAlarms: [CustomDailyAlarm] = []
    @Published var selectedAdhanId: String = "adhan-jordan" {
        didSet { UserDefaults.standard.set(selectedAdhanId, forKey: "v2SelectedAdhanId") }
    }

    private var lastPlayedKey: String?
    private var watchTimer: Timer?
    private weak var prayerService: PrayerService?
    private weak var speakers: SpeakerService?

    init() {
        let saved = UserDefaults.standard.object(forKey: "adhanVolume") as? Float
        volume = saved ?? 0.85
        if let savedAdhan = UserDefaults.standard.string(forKey: "v2SelectedAdhanId"),
           AlarmSound.adhans.contains(where: { $0.id == savedAdhan }) {
            selectedAdhanId = savedAdhan
        }
        loadSecondaryAlerts()
        loadCustomAlarms()
    }

    func attach(prayerService: PrayerService, speakers: SpeakerService) {
        self.prayerService = prayerService
        self.speakers = speakers
        speakers.onPlaybackEnded = { [weak self] in
            Task { @MainActor in
                self?.isPlaying = false
                self?.statusLine = self?.isArmed == true ? "Audio: on" : "Audio: off"
            }
        }
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
        isArmed = true
        statusLine = "Audio: on"
    }

    func disarm() {
        isArmed = false
        stopAndReset()
        statusLine = "Audio: off"
    }

    func playNow() {
        Task { await playAdhan() }
    }

    func playAlarmPreview(soundId: String) {
        statusLine = "Audio: loading…"
        Task { @MainActor in
            await playAlarm(soundId: soundId)
        }
    }

    func stopAndReset() {
        speakers?.stopPlayback()
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

    func addCustomAlarm(_ alarm: CustomDailyAlarm) {
        customAlarms.append(alarm)
        saveCustomAlarms()
    }

    func updateCustomAlarm(_ alarm: CustomDailyAlarm) {
        if let index = customAlarms.firstIndex(where: { $0.id == alarm.id }) {
            customAlarms[index] = alarm
            saveCustomAlarms()
        }
    }

    func removeCustomAlarm(id: String) {
        customAlarms.removeAll { $0.id == id }
        saveCustomAlarms()
    }

    var selectedAdhan: AlarmSound {
        AlarmSound.adhans.first(where: { $0.id == selectedAdhanId }) ?? AlarmSound.adhans.first(where: { $0.id == "adhan-jordan" })!
    }

    private func playAdhan() async {
        await playSound(selectedAdhan)
    }

    private func playAlarm(soundId: String) async {
        let sound = AlarmSound.all.first(where: { $0.id == soundId }) ?? AlarmSound.all[0]
        await playSound(sound)
    }

    private func playSound(_ sound: AlarmSound) async {
        guard let speakers else { return }
        guard let fileURL = await localURL(for: sound) else {
            statusLine = "Audio: missing file"
            return
        }
        await speakers.play(fileURL: fileURL, remoteURL: sound.cloudURL, volume: volume)
        isPlaying = speakers.isStreaming
        statusLine = speakers.statusLine
    }

    private func localURL(for sound: AlarmSound) async -> URL? {
        if let fileName = sound.fileName,
           let url = Bundle.module.url(forResource: fileName, withExtension: "mp3", subdirectory: "alarms")
            ?? Bundle.module.url(forResource: fileName, withExtension: "mp3") {
            return url
        }
        guard let remote = sound.remoteURL, let remoteURL = URL(string: remote) else { return nil }
        do {
            let (data, _) = try await URLSession.shared.data(from: remoteURL)
            let tmp = FileManager.default.temporaryDirectory.appendingPathComponent("athan-\(sound.id).mp3")
            try data.write(to: tmp)
            return tmp
        } catch {
            print("Alarm download failed: \(error)")
            return nil
        }
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

    private func loadCustomAlarms() {
        guard let data = UserDefaults.standard.data(forKey: "customAlarms"),
              let decoded = try? JSONDecoder().decode([CustomDailyAlarm].self, from: data)
        else { return }
        customAlarms = decoded
    }

    private func saveCustomAlarms() {
        if let data = try? JSONEncoder().encode(customAlarms) {
            UserDefaults.standard.set(data, forKey: "customAlarms")
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
            return
        }

        if let alert = service.currentSecondaryAlertIfDue(configs: secondaryAlerts) {
            let key = "\(dayKey)-\(alert.id)-alarm"
            if lastPlayedKey == key { return }
            lastPlayedKey = key
            playAlarmPreview(soundId: alert.soundId)
            return
        }

        let parts = Calendar.current.dateComponents([.hour, .minute], from: Date())
        for alarm in customAlarms where alarm.enabled {
            guard alarm.hour == parts.hour, alarm.minute == parts.minute else { continue }
            let key = "\(dayKey)-custom-\(alarm.id)"
            if lastPlayedKey == key { return }
            lastPlayedKey = key
            playAlarmPreview(soundId: alarm.soundId)
            return
        }
    }
}
