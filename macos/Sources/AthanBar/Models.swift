import Foundation

struct PrayerTiming: Identifiable, Equatable {
    let id: String
    let name: String
    let time24: String
    let playsAdhan: Bool

    var displayTime: String {
        Self.formatDisplay(time24)
    }

    static func formatDisplay(_ time24: String) -> String {
        let parts = time24.split(separator: ":").compactMap { Int($0) }
        guard parts.count >= 2 else { return time24 }
        var hour = parts[0]
        let minute = parts[1]
        let period = hour >= 12 ? "PM" : "AM"
        hour = hour % 12
        if hour == 0 { hour = 12 }
        return String(format: "%d:%02d %@", hour, minute, period)
    }
}

struct PrayerDay: Equatable {
    var locationLabel: String
    var methodName: String
    var timezone: String
    var gregorian: String
    var hijri: String
    var timings: [PrayerTiming]
}

enum PrayerName {
    static let order = [
        "Fajr", "Sunrise", "Dhuhr", "Asr", "Maghrib", "Isha",
        "Midnight", "Firstthird", "Lastthird"
    ]

    static let labels: [String: String] = [
        "Fajr": "Fajr",
        "Sunrise": "Sunrise",
        "Dhuhr": "Dhuhr",
        "Asr": "Asr",
        "Maghrib": "Maghrib",
        "Isha": "Isha",
        "Midnight": "Midnight",
        "Firstthird": "First Third",
        "Lastthird": "Tahajjud"
    ]

    static let adhanPrayers: Set<String> = [
        "Fajr", "Dhuhr", "Asr", "Maghrib", "Isha"
    ]

    static let secondaryTimes = [
        "Sunrise", "Midnight", "Firstthird", "Lastthird"
    ]
}

struct AlarmSound: Identifiable, Hashable {
    let id: String
    let name: String
    /// Local bundle resource name without extension (alarms/ or root).
    let fileName: String?
    /// Remote CDN / HTTP URL when not bundled locally.
    let remoteURL: String?

    static let alarms: [AlarmSound] = [
        .init(id: "classic-alarm", name: "Classic Alarm", fileName: "classic-alarm", remoteURL: nil),
        .init(id: "digital-clock-beep", name: "Digital Clock Beep", fileName: "digital-clock-beep", remoteURL: nil),
        .init(id: "facility-alarm", name: "Facility Alarm", fileName: "facility-alarm", remoteURL: nil),
        .init(id: "alert-alarm", name: "Alert Alarm", fileName: "alert-alarm", remoteURL: nil),
        .init(id: "positive-notification", name: "Positive Notification", fileName: "positive-notification", remoteURL: nil),
        .init(id: "correct-answer-tone", name: "Correct Answer Tone", fileName: "correct-answer-tone", remoteURL: nil),
        .init(id: "game-notification-wave", name: "Rooster", fileName: "game-notification-wave", remoteURL: nil),
        .init(id: "software-interface-start", name: "Interface Start", fileName: "software-interface-start", remoteURL: nil),
    ]

    static let adhans: [AlarmSound] = [
        .init(
            id: "adhan-alafasy",
            name: "Yet Another Adhan by Mishary Rashid Alafasy",
            fileName: nil,
            remoteURL: "https://cdn.aladhan.com/audio/adhans/a9.mp3"
        ),
        .init(
            id: "adhan-nafees",
            name: "Adhan by Ahmad al-Nafees",
            fileName: nil,
            remoteURL: "https://cdn.aladhan.com/audio/adhans/a1.mp3"
        ),
        .init(
            id: "adhan-turkey",
            name: "Adhan by Hafiz Mustafa Özcan from Turkey",
            fileName: nil,
            remoteURL: "https://cdn.aladhan.com/audio/adhans/a2.mp3"
        ),
        .init(
            id: "adhan-jenkins",
            name: "Adhan from Karl Jenkins' Mass for Peace",
            fileName: nil,
            remoteURL: "https://cdn.aladhan.com/audio/adhans/a3.mp3"
        ),
        .init(
            id: "adhan-dubai",
            name: "Adhan from Dubai's One TV by Mishary Rashid Alafasy",
            fileName: nil,
            remoteURL: "https://cdn.aladhan.com/audio/adhans/a4.mp3"
        ),
        .init(
            id: "adhan-alafasy2",
            name: "Another Adhan by Mishary Rashid Alafasy",
            fileName: nil,
            remoteURL: "https://cdn.aladhan.com/audio/adhans/a7.mp3"
        ),
        .init(
            id: "adhan-zahrani",
            name: "Adhan by Mansour Al-Zahrani",
            fileName: nil,
            remoteURL: "https://cdn.aladhan.com/audio/adhans/a11-mansour-al-zahrani.mp3"
        ),
        .init(
            id: "adhan-jordan",
            name: "Athan Amman Jordan — Ma'rouf Rashad Al-Sharif",
            fileName: "athan-amman-jordan",
            remoteURL: nil
        ),
    ]

    static let all: [AlarmSound] = alarms + adhans
}

struct SecondaryAlertConfig: Equatable, Codable {
    var enabled: Bool
    var soundId: String
}

enum SecondaryAlertDefaults {
    static let values: [String: SecondaryAlertConfig] = [
        "Sunrise": .init(enabled: false, soundId: "positive-notification"),
        "Midnight": .init(enabled: false, soundId: "digital-clock-beep"),
        "Firstthird": .init(enabled: false, soundId: "correct-answer-tone"),
        "Lastthird": .init(enabled: false, soundId: "classic-alarm"),
    ]
}
