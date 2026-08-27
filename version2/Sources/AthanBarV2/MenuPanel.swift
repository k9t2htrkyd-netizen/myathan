import AppKit
import SwiftUI

struct MenuPanel: View {
    @ObservedObject var prayers: PrayerService
    @ObservedObject var audio: AdhanPlayer
    @ObservedObject var speakers: SpeakerService
    var onQuit: () -> Void
    @State private var showingCustomAlarm = false

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            leftColumn
                .frame(width: 360)
            Divider()
            rightColumn
                .frame(width: 400)
        }
        .frame(width: 760)
        .background(Color(red: 0.043, green: 0.110, blue: 0.094))
        .preferredColorScheme(.dark)
    }

    private var leftColumn: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider().opacity(0.35)
            locationSection
            Divider().opacity(0.35)
            nextSection
            Divider().opacity(0.35)
            prayerList
        }
    }

    private var rightColumn: some View {
        VStack(alignment: .leading, spacing: 0) {
            audioSection
            Divider().opacity(0.35)
            speakerSection
            Spacer(minLength: 8)
            Divider().opacity(0.35)
            actionsSection
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            if let url = Bundle.module.url(forResource: "logo", withExtension: "png"),
               let nsImage = NSImage(contentsOf: url) {
                Image(nsImage: nsImage)
                    .resizable()
                    .interpolation(.high)
                    .frame(width: 28, height: 28)
                    .clipShape(RoundedRectangle(cornerRadius: 7))
            } else {
                Image(systemName: "moon.stars.fill")
                    .foregroundStyle(Color(red: 0.769, green: 0.639, blue: 0.353))
            }
            VStack(alignment: .leading, spacing: 1) {
                Text("Athan 2.1.1")
                    .font(.headline)
                Text(prayers.locationLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            Text(prayers.statusText)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Location")
                .font(.caption)
                .foregroundStyle(.secondary)

            TextField("City, state, or country", text: Binding(
                get: { prayers.locationQuery },
                set: { prayers.schedulePlaceSearch(for: $0) }
            ))
            .textFieldStyle(.roundedBorder)
            .onSubmit {
                if let first = prayers.suggestions.first {
                    Task { await prayers.selectPlace(first) }
                }
            }

            Button {
                Task { await prayers.findMyLocation() }
            } label: {
                Label(prayers.isLocating ? "Finding…" : "Find my location", systemImage: "location")
            }
            .disabled(prayers.isLocating)
            .font(.caption)

            if let locationError = prayers.locationError {
                Text(locationError)
                    .font(.caption2)
                    .foregroundStyle(.red)
            }

            Picker("Method", selection: Binding(
                get: { prayers.method },
                set: { newValue in
                    prayers.method = newValue
                    prayers.saveLocation()
                    Task { await prayers.refresh() }
                }
            )) {
                ForEach(CalculationMethod.all) { method in
                    Text(method.shortName).tag(method.id)
                }
            }
            .labelsHidden()

            Picker("Asr", selection: Binding(
                get: { prayers.school },
                set: { newValue in
                    prayers.school = newValue
                    prayers.saveLocation()
                    Task { await prayers.refresh() }
                }
            )) {
                Text("Shafi").tag(0)
                Text("Hanafi").tag(1)
            }
            .pickerStyle(.segmented)

            if prayers.isSearchingPlaces {
                Text("Searching…")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            if !prayers.suggestions.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(prayers.suggestions.prefix(3))) { place in
                        Button {
                            Task { await prayers.selectPlace(place) }
                        } label: {
                            HStack {
                                Image(systemName: "mappin.and.ellipse")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(place.label)
                                    .font(.caption)
                                    .lineLimit(1)
                                Spacer()
                            }
                            .padding(.vertical, 4)
                            .padding(.horizontal, 6)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .background(Color.primary.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private var nextSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Next prayer")
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack {
                VStack(alignment: .leading, spacing: 1) {
                    Text(prayers.nextPrayer?.name ?? "—")
                        .font(.title3.weight(.semibold))
                    Text(prayers.nextPrayer?.displayTime ?? "—")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 1) {
                    Text("Countdown")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(prayers.countdownText)
                        .font(.system(.body, design: .monospaced).weight(.semibold))
                }
            }
            if let day = prayers.day {
                Text("\(day.gregorian)  ·  \(day.hijri)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private var prayerList: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Adhan prayers")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 12)
                .padding(.top, 8)
                .padding(.bottom, 2)

            ForEach(prayers.day?.timings.filter { PrayerName.adhanPrayers.contains($0.id) } ?? []) { timing in
                HStack {
                    if prayers.nextPrayer?.id == timing.id {
                        Image(systemName: "checkmark")
                            .font(.caption.weight(.bold))
                            .frame(width: 14)
                    } else {
                        Color.clear.frame(width: 14)
                    }
                    Text(timing.name)
                    Spacer()
                    Text(timing.displayTime)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(
                    prayers.nextPrayer?.id == timing.id
                        ? Color.accentColor.opacity(0.12)
                        : Color.clear
                )
            }

            Divider().opacity(0.35)
                .padding(.top, 4)

            Text("Other times (alarms)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 12)
                .padding(.top, 8)
                .padding(.bottom, 2)

            ForEach(PrayerName.secondaryTimes, id: \.self) { key in
                secondaryRow(for: key)
            }

            ForEach(audio.customAlarms) { alarm in
                customAlarmRow(alarm)
            }

            if showingCustomAlarm {
                AddCustomAlarmForm(
                    onCancel: { showingCustomAlarm = false },
                    onSave: { alarm in
                        audio.addCustomAlarm(alarm)
                        showingCustomAlarm = false
                    }
                )
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
            } else {
                Button {
                    showingCustomAlarm = true
                } label: {
                    Label("Add daily alarm", systemImage: "plus")
                }
                .buttonStyle(.plain)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
            }
        }
    }

    private func secondaryRow(for key: String) -> some View {
        let timing = prayers.day?.timings.first(where: { $0.id == key })
        let config = audio.secondaryAlerts[key] ?? SecondaryAlertDefaults.values[key]!
        return HStack(spacing: 6) {
            Text(PrayerName.labels[key] ?? key)
                .lineLimit(1)
            Spacer(minLength: 4)
            if let timing {
                Text(timing.displayTime)
                    .foregroundStyle(.secondary)
            }
            if config.enabled {
                Picker("Sound", selection: Binding(
                    get: { audio.secondaryAlerts[key]?.soundId ?? AlarmSound.all[0].id },
                    set: { audio.setSecondarySound(key, soundId: $0) }
                )) {
                    Section("Alarms") {
                        ForEach(AlarmSound.alarms) { sound in
                            Text(sound.name).tag(sound.id)
                        }
                    }
                    Section("Adhan") {
                        ForEach(AlarmSound.adhans) { sound in
                            Text(sound.name).tag(sound.id)
                        }
                    }
                }
                .labelsHidden()
                .frame(width: 120)
                .controlSize(.mini)

                Button {
                    audio.playAlarmPreview(soundId: audio.secondaryAlerts[key]?.soundId ?? AlarmSound.all[0].id)
                } label: {
                    Image(systemName: "play.circle")
                }
                .buttonStyle(.plain)
                .help("Preview alarm")
            }
            Toggle("", isOn: Binding(
                get: { audio.secondaryAlerts[key]?.enabled ?? false },
                set: { audio.setSecondaryEnabled(key, enabled: $0) }
            ))
            .labelsHidden()
            .toggleStyle(.switch)
            .controlSize(.mini)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 3)
    }

    private func customAlarmRow(_ alarm: CustomDailyAlarm) -> some View {
        HStack(spacing: 6) {
            Text(alarm.name)
                .lineLimit(1)
            Spacer(minLength: 4)
            Text(alarm.displayTime)
                .foregroundStyle(.secondary)
            if alarm.enabled {
                Picker("Sound", selection: Binding(
                    get: { alarm.soundId },
                    set: {
                        var next = alarm
                        next.soundId = $0
                        audio.updateCustomAlarm(next)
                    }
                )) {
                    ForEach(AlarmSound.all) { sound in
                        Text(sound.name).tag(sound.id)
                    }
                }
                .labelsHidden()
                .frame(width: 120)
                .controlSize(.mini)
            }
            Toggle("", isOn: Binding(
                get: { alarm.enabled },
                set: {
                    var next = alarm
                    next.enabled = $0
                    audio.updateCustomAlarm(next)
                }
            ))
            .labelsHidden()
            .toggleStyle(.switch)
            .controlSize(.mini)
            Button {
                audio.removeCustomAlarm(id: alarm.id)
            } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(.plain)
            .help("Remove alarm")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 3)
    }

    private var audioSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Adhan audio", systemImage: "speaker.wave.2.fill")
                .font(.caption)
                .foregroundStyle(.secondary)

            Button {
                audio.toggleArmed()
            } label: {
                HStack {
                    Image(systemName: audio.isArmed ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(audio.isArmed ? .green : .secondary)
                    Text(audio.isArmed ? "Adhan armed — will play at prayer time" : "Enable Adhan audio")
                        .lineLimit(1)
                    Spacer()
                }
            }
            .buttonStyle(.plain)

            HStack(spacing: 8) {
                Image(systemName: audio.volume < 0.01 ? "speaker.slash.fill" : "speaker.fill")
                    .foregroundStyle(.secondary)
                    .frame(width: 16)
                Slider(value: $audio.volume, in: 0...1)
                Text("\(Int((audio.volume * 100).rounded()))%")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .frame(width: 36, alignment: .trailing)
            }

            HStack {
                Text("Adhan")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Picker("Adhan", selection: $audio.selectedAdhanId) {
                    ForEach(AlarmSound.adhans) { sound in
                        Text(sound.name).tag(sound.id)
                    }
                }
                .labelsHidden()
            }

            if audio.isPlaying {
                Button {
                    audio.stopAndReset()
                } label: {
                    Label("Stop & reset Adhan", systemImage: "stop.fill")
                }
                .buttonStyle(.plain)
                .foregroundStyle(.red)
            } else {
                Button {
                    audio.playNow()
                } label: {
                    Label("Play Adhan now", systemImage: "play.fill")
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }

            Text(audio.statusLine)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    private var speakerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Play Adhan on", systemImage: "hifispeaker.fill")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text("Checked speakers play together. Unchecked Mac speakers stay silent.")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            HStack {
                Text("This Mac / Bluetooth")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Refresh") {
                    speakers.refreshAudioDevices()
                }
                .buttonStyle(.plain)
                .font(.caption)
            }

            if speakers.audioDevices.isEmpty {
                Text("No output devices found.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(speakers.audioDevices) { device in
                    SpeakerRenameRow(
                        title: speakers.displayName(localUID: device.uid, fallback: device.name),
                        subtitle: device.isBluetooth ? "Bluetooth" : device.transport,
                        isOn: Binding(
                            get: { speakers.selectedLocalUIDs.contains(device.uid) },
                            set: { speakers.setLocalSelected(device.uid, enabled: $0) }
                        ),
                        onRename: { speakers.renameLocalDevice(uid: device.uid, name: $0) }
                    )
                }
            }

            Divider().opacity(0.35)

            HStack {
                Text("Google Nest / Chromecast")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button {
                    speakers.scanCastDevices()
                } label: {
                    Label(speakers.isScanning ? "Scanning…" : "Scan Wi-Fi", systemImage: "wifi")
                }
                .disabled(speakers.isScanning)
                .buttonStyle(.plain)
                .font(.caption)
            }

            if speakers.allCastDevices.isEmpty {
                Text("Scan Wi-Fi or add a Nest IP below.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(speakers.allCastDevices) { device in
                    SpeakerRenameRow(
                        title: speakers.displayName(cast: device),
                        subtitle: device.host,
                        isOn: Binding(
                            get: { speakers.selectedCastKeys.contains(device.host) || speakers.selectedCastKeys.contains(device.id) },
                            set: { speakers.setCastSelected(device, enabled: $0) }
                        ),
                        onRename: { speakers.renameCastDevice(device, name: $0) }
                    )
                }
            }

            HStack(spacing: 6) {
                TextField("Add Nest IP", text: $speakers.manualIP)
                    .textFieldStyle(.roundedBorder)
                Button("Add") {
                    speakers.addManualIP()
                }
                .disabled(speakers.manualIP.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .font(.caption)

            Text(speakers.statusLine)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .onAppear {
            speakers.refreshAudioDevices()
            if speakers.castDevices.isEmpty {
                speakers.scanCastDevices()
            }
        }
    }

    private var actionsSection: some View {
        HStack {
            Button {
                Task { await prayers.refresh() }
            } label: {
                Label("Refresh times", systemImage: "arrow.clockwise")
            }
            .buttonStyle(.plain)

            Spacer()

            Button(role: .destructive) {
                onQuit()
            } label: {
                HStack(spacing: 8) {
                    Text("Quit Athan 2.1.1")
                    Text("⌘Q")
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)
            .keyboardShortcut("q", modifiers: .command)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
}

private struct SpeakerRenameRow: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    var onRename: (String) -> Void

    @State private var showRename = false
    @State private var draft = ""

    var body: some View {
        HStack(spacing: 6) {
            Toggle(isOn: $isOn) {
                HStack(spacing: 6) {
                    Text(title)
                        .lineLimit(1)
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .toggleStyle(.checkbox)

            Button {
                draft = title
                showRename = true
            } label: {
                Image(systemName: "pencil")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help("Rename this speaker")
            .popover(isPresented: $showRename, arrowEdge: .leading) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Rename speaker")
                        .font(.headline)
                    TextField("Name", text: $draft)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 220)
                        .onSubmit { save() }
                    HStack {
                        Button("Use original") {
                            onRename("")
                            showRename = false
                        }
                        Spacer()
                        Button("Save") { save() }
                            .keyboardShortcut(.defaultAction)
                    }
                }
                .padding(12)
            }
        }
    }

    private func save() {
        onRename(draft)
        showRename = false
    }
}

private struct AddCustomAlarmForm: View {
    var onCancel: () -> Void
    var onSave: (CustomDailyAlarm) -> Void

    @State private var name = "My alarm"
    @State private var hour: Int
    @State private var minute: Int
    @State private var soundId = "classic-alarm"

    init(onCancel: @escaping () -> Void, onSave: @escaping (CustomDailyAlarm) -> Void) {
        self.onCancel = onCancel
        self.onSave = onSave
        let parts = Calendar.current.dateComponents([.hour, .minute], from: Date())
        _hour = State(initialValue: min(23, max(0, parts.hour ?? 6)))
        _minute = State(initialValue: min(59, max(0, parts.minute ?? 0)))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Add daily alarm")
                .font(.headline)
            TextField("Name", text: $name)
                .textFieldStyle(.roundedBorder)
            HStack(spacing: 6) {
                Text("Time")
                    .foregroundStyle(.secondary)
                Picker("Hour", selection: $hour) {
                    ForEach(0..<24, id: \.self) { value in
                        Text(Self.hourLabel(value)).tag(value)
                    }
                }
                .labelsHidden()
                .frame(maxWidth: .infinity)
                Text(":")
                    .foregroundStyle(.secondary)
                Picker("Minute", selection: $minute) {
                    ForEach(0..<60, id: \.self) { value in
                        Text(String(format: "%02d", value)).tag(value)
                    }
                }
                .labelsHidden()
                .frame(width: 72)
            }
            Picker("Sound", selection: $soundId) {
                ForEach(AlarmSound.all) { sound in
                    Text(sound.name).tag(sound.id)
                }
            }
            HStack {
                Button("Cancel") { onCancel() }
                Spacer()
                Button("Save") {
                    let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                    onSave(
                        CustomDailyAlarm(
                            id: UUID().uuidString,
                            name: trimmed.isEmpty ? "Alarm" : trimmed,
                            hour: hour,
                            minute: minute,
                            enabled: true,
                            soundId: soundId
                        )
                    )
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(10)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private static func hourLabel(_ hour: Int) -> String {
        let period = hour >= 12 ? "PM" : "AM"
        var display = hour % 12
        if display == 0 { display = 12 }
        return String(format: "%d %@", display, period)
    }
}
