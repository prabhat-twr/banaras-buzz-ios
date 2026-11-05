// Panchang data and calculations shared by the app and the widget extension.
//
// Same logic as the Android app (Alerts.kt / Sticky.kt / Data.kt): the daily panchang comes from
// the vns-news-api JSON feeds; when they are missing, sunrise, sunset, Rahu Kaal and Abhijit are
// worked out on the device from Varanasi's coordinates.
import Foundation

// MARK: - Dates (all in IST, days as "yyyy-MM-dd" keys)

let pkIST = TimeZone(identifier: "Asia/Kolkata")!

var pkCalendar: Calendar {
    var c = Calendar(identifier: .gregorian)
    c.timeZone = pkIST
    return c
}

private let pkKeyFormatter: DateFormatter = {
    let f = DateFormatter()
    f.calendar = Calendar(identifier: .gregorian)
    f.locale = Locale(identifier: "en_US_POSIX")
    f.timeZone = pkIST
    f.dateFormat = "yyyy-MM-dd"
    return f
}()

private let pkClockFormatter: DateFormatter = {
    let f = DateFormatter()
    f.locale = Locale(identifier: "en_US_POSIX")
    f.timeZone = pkIST
    f.dateFormat = "h:mm a"
    return f
}()

private let pkClockPaddedFormatter: DateFormatter = {
    let f = DateFormatter()
    f.locale = Locale(identifier: "en_US_POSIX")
    f.timeZone = pkIST
    f.dateFormat = "hh:mm a"
    return f
}()

func pkDayKey(_ date: Date) -> String { pkKeyFormatter.string(from: date) }
func pkTodayKey() -> String { pkDayKey(Date()) }

/// Midnight IST at the start of a day key.
func pkStartOfDay(_ key: String) -> Date? { pkKeyFormatter.date(from: key) }

func pkAddDays(_ key: String, _ n: Int) -> String {
    guard let d = pkStartOfDay(key), let r = pkCalendar.date(byAdding: .day, value: n, to: d) else { return key }
    return pkDayKey(r)
}

/// 0 = Monday … 6 = Sunday.
func pkWeekdayMon0(_ key: String) -> Int {
    guard let d = pkStartOfDay(key) else { return 0 }
    return (pkCalendar.component(.weekday, from: d) + 5) % 7
}

/// "1:04 PM"
func pkClock(_ date: Date?) -> String { date.map { pkClockFormatter.string(from: $0) } ?? "" }
/// "06:07 AM"
func pkClockPadded(_ date: Date?) -> String { date.map { pkClockPaddedFormatter.string(from: $0) } ?? "" }

let pkMonthsHi = ["जनवरी", "फ़रवरी", "मार्च", "अप्रैल", "मई", "जून", "जुलाई", "अगस्त", "सितंबर", "अक्टूबर", "नवंबर", "दिसंबर"]
let pkWeekdaysHi = ["सोमवार", "मंगलवार", "बुधवार", "गुरुवार", "शुक्रवार", "शनिवार", "रविवार"]
let pkWeekdaysShortHi = ["सोम", "मंगल", "बुध", "गुरु", "शुक्र", "शनि", "रवि"]

private func pkParts(_ key: String) -> (y: Int, m: Int, d: Int)? {
    let p = key.split(separator: "-").compactMap { Int($0) }
    return p.count == 3 ? (p[0], p[1], p[2]) : nil
}

/// "गुरुवार, 5 नवंबर 2026"
func pkHindiLongDate(_ key: String) -> String {
    guard let p = pkParts(key) else { return key }
    return "\(pkWeekdaysHi[pkWeekdayMon0(key)]), \(p.d) \(pkMonthsHi[p.m - 1]) \(p.y)"
}

/// "5 नवंबर"
func pkHindiShortDate(_ key: String) -> String {
    guard let p = pkParts(key) else { return key }
    return "\(p.d) \(pkMonthsHi[p.m - 1])"
}

