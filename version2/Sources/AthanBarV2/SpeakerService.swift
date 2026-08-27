import Foundation

@MainActor
final class SpeakerService: ObservableObject {
    @Published var castDevices: [CastDevice] = []
    @Published var extraCastDevices: [CastDevice] = []
    @Published var audioDevices: [SystemAudioDevice] = []
    @Published var selectedLocalUIDs: Set<String> = [] {
        didSet { UserDefaults.standard.set(Array(selectedLocalUIDs), forKey: "v2SelectedLocalUIDs") }
    }
    @Published var selectedCastKeys: Set<String> = [] {
        didSet { UserDefaults.standard.set(Array(selectedCastKeys), forKey: "v2SelectedCastKeys") }
    }
    @Published var manualIP: String = "" {
        didSet { UserDefaults.standard.set(manualIP, forKey: "v2CastHost") }
    }
    @Published var statusLine = "Check the speakers that should play Adhan"
    @Published var customNames: [String: String] = [:] {
        didSet { UserDefaults.standard.set(customNames, forKey: "v2CustomDeviceNames") }
    }
    @Published var isScanning = false
    @Published var isConnecting = false
    @Published var isStreaming = false

    var onPlaybackEnded: (() -> Void)?

    var allCastDevices: [CastDevice] {
        var seen = Set<String>()
        var list: [CastDevice] = []
        for device in extraCastDevices + castDevices {
            if seen.insert(device.host).inserted {
                list.append(device)
            }
        }
        return list.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    var selectedLocalDevices: [SystemAudioDevice] {
        refreshMatches()
    }

    private var savedLocalNames: [String: String] {
        get { UserDefaults.standard.dictionary(forKey: "v2SelectedLocalNames") as? [String: String] ?? [:] }
        set { UserDefaults.standard.set(newValue, forKey: "v2SelectedLocalNames") }
    }

    private func refreshMatches() -> [SystemAudioDevice] {
        var found = audioDevices.filter { selectedLocalUIDs.contains($0.uid) }
        let foundUIDs = Set(found.map(\.uid))
        let names = savedLocalNames
        for uid in selectedLocalUIDs where !foundUIDs.contains(uid) {
            if let name = names[uid],
               let match = audioDevices.first(where: { $0.name == name }) {
                found.append(match)
            }
        }
        return found
    }

    var selectedCastList: [CastDevice] {
        var seen = Set<String>()
        var list: [CastDevice] = []
        for device in extraCastDevices + castDevices {
            guard selectedCastKeys.contains(device.host) || selectedCastKeys.contains(device.id) else { continue }
            if seen.insert(device.host).inserted {
                list.append(device)
            }
        }
        for key in selectedCastKeys where seen.insert(key).inserted {
            list.append(CastDevice(id: key, name: key, model: "Saved", host: key, port: 8009))
        }
        return list.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private let browser = CastBrowser()
    private let localPlayer = LocalDevicePlayer()
    private var castClients: [String: CastClient] = [:]
    private var activeLocal = false
    private var activeCastHosts: Set<String> = []
    private var awaitingCastStart = false

    init() {
        loadSavedSelection()
        refreshAudioDevices()
        localPlayer.onAllFinished = { [weak self] in
            Task { @MainActor in
                self?.activeLocal = false
                self?.finishIfIdle()
            }
        }
        browser.onUpdate = { [weak self] devices in
            Task { @MainActor in
                self?.castDevices = devices
                self?.rememberVisibleCastDevices(devices)
                self?.isScanning = false
                if devices.isEmpty {
                    self?.statusLine = self?.selectedSummary() ?? "No Nest speakers found"
                } else {
                    self?.statusLine = "Found \(devices.count) Nest/Chromecast speaker\(devices.count == 1 ? "" : "s")"
                }
            }
        }
    }

    func refreshAudioDevices() {
        audioDevices = AudioOutputRouter.outputDevices()
        migrateLocalSelection()
        statusLine = selectedSummary()
    }

    func scanCastDevices() {
        isScanning = true
        statusLine = "Scanning Wi-Fi for Nest / Chromecast…"
        browser.start()
        DispatchQueue.main.asyncAfter(deadline: .now() + 6) { [weak self] in
            self?.isScanning = false
            if self?.castDevices.isEmpty == true {
                self?.statusLine = "No Nest speakers found. Add one by IP, or check Wi-Fi."
            }
        }
    }

    func setLocalSelected(_ uid: String, enabled: Bool) {
        if enabled {
            selectedLocalUIDs.insert(uid)
            var names = savedLocalNames
            names[uid] = audioDevices.first(where: { $0.uid == uid })?.name ?? uid
            savedLocalNames = names
        } else {
            selectedLocalUIDs.remove(uid)
        }
        statusLine = selectedSummary()
    }

    func setCastSelected(_ device: CastDevice, enabled: Bool) {
        if enabled {
            selectedCastKeys.insert(device.host)
            extraCastDevices.removeAll { $0.host == device.host }
            extraCastDevices.append(device)
            persistExtraCast()
        } else {
            selectedCastKeys.remove(device.host)
            selectedCastKeys.remove(device.id)
        }
        statusLine = selectedSummary()
    }

    func displayName(localUID: String, fallback: String) -> String {
        let custom = customNames["local:\(localUID)"]?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let custom, !custom.isEmpty { return custom }
        return fallback
    }

    func displayName(cast device: CastDevice) -> String {
        for key in ["cast:\(device.host)", "cast:\(device.id)"] {
            let custom = customNames[key]?.trimmingCharacters(in: .whitespacesAndNewlines)
            if let custom, !custom.isEmpty { return custom }
        }
        return device.name
    }

    func renameLocalDevice(uid: String, name: String) {
        setCustomName(key: "local:\(uid)", name: name)
    }

    func renameCastDevice(_ device: CastDevice, name: String) {
        var next = customNames
        next.removeValue(forKey: "cast:\(device.id)")
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            next.removeValue(forKey: "cast:\(device.host)")
        } else {
            next["cast:\(device.host)"] = trimmed
        }
        customNames = next
        statusLine = selectedSummary()
    }

    private func setCustomName(key: String, name: String) {
        var next = customNames
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            next.removeValue(forKey: key)
        } else {
            next[key] = trimmed
        }
        customNames = next
        statusLine = selectedSummary()
    }

