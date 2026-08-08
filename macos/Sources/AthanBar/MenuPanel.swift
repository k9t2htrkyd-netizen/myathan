import AppKit
import SwiftUI

struct MenuPanel: View {
    @ObservedObject var prayers: PrayerService
    @ObservedObject var audio: AdhanPlayer
    var onQuit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider().opacity(0.35)
            locationSection
            Divider().opacity(0.35)
            nextSection
            Divider().opacity(0.35)
            prayerList
            Divider().opacity(0.35)
            audioSection
            Divider().opacity(0.35)
            actionsSection
        }
        .frame(width: 360)
        .background(.ultraThinMaterial)
    }

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "moon.stars.fill")
                .foregroundStyle(.yellow)
            VStack(alignment: .leading, spacing: 2) {
                Text("Athan")
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
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
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

            if prayers.isSearchingPlaces {
                Text("Searching cities…")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            if !prayers.suggestions.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(prayers.suggestions) { place in
                        Button {
                            Task { await prayers.selectPlace(place) }
                        } label: {
                            HStack {
                                Image(systemName: "mappin.and.ellipse")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(place.label)
                                    .font(.caption)
                                    .multilineTextAlignment(.leading)
                                Spacer()
                            }
                            .padding(.vertical, 6)
                            .padding(.horizontal, 8)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .background(Color.primary.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(14)
    }

    private var nextSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Next prayer")
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(prayers.nextPrayer?.name ?? "—")
                        .font(.title3.weight(.semibold))
                    Text(prayers.nextPrayer?.displayTime ?? "—")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
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
            }
        }
        .padding(14)
    }

    private var prayerList: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Adhan prayers")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 14)
                .padding(.top, 10)
                .padding(.bottom, 4)

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
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(
                    prayers.nextPrayer?.id == timing.id
                        ? Color.accentColor.opacity(0.12)
                        : Color.clear
                )
            }
            .padding(.bottom, 8)

            Divider().opacity(0.35)

            Text("Other times (alarms)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 14)
                .padding(.top, 10)
                .padding(.bottom, 4)

            ForEach(PrayerName.secondaryTimes, id: \.self) { key in
                secondaryRow(for: key)
            }
            .padding(.bottom, 8)
        }
    }

    private func secondaryRow(for key: String) -> some View {
        let timing = prayers.day?.timings.first(where: { $0.id == key })
        let config = audio.secondaryAlerts[key] ?? SecondaryAlertDefaults.values[key]!
        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(PrayerName.labels[key] ?? key)
                Spacer()
                if let timing {
                    Text(timing.displayTime)
                        .foregroundStyle(.secondary)
                }
                Toggle("", isOn: Binding(
                    get: { audio.secondaryAlerts[key]?.enabled ?? false },
                    set: { audio.setSecondaryEnabled(key, enabled: $0) }
                ))
                .labelsHidden()
                .toggleStyle(.switch)
                .controlSize(.mini)
            }
            .padding(.horizontal, 14)

            if config.enabled {
                HStack {
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

                    Button {
                        audio.playAlarmPreview(soundId: audio.secondaryAlerts[key]?.soundId ?? AlarmSound.all[0].id)
                    } label: {
                        Image(systemName: "play.circle")
                    }
                    .buttonStyle(.plain)
                    .help("Preview alarm")
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 4)
            }
        }
        .padding(.vertical, 4)
    }

    private var audioSection: some View {
        VStack(alignment: .leading, spacing: 8) {
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
                    Label("Play Amman Jordan Adhan now", systemImage: "play.fill")
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }

            Text(audio.statusLine)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(14)
    }

    private var actionsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                Task { await prayers.refresh() }
            } label: {
                Label("Refresh times", systemImage: "arrow.clockwise")
            }
            .buttonStyle(.plain)

            Divider().opacity(0.35)

            Button(role: .destructive) {
                onQuit()
            } label: {
                HStack {
                    Text("Quit Athan")
                    Spacer()
                    Text("⌘Q")
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)
            .keyboardShortcut("q", modifiers: .command)
        }
        .padding(14)
    }
}