func pkDayOfMonth(_ key: String) -> Int { pkParts(key)?.d ?? 0 }
func pkMonthHi(_ key: String) -> String { pkParts(key).map { pkMonthsHi[$0.m - 1] } ?? "" }

private let pkIsoParser: ISO8601DateFormatter = {
    let f = ISO8601DateFormatter()
    f.formatOptions = [.withInternetDateTime]
    return f
}()

func pkParseIso(_ s: Any?) -> Date? {
    guard let s = s as? String, !s.isEmpty else { return nil }
    return pkIsoParser.date(from: s)
}

// MARK: - Hindi names

let pkTithiHi: [String: String] = [
    "pratipada": "प्रतिपदा", "dwitiya": "द्वितीया", "tritiya": "तृतीया", "chaturthi": "चतुर्थी",
    "panchami": "पंचमी", "shashthi": "षष्ठी", "saptami": "सप्तमी", "ashtami": "अष्टमी", "navami": "नवमी",
    "dashami": "दशमी", "ekadashi": "एकादशी", "dwadashi": "द्वादशी", "trayodashi": "त्रयोदशी",
    "chaturdashi": "चतुर्दशी", "purnima": "पूर्णिमा", "amavasya": "अमावस्या",
]

func pkTithiInHindi(_ name: String) -> String { pkTithiHi[name.lowercased()] ?? name }

func pkPakshaInHindi(_ p: String?) -> String {
    switch p?.lowercased() {
    case "shukla": return "शुक्ल पक्ष"
    case "krishna": return "कृष्ण पक्ष"
    default: return p ?? ""
    }
}

// MARK: - Models

struct PAnga: Hashable {
    let name: String
    let nameHi: String?
    let paksha: String?
    let endsAt: Date?
    var display: String { nameHi ?? name }
}

struct PWindow: Hashable {
    let start: Date
    let end: Date
    func contains(_ d: Date) -> Bool { d >= start && d < end }
    var range: String { "\(pkClock(start)) – \(pkClock(end))" }
}

/// One day's panchang, as published in the daily / 8-day / year files.
struct PDay {
    let date: String
    let varaHi: String?
    let monthHi: String?
    let tithi: [PAnga]
    let nakshatra: [PAnga]
    let yoga: [PAnga]
    let karana: [PAnga]
    let sunrise: Date?
    let sunset: Date?
    let moonrise: Date?
    let moonset: Date?
    let rahu: PWindow?
    let yamaganda: PWindow?
    let gulika: PWindow?
    let abhijit: PWindow?
    let festivals: [String]
}

struct PObservance: Identifiable, Hashable {
    let id: String
    let name: String
    let nameHi: String?
    let type: String
    let date: String
    let tithi: String
    let paksha: String
    let description: String
    var display: String { nameHi ?? name }
    var typeHi: String { type == "vrat" ? "व्रत" : type == "both" ? "व्रत व त्योहार" : "त्योहार" }
}

private func pkAngas(_ any: Any?) -> [PAnga] {
    guard let arr = any as? [[String: Any]] else { return [] }
    return arr.compactMap { o in
        guard let name = o["name"] as? String, !name.isEmpty else { return nil }
        return PAnga(
            name: name,
            nameHi: (o["name_hi"] as? String).flatMap { $0.isEmpty ? nil : $0 },
            paksha: (o["paksha"] as? String).flatMap { $0.isEmpty ? nil : $0 },
            endsAt: pkParseIso(o["ends_at"])
        )
    }
}

private func pkWindow(_ any: Any?) -> PWindow? {
    guard let o = any as? [String: Any], let s = pkParseIso(o["start"]), let e = pkParseIso(o["end"]), e > s else { return nil }
    return PWindow(start: s, end: e)
}

