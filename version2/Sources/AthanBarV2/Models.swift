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
    /// Remote CDN / HTTPS URL for this sound.
    let remoteURL: String?
    /// Public HTTPS URL Nest/Chromecast can fetch. Matches the selected sound.
    var cloudURL: URL? {
        if let remoteURL, let url = URL(string: remoteURL) {
            return url
        }
        guard let fileName else { return nil }
        if Self.alarms.contains(where: { $0.id == id }) {
            return URL(string: "https://myathan.link/audio/alarms/\(fileName).mp3")
        }
        return URL(string: "https://myathan.link/audio/\(fileName).mp3")
    }

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
            name: "Adhan by Alafasy - style 1",
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
            name: "Adhan by Ma'rouf Rashad Al-Sharif from Jordan",
            fileName: "athan-amman-jordan",
            remoteURL: "https://myathan.link/audio/athan-amman-jordan.mp3"
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

struct CustomDailyAlarm: Identifiable, Equatable, Codable {
    var id: String
    var name: String
    var hour: Int
    var minute: Int
    var enabled: Bool
    var soundId: String

    var time24: String { String(format: "%02d:%02d", hour, minute) }
    var displayTime: String { PrayerTiming.formatDisplay(time24) }
}

struct CalculationMethod: Identifiable, Hashable {
    let id: Int
    let name: String
    let shortName: String

    static let all: [CalculationMethod] = [
        .init(id: 2, name: "Islamic Society of North America (ISNA)", shortName: "ISNA"),
        .init(id: 3, name: "Muslim World League", shortName: "Muslim World League"),
        .init(id: 4, name: "Umm Al-Qura University, Makkah", shortName: "Umm Al-Qura"),
        .init(id: 5, name: "Egyptian General Authority of Survey", shortName: "Egyptian"),
        .init(id: 1, name: "University of Islamic Sciences, Karachi", shortName: "Karachi"),
        .init(id: 8, name: "Gulf Region", shortName: "Gulf"),
        .init(id: 9, name: "Kuwait", shortName: "Kuwait"),
        .init(id: 10, name: "Qatar", shortName: "Qatar"),
        .init(id: 13, name: "Diyanet İşleri Başkanlığı, Turkey", shortName: "Diyanet"),
        .init(id: 16, name: "Dubai", shortName: "Dubai"),
    ]
}