    func addManualIP() {
        let host = manualIP.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !host.isEmpty else { return }
        let device = CastDevice(id: host, name: host, model: "IP", host: host, port: 8009)
        extraCastDevices.removeAll { $0.host == host }
        extraCastDevices.append(device)
        selectedCastKeys.insert(host)
        persistExtraCast()
        statusLine = selectedSummary()
    }

    func play(fileURL: URL, remoteURL: URL? = nil, volume: Float) async {
        await resetForNewPlay()
        refreshAudioDevices()

        let local = selectedLocalDevices
        let nest = selectedCastList
        if local.isEmpty && nest.isEmpty {
            isStreaming = false
            statusLine = "Select at least one speaker first"
            return
        }

        var playing: [String] = []
        var failed: [String] = []

        if !nest.isEmpty {
            awaitingCastStart = true
            let mediaURL = remoteURL ?? URL(string: "https://myathan.link/audio/athan-amman-jordan.mp3")!
            isConnecting = true
            for device in nest {
                do {
                    try await playOnCast(device: device, mediaURL: mediaURL, volume: volume)
                    playing.append(displayName(cast: device))
                } catch {
                    failed.append("\(device.name): \(error.localizedDescription)")
                }
            }
            isConnecting = false
            awaitingCastStart = false
        }

        if !local.isEmpty {
            if !nest.isEmpty {
                statusLine = "Waiting 2 seconds so Nest can start…"
                try? await Task.sleep(nanoseconds: 2_000_000_000)
            }
            do {
                try localPlayer.play(fileURL: fileURL, devices: local, volume: volume)
                activeLocal = true
                playing.append(contentsOf: local.map { displayName(localUID: $0.uid, fallback: $0.name) })
            } catch {
                activeLocal = false
                failed.append(error.localizedDescription)
            }
        } else {
            activeLocal = false
        }

        finishAfterPartialStart(playing: playing, failed: failed)
    }