func parsePDay(_ any: Any?) -> PDay? {
    guard let o = any as? [String: Any], let date = o["date"] as? String, !date.isEmpty else { return nil }
    let festivals: [String] = ((o["festivals_and_vrats"] as? [Any]) ?? []).compactMap {
        if let s = $0 as? String { return s.isEmpty ? nil : s }
        if let f = $0 as? [String: Any] { return (f["name_hi"] as? String) ?? (f["name"] as? String) }
        return nil
    }
    let month = o["lunar_month"] as? [String: Any]
    return PDay(
        date: date,
        varaHi: o["vara_hi"] as? String,
        monthHi: (month?["purnimanta_hi"] as? String) ?? (month?["purnimanta"] as? String),
        tithi: pkAngas(o["tithi"]),
        nakshatra: pkAngas(o["nakshatra"]),
        yoga: pkAngas(o["yoga"]),
        karana: pkAngas(o["karana"]),
        sunrise: pkParseIso(o["sunrise"]),
        sunset: pkParseIso(o["sunset"]),
        moonrise: pkParseIso(o["moonrise"]),
        moonset: pkParseIso(o["moonset"]),
        rahu: pkWindow(o["rahu_kaal"]),
        yamaganda: pkWindow(o["yamaganda_kaal"]),
        gulika: pkWindow(o["gulika_kaal"]),
        abhijit: pkWindow(o["abhijit_muhurat"]),
        festivals: festivals
    )
}

func parsePObservances(_ any: Any?) -> [PObservance] {
    guard let arr = any as? [[String: Any]] else { return [] }
    return arr.compactMap { o -> PObservance? in
        guard let name = o["name"] as? String, !name.isEmpty, let date = o["date"] as? String, !date.isEmpty else { return nil }
        return PObservance(
            id: (o["id"] as? String) ?? "\(name)-\(date)",
            name: name,
            nameHi: (o["name_hi"] as? String).flatMap { $0.isEmpty ? nil : $0 },
            type: (o["type"] as? String) ?? "tyohar",
            date: date,
            tithi: (o["tithi"] as? String) ?? "",
            paksha: (o["paksha"] as? String) ?? "",
            description: (o["description"] as? String) ?? ""
        )
    }.sorted { $0.date < $1.date }
}

/// Day entries of the 8-day or year file, by date.
func parsePDays(_ root: Any?) -> [String: PDay] {
    guard let o = root as? [String: Any], let arr = o["days"] as? [Any] else { return [:] }
    var out: [String: PDay] = [:]
    for item in arr { if let d = parsePDay(item) { out[d.date] = d } }
    return out
}

// MARK: - Sunrise / sunset on the device (NOAA solar equations, about a minute's accuracy)

enum SolarDay {
    private static let lat = 25.3176
    private static let lng = 82.9739
    private static let altitude = -0.833 // upper limb at the horizon, with refraction

    private static func rad(_ d: Double) -> Double { d * .pi / 180 }
    private static func deg(_ r: Double) -> Double { r * 180 / .pi }

    /// Solar declination (degrees) and equation of time (minutes).
    private static func sun(_ date: Date) -> (Double, Double) {
        let jd = date.timeIntervalSince1970 / 86400 + 2440587.5
        let t = (jd - 2451545.0) / 36525.0
        let l0 = (280.46646 + t * (36000.76983 + t * 0.0003032)).truncatingRemainder(dividingBy: 360)
        let m = 357.52911 + t * (35999.05029 - 0.0001537 * t)
        let e = 0.016708634 - t * (0.000042037 + 0.0000001267 * t)
        let c = sin(rad(m)) * (1.914602 - t * (0.004817 + 0.000014 * t)) +
            sin(rad(2 * m)) * (0.019993 - 0.000101 * t) + sin(rad(3 * m)) * 0.000289
        let omega = 125.04 - 1934.136 * t
        let lambda = l0 + c - 0.00569 - 0.00478 * sin(rad(omega))
        let eps0 = 23 + (26 + (21.448 - t * (46.815 + t * (0.00059 - t * 0.001813))) / 60) / 60
        let eps = eps0 + 0.00256 * cos(rad(omega))
        let dec = deg(asin(sin(rad(eps)) * sin(rad(lambda))))
        let y = pow(tan(rad(eps / 2)), 2)
        let eot = 4 * deg(
            y * sin(2 * rad(l0)) - 2 * e * sin(rad(m)) + 4 * e * y * sin(rad(m)) * cos(2 * rad(l0)) -
                0.5 * y * y * sin(4 * rad(l0)) - 1.25 * e * e * sin(2 * rad(m))
        )
        return (dec, eot)
    }

