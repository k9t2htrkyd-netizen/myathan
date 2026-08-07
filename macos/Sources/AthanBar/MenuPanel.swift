import SwiftUI

struct MenuPanel: View {
    @ObservedObject var prayers: PrayerService
    @ObservedObject var audio: AdhanPlayer
    var onQuit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider().opacity(0.35)
            nextSection
            Divider().opacity(0.35)
            prayerList
            Divider().opacity(0.35)
            audioSection
            Divider().opacity(0.35)
            actionsSection
        }
        .frame(width: 320)
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
            Text("Today")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 14)
                .padding(.top, 10)
                .padding(.bottom, 4)

            ForEach(prayers.day?.timings.filter { ["Fajr", "Dhuhr", "Asr", "Maghrib", "Isha"].contains($0.id) } ?? []) { timing in
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
        }
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

            Button {
                audio.playNow()
            } label: {
                Label("Play Amman Jordan Adhan now", systemImage: "play.fill")
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)

            Text(audio.statusLine)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(14)
    }

    private var actionsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                Task { await prayers.useDeviceLocation() }
            } label: {
                Label("Use my location", systemImage: "location.fill")
            }
            .buttonStyle(.plain)

            Button {
                Task { await prayers.refresh() }
            } label: {
                Label("Refresh times", systemImage: "arrow.clockwise")
            }
            .buttonStyle(.plain)

            Button {
                if let url = URL(string: "http://127.0.0.1:8765/") {
                    NSWorkspace.shared.open(url)
                }
            } label: {
                Label("Open web player", systemImage: "safari")
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