    func stopPlayback() {
        localPlayer.stop()
        activeLocal = false
        awaitingCastStart = false
        for client in castClients.values {
            client.stopPlayback()
        }
        activeCastHosts.removeAll()
        isStreaming = false
        statusLine = selectedSummary()
        Task { [castClients] in
            for client in castClients.values {
                await client.disconnect()
            }
        }
    }

    private func resetForNewPlay() async {
        localPlayer.stop()
        activeLocal = false
        awaitingCastStart = false
        activeCastHosts.removeAll()
        isStreaming = false
        for client in Array(castClients.values) {
            await client.disconnect()
        }
    }

    func applyVolume(_ volume: Float) {
        localPlayer.setVolume(volume)
        for client in castClients.values {
            client.setVolume(volume)
        }
    }

    func selectedSummary() -> String {
        let names = selectedLocalDevices.map { displayName(localUID: $0.uid, fallback: $0.name) }
            + selectedCastList.map { displayName(cast: $0) }
        if names.isEmpty {
            return "No speakers selected — Mac speakers will stay silent"
        }
        return "Will play on \(names.joined(separator: ", "))"
    }

    private func playOnCast(device: CastDevice, mediaURL: URL, volume: Float) async throws {
        let client = client(for: device.host)
        // Nest closes the Cast session after each play. Always open a fresh connection.
        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask { try await client.connect(host: device.host, port: UInt16(device.port)) }
            group.addTask {
                try await Task.sleep(nanoseconds: 8_000_000_000)
                throw CastError.timeout
            }
            _ = try await group.next()
            group.cancelAll()
        }
        try await Task.sleep(nanoseconds: 400_000_000)
        client.setVolume(volume)
        try await client.play(mediaURL: mediaURL)
        activeCastHosts.insert(device.host)
        isStreaming = true
    }

    private func client(for host: String) -> CastClient {
        if let existing = castClients[host] { return existing }
        let client = CastClient()
        client.onPlayerState = { [weak self] state in
            Task { @MainActor in
                self?.noteCastState(host: host, state: state)
            }
        }
        client.onDisconnected = { [weak self] _ in
            Task { @MainActor in
                guard let self, self.activeCastHosts.contains(host) else { return }
                self.activeCastHosts.remove(host)
                self.finishIfIdle()
            }
        }
        castClients[host] = client
        return client
    }

    private func noteCastState(host: String, state: String) {
        if state == "PLAYING" || state == "BUFFERING" {
            activeCastHosts.insert(host)
            awaitingCastStart = false
            isStreaming = true
        }
        if state == "IDLE" && activeCastHosts.contains(host) {
            activeCastHosts.remove(host)
            finishIfIdle()
        }
    }

    private func finishAfterPartialStart(playing: [String], failed: [String]) {
        if playing.isEmpty {
            isStreaming = false
            statusLine = failed.isEmpty ? "Select at least one speaker first" : failed.joined(separator: " · ")
            return
        }
        isStreaming = true
        var line = "Playing on \(playing.joined(separator: ", "))"
        if !failed.isEmpty {
            line += " · \(failed.joined(separator: " · "))"
        }
        statusLine = line
    }

    private func finishIfIdle() {
        guard !awaitingCastStart, !activeLocal, activeCastHosts.isEmpty else { return }
        isStreaming = false
        statusLine = selectedSummary()
        onPlaybackEnded?()
    }

    private func loadSavedSelection() {
        if let saved = UserDefaults.standard.array(forKey: "v2SelectedLocalUIDs") as? [String] {
            selectedLocalUIDs = Set(saved)
        } else if UserDefaults.standard.string(forKey: "v2SpeakerMode") == "thisMac",
                  let uid = AudioOutputRouter.defaultOutputUID() {
            selectedLocalUIDs = [uid]
        } else if UserDefaults.standard.string(forKey: "v2SpeakerMode") == "bluetooth",
                  let uid = UserDefaults.standard.string(forKey: "v2AudioDeviceUID") {
            selectedLocalUIDs = [uid]
        }

        if let saved = UserDefaults.standard.array(forKey: "v2SelectedCastKeys") as? [String] {
            selectedCastKeys = Set(saved)
        } else if UserDefaults.standard.string(forKey: "v2SpeakerMode") == "googleCast",
                  let host = UserDefaults.standard.string(forKey: "v2CastHost"), !host.isEmpty {
            selectedCastKeys = [host]
        }

        if let data = UserDefaults.standard.data(forKey: "v2ExtraCastDevices"),
           let saved = try? JSONDecoder().decode([CastDevice].self, from: data) {
            extraCastDevices = saved
        } else if let hosts = UserDefaults.standard.array(forKey: "v2ExtraCastHosts") as? [String] {
            extraCastDevices = hosts.map { CastDevice(id: $0, name: $0, model: "IP", host: $0, port: 8009) }
        } else if let host = UserDefaults.standard.string(forKey: "v2CastHost"), !host.isEmpty {
            extraCastDevices = [CastDevice(id: host, name: host, model: "IP", host: host, port: 8009)]
            selectedCastKeys.insert(host)
        }

        for key in selectedCastKeys where !extraCastDevices.contains(where: { $0.host == key || $0.id == key }) {
            extraCastDevices.append(CastDevice(id: key, name: key, model: "Saved", host: key, port: 8009))
        }
        persistExtraCast()

        if let savedNames = UserDefaults.standard.dictionary(forKey: "v2CustomDeviceNames") as? [String: String] {
            customNames = savedNames
        }

        manualIP = UserDefaults.standard.string(forKey: "v2CastHost") ?? ""
        statusLine = selectedSummary()
    }

    private func rememberVisibleCastDevices(_ devices: [CastDevice]) {
        guard !devices.isEmpty else { return }
        var changed = false
        for device in devices {
            let wasSelected = selectedCastKeys.contains(device.host)
                || selectedCastKeys.contains(device.id)
                || extraCastDevices.contains(where: { $0.id == device.id && selectedCastKeys.contains($0.host) })
            guard wasSelected else { continue }
            if let old = extraCastDevices.first(where: { $0.id == device.id && $0.host != device.host }) {
                selectedCastKeys.remove(old.host)
            }
            selectedCastKeys.insert(device.host)
            extraCastDevices.removeAll { $0.id == device.id || $0.host == device.host }
            extraCastDevices.append(device)
            changed = true
        }
        if changed { persistExtraCast() }
    }

    private func migrateLocalSelection() {
        var names = savedLocalNames
        var uids = selectedLocalUIDs
        let current = Set(audioDevices.map(\.uid))
        for uid in selectedLocalUIDs where !current.contains(uid) {
            if let name = names[uid],
               let match = audioDevices.first(where: { $0.name == name }) {
                uids.remove(uid)
                uids.insert(match.uid)
                names.removeValue(forKey: uid)
                names[match.uid] = name
            }
        }
        if uids != selectedLocalUIDs {
            selectedLocalUIDs = uids
            savedLocalNames = names
        }
    }

    private func persistExtraCast() {
        if let data = try? JSONEncoder().encode(extraCastDevices) {
            UserDefaults.standard.set(data, forKey: "v2ExtraCastDevices")
        }
        UserDefaults.standard.set(extraCastDevices.map(\.host), forKey: "v2ExtraCastHosts")
    }
}