    /// Sunrise (rising) or sunset on a day key, IST.
    static func event(_ key: String, rising: Bool) -> Date {
        let parts = key.split(separator: "-").compactMap { Int($0) }
        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = TimeZone(identifier: "UTC")!
        let midnightUtc = utc.date(from: DateComponents(year: parts.first, month: parts.dropFirst().first, day: parts.last)) ?? Date()
        var minutes = rising ? 0.0 : 720.0
        for _ in 0..<4 {
            let (dec, eot) = sun(midnightUtc.addingTimeInterval(minutes * 60))
            let cosH = (sin(rad(altitude)) - sin(rad(lat)) * sin(rad(dec))) / (cos(rad(lat)) * cos(rad(dec)))
            let h = deg(acos(max(-1, min(1, cosH))))
            let noon = 720 - 4 * lng - eot
            minutes = rising ? noon - 4 * h : noon + 4 * h
        }
        return midnightUtc.addingTimeInterval(minutes * 60)
    }
}

// Which eighth of the daytime Rahu Kaal occupies, Monday first.
private let pkRahuPart = [2, 7, 5, 6, 4, 3, 8]

struct PDayWindows {
    let rahu: PWindow
    let abhijit: PWindow
    let sunrise: Date
    let sunset: Date
}

/// Rahu Kaal and Abhijit for a day: from the panchang file when we have that day, else calculated.
func pkWindows(_ key: String, day: PDay?) -> PDayWindows {
    let rise = SolarDay.event(key, rising: true)
    let set = SolarDay.event(key, rising: false)
    let len = set.timeIntervalSince(rise)
    let part = len / 8
    let rahuStart = rise.addingTimeInterval(part * Double(pkRahuPart[pkWeekdayMon0(key)] - 1))
    let muhurta = len / 15
    let abhijitStart = rise.addingTimeInterval(muhurta * 7)
    let calc = PDayWindows(
        rahu: PWindow(start: rahuStart, end: rahuStart.addingTimeInterval(part)),
        abhijit: PWindow(start: abhijitStart, end: abhijitStart.addingTimeInterval(muhurta)),
        sunrise: rise, sunset: set
    )
    guard let d = day, d.date == key else { return calc }
    return PDayWindows(
        rahu: d.rahu ?? calc.rahu,
        abhijit: d.abhijit ?? calc.abhijit,
        sunrise: d.sunrise ?? calc.sunrise,
        sunset: d.sunset ?? calc.sunset
    )
}

/// Abhijit Muhurat is traditionally not observed on Wednesdays.
func pkShubhObserved(_ key: String) -> Bool { pkWeekdayMon0(key) != 2 }

// MARK: - "What's happening now" (widgets and the in-app banner)

struct PStatus {
    let date: String
    let title: String
    let shortTitle: String
    let line2: String
    let countdownTo: Date?
    let countdownLabel: String?
    let inRahu: Bool
    let inShubh: Bool
    let rahuRange: String
    let shubhRange: String?
    /// When this status next changes (a period starts or ends, or midnight).
    let nextChange: Date
}

