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
}
