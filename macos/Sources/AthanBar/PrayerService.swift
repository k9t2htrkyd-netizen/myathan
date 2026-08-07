import Foundation

@MainActor
final class PrayerService: ObservableObject {
    @Published var day: PrayerDay?
    @Published var statusText = "Loading…"
    @Published var nextPrayer: PrayerTiming?
    @Published var countdownText = "--:--:--"
    @Published var menuBarText = "Athan"

    @Published var latitude: Double = 27.9506
    @Published var longitude: Double = -82.4572
    @Published var locationLabel: String = "Tampa, Florida, United States"
    @Published var method: Int = 2
    @Published var school: Int = 0

    private var refreshTimer: Timer?
    private var tickTimer: Timer?
    private let defaults = UserDefaults.standard

    init() {
        loadSavedLocation()
        startTimers()
        Task { await refresh() }
    }

    deinit {
        refreshTimer?.invalidate()
        tickTimer?.invalidate()
    }

    func startTimers() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 60 * 30, repeats: true) { [weak self] _ in
            Task { @MainActor in await self?.refresh() }
        }
        tickTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.updateNextAndCountdown() }
        }
        RunLoop.main.add(refreshTimer!, forMode: .common)
        RunLoop.main.add(tickTimer!, forMode: .common)
    }

    func loadSavedLocation() {
        if defaults.object(forKey: "latitude") != nil {
            latitude = defaults.double(forKey: "latitude")
            longitude = defaults.double(forKey: "longitude")
            locationLabel = defaults.string(forKey: "locationLabel") ?? locationLabel
            method = defaults.integer(forKey: "method").nonZeroOr(2)
            school = defaults.integer(forKey: "school")
        }
    }

    func saveLocation() {
        defaults.set(latitude, forKey: "latitude")
        defaults.set(longitude, forKey: "longitude")
        defaults.set(locationLabel, forKey: "locationLabel")
        defaults.set(method, forKey: "method")
        defaults.set(school, forKey: "school")
    }

    func useDeviceLocation() async {
        statusText = "Requesting location…"
        let locator = LocationHelper()
        do {
            let coord = try await locator.requestCoordinate()
            latitude = coord.latitude
            longitude = coord.longitude
            if let place = try? await reverseGeocode(lat: latitude, lon: longitude) {
                locationLabel = place
            } else {
                locationLabel = String(format: "%.3f, %.3f", latitude, longitude)
            }
            saveLocation()
            await refresh()
        } catch {
            statusText = "Location unavailable — using saved place"
        }
    }

    func refresh() async {
        statusText = "Updating prayer times…"
        let dateParam = Self.apiDateParam(timezone: day?.timezone)
        let urlString =
            "https://api.aladhan.com/v1/timings/\(dateParam)" +
            "?latitude=\(latitude)&longitude=\(longitude)&method=\(method)&school=\(school)"

        guard let url = URL(string: urlString) else {
            statusText = "Bad request URL"
            return
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                statusText = "Could not load times"
                return
            }
            let decoded = try JSONDecoder().decode(AladhanResponse.self, from: data)
            guard decoded.code == 200 else {
                statusText = decoded.status
                return
            }

            let timingsDict = decoded.data.timings
            var list: [PrayerTiming] = []
            for key in PrayerName.order {
                guard let value = timingsDict[key] else { continue }
                let clean = String(value.prefix(5))
                list.append(
                    PrayerTiming(
                        id: key,
                        name: PrayerName.labels[key] ?? key,
                        time24: clean,
                        playsAdhan: PrayerName.adhanPrayers.contains(key)
                    )
                )
            }

            let g = decoded.data.date.gregorian
            let h = decoded.data.date.hijri
            let tz = decoded.data.meta.timezone
            day = PrayerDay(
                locationLabel: locationLabel,
                methodName: decoded.data.meta.method.name,
                timezone: tz,
                gregorian: "\(g.weekday.en), \(Int(g.day) ?? 0) \(g.month.en) \(g.year)",
                hijri: "\(h.day) \(h.month.en) \(h.year) AH",
                timings: list
            )
            if !tz.isEmpty {
                // keep for countdown
            }
            statusText = "Times ready"
            updateNextAndCountdown()
        } catch {
            statusText = "Network error"
            print("Prayer refresh failed: \(error)")
        }
    }

    func updateNextAndCountdown() {
        guard let day else { return }
        let nowParts = Self.localParts(timezone: day.timezone)
        let nowMinutes = nowParts.hour * 60 + nowParts.minute
        let nowSeconds = nowParts.hour * 3600 + nowParts.minute * 60 + nowParts.second

        var next: PrayerTiming?
        var tomorrow = false
        for timing in day.timings {
            if Self.minutes(timing.time24) > nowMinutes {
                next = timing
                break
            }
        }
        if next == nil, let fajr = day.timings.first(where: { $0.id == "Fajr" }) {
            next = fajr
            tomorrow = true
        }

        nextPrayer = next
        if let next {
            let target = Self.seconds(next.time24) + (tomorrow ? 86400 : 0)
            var remaining = target - nowSeconds
            if remaining < 0 { remaining += 86400 }
            let h = remaining / 3600
            let m = (remaining % 3600) / 60
            let s = remaining % 60
            countdownText = String(format: "%02d:%02d:%02d", h, m, s)
            menuBarText = "\(next.name) \(next.displayTime)"
        } else {
            countdownText = "--:--:--"
            menuBarText = "Athan"
        }
    }

    func currentAdhanPrayerIfDue() -> PrayerTiming? {
        guard let day else { return nil }
        let parts = Self.localParts(timezone: day.timezone)
        let nowMinutes = parts.hour * 60 + parts.minute
        return day.timings.first {
            $0.playsAdhan && Self.minutes($0.time24) == nowMinutes
        }
    }

    private func reverseGeocode(lat: Double, lon: Double) async throws -> String {
        let url = URL(string:
            "https://api.bigdatacloud.net/data/reverse-geocode-client?latitude=\(lat)&longitude=\(lon)&localityLanguage=en"
        )!
        let (data, _) = try await URLSession.shared.data(from: url)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let city = (json?["city"] as? String)
            ?? (json?["locality"] as? String)
            ?? (json?["principalSubdivision"] as? String)
            ?? "Current location"
        let region = json?["principalSubdivision"] as? String ?? ""
        let country = json?["countryName"] as? String ?? ""
        return [city, region, country].filter { !$0.isEmpty }.joined(separator: ", ")
    }

    static func minutes(_ time24: String) -> Int {
        let parts = time24.split(separator: ":").compactMap { Int($0) }
        guard parts.count >= 2 else { return 0 }
        return parts[0] * 60 + parts[1]
    }

    static func seconds(_ time24: String) -> Int {
        minutes(time24) * 60
    }

    static func localParts(timezone: String) -> (year: Int, month: Int, day: Int, hour: Int, minute: Int, second: Int) {
        var calendar = Calendar(identifier: .gregorian)
        if let tz = TimeZone(identifier: timezone) {
            calendar.timeZone = tz
        }
        let now = Date()
        let c = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: now)
        return (
            c.year ?? 0,
            c.month ?? 0,
            c.day ?? 0,
            c.hour ?? 0,
            c.minute ?? 0,
            c.second ?? 0
        )
    }

    static func apiDateParam(timezone: String?) -> String {
        let parts = localParts(timezone: timezone ?? TimeZone.current.identifier)
        return String(format: "%02d-%02d-%04d", parts.day, parts.month, parts.year)
    }
}

private extension Int {
    func nonZeroOr(_ fallback: Int) -> Int {
        self == 0 ? fallback : self
    }
}

// MARK: - API models

struct AladhanResponse: Decodable {
    let code: Int
    let status: String
    let data: AladhanData
}

struct AladhanData: Decodable {
    let timings: [String: String]
    let date: AladhanDate
    let meta: AladhanMeta
}

struct AladhanDate: Decodable {
    let gregorian: AladhanGregorian
    let hijri: AladhanHijri
}

struct AladhanGregorian: Decodable {
    let day: String
    let year: String
    let weekday: Named
    let month: NamedMonth
}

struct AladhanHijri: Decodable {
    let day: String
    let year: String
    let month: NamedMonth
}

struct Named: Decodable {
    let en: String
}

struct NamedMonth: Decodable {
    let en: String
}

struct AladhanMeta: Decodable {
    let timezone: String
    let method: NamedMethod
}

struct NamedMethod: Decodable {
    let name: String
}