func pkStatus(at now: Date, today: PDay?, tomorrow: PDay?) -> PStatus {
    let key = pkDayKey(now)
    let day = today?.date == key ? today : nil
    let w = pkWindows(key, day: day)
    let shubhToday = pkShubhObserved(key)
    let inRahu = w.rahu.contains(now)
    let inShubh = shubhToday && w.abhijit.contains(now)
    let midnight = pkStartOfDay(pkAddDays(key, 1)) ?? now.addingTimeInterval(86400)

    var upcoming: [(String, PWindow)] = []
    if w.rahu.start > now { upcoming.append(("राहुकाल", w.rahu)) }
    if shubhToday && w.abhijit.start > now { upcoming.append(("शुभ मुहूर्त", w.abhijit)) }
    let next = upcoming.min { $0.1.start < $1.1.start }

    let title: String, short: String
    var countdown: Date? = nil
    var label: String? = nil
    if inRahu {
        title = "🌑 राहुकाल चल रहा है · \(pkClock(w.rahu.end)) तक"; short = "🌑 राहुकाल · \(pkClock(w.rahu.end)) तक"
        countdown = w.rahu.end; label = "समाप्त होने में"
    } else if inShubh {
        title = "✨ शुभ मुहूर्त चल रहा है · \(pkClock(w.abhijit.end)) तक"; short = "✨ शुभ मुहूर्त · \(pkClock(w.abhijit.end)) तक"
        countdown = w.abhijit.end; label = "समाप्त होने में"
    } else if let n = next {
        title = "आगे: \(n.0) \(pkClock(n.1.start)) से"; short = "\(n.0) \(pkClock(n.1.start)) से"
        countdown = n.1.start; label = "शुरू होने में"
    } else {
        let tKey = pkAddDays(key, 1)
        let tw = pkWindows(tKey, day: tomorrow?.date == tKey ? tomorrow : nil)
        title = "आज के राहुकाल व शुभ मुहूर्त बीत चुके · कल राहुकाल \(pkClock(tw.rahu.start))"
        short = "कल राहुकाल \(pkClock(tw.rahu.start))"
    }

    let tithi = day?.tithi.first.map { [pkPakshaInHindi($0.paksha).replacingOccurrences(of: " पक्ष", with: ""), $0.display].filter { !$0.isEmpty }.joined(separator: " ") }
    let nak = day?.nakshatra.first?.display
    let line2 = [tithi, nak].compactMap { $0 }.joined(separator: " · ")
    let changes = [w.rahu.start, w.rahu.end, w.abhijit.start, w.abhijit.end, midnight].filter { $0 > now }

    return PStatus(
        date: key, title: title, shortTitle: short,
        line2: line2.isEmpty ? "सूर्योदय \(pkClock(w.sunrise)) · सूर्यास्त \(pkClock(w.sunset))" : line2,
        countdownTo: countdown, countdownLabel: label, inRahu: inRahu, inShubh: inShubh,
        rahuRange: w.rahu.range, shubhRange: shubhToday ? w.abhijit.range : nil,
        nextChange: changes.min() ?? midnight
    )
}

// MARK: - Network

let pkRawBase = "https://raw.githubusercontent.com/prabhat-twr/vns-news-api/main/"

enum PKFetchResult {
    case ok(Data)
    case notFound
    case failed
}

/// Downloads one feed file, bypassing caches (a per-minute query keeps GitHub's CDN honest).
func pkFetch(_ name: String, timeout: TimeInterval = 15) async -> PKFetchResult {
    guard let url = URL(string: pkRawBase + name + "?t=\(Int(Date().timeIntervalSince1970 / 60))") else { return .failed }
    var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: timeout)
    request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
    do {
        let (data, response) = try await URLSession.shared.data(for: request)
        let code = (response as? HTTPURLResponse)?.statusCode ?? 0
        if code == 404 { return .notFound }
        return code == 200 ? .ok(data) : .failed
    } catch {
        return .failed
    }
}

func pkJSON(_ data: Data?) -> Any? {
    guard let data else { return nil }
    return try? JSONSerialization.jsonObject(with: data)
}
