// Ported from the Android app's data/PanchangRepository.kt.
import Foundation

private let PANCHANG_DAILY_URL = "https://raw.githubusercontent.com/prabhat-twr/vns-news-api/main/varanasi-panchang-daily.json"
private let PANCHANG_CALENDAR_URL = "https://raw.githubusercontent.com/prabhat-twr/vns-news-api/main/varanasi-panchang-calendar.json"

private let hhmmFormatter: DateFormatter = {
    let f = DateFormatter()
    f.timeZone = istTimeZone
    f.dateFormat = "HH:mm"
    return f
}()

private let panchangIso: ISO8601DateFormatter = {
    let f = ISO8601DateFormatter()
    f.formatOptions = [.withInternetDateTime, .withTimeZone]
    return f
}()

private func formatIso(_ iso: String?) -> String? {
    guard let iso, !iso.isEmpty else { return nil }
    guard let date = panchangIso.date(from: iso) else { return nil }
    return hhmmFormatter.string(from: date)
}

private actor PanchangCache {
    static let shared = PanchangCache()
    var day: PanchangDay?
    var observances: [Observance]?
    func setDay(_ v: PanchangDay?) { day = v }
    func setObservances(_ v: [Observance]) { observances = v }
}

private func angaList(_ arr: [[String: Any]]?) -> [PanchangAnga] {
    guard let arr else { return [] }
    return arr.map { obj in
        PanchangAnga(
            name: (obj["name"] as? String) ?? "",
            paksha: (obj["paksha"] as? String).flatMap { $0.isEmpty ? nil : $0 },
            endsAt: formatIso(obj["ends_at"] as? String)
        )
    }
}

private func window(_ obj: [String: Any]?) -> PanchangWindow? {
    guard let obj else { return nil }
    guard let start = formatIso(obj["start"] as? String), let end = formatIso(obj["end"] as? String) else { return nil }
    return PanchangWindow(start: start, end: end)
}

/// Fetches varanasi-panchang-daily.json (produced daily by a scheduled Claude run against the
/// varanasi-panchang skill) and maps it onto `PanchangDay`. Returns nil on any failure — the
/// caller shows a "not available" message rather than stale or wrong-city data.
func fetchTodayPanchang(forceRefresh: Bool = false) async -> PanchangDay? {
    if !forceRefresh, let cached = await PanchangCache.shared.day { return cached }
    guard let url = URL(string: PANCHANG_DAILY_URL) else { return nil }
    var request = URLRequest(url: url, timeoutInterval: 7)
    request.setValue(forceRefresh ? "no-cache" : "max-age=300", forHTTPHeaderField: "Cache-Control")
    do {
        let (data, _) = try await URLSession.shared.data(for: request)
        guard let root = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else { return nil }
        let festivalsRaw = root["festivals_and_vrats"] as? [Any] ?? []
        let festivals: [String] = festivalsRaw.compactMap {
            if let s = $0 as? String { return s.isEmpty ? nil : s }
            if let o = $0 as? [String: Any], let n = o["name"] as? String, !n.isEmpty { return n }
            return nil
        }
        let parsed = PanchangDay(
            date: (root["date"] as? String) ?? "",
            vara: (root["vara"] as? String) ?? "",
            tithi: angaList(root["tithi"] as? [[String: Any]]),
            nakshatra: angaList(root["nakshatra"] as? [[String: Any]]),
            yoga: angaList(root["yoga"] as? [[String: Any]]),
            karana: angaList(root["karana"] as? [[String: Any]]),
            sunrise: formatIso(root["sunrise"] as? String),
            sunset: formatIso(root["sunset"] as? String),
            moonrise: formatIso(root["moonrise"] as? String),
            moonset: formatIso(root["moonset"] as? String),
            rahuKaal: window(root["rahu_kaal"] as? [String: Any]),
            abhijitMuhurat: window(root["abhijit_muhurat"] as? [String: Any]),
            festivalsToday: festivals
        )
        await PanchangCache.shared.setDay(parsed)
        return parsed
    } catch {
        return nil
    }
}

/// Fetches varanasi-panchang-calendar.json — the upcoming vrat/tyohar list — sorted by date.
/// Falls back to an empty list on any failure.
func fetchUpcomingObservances(forceRefresh: Bool = false) async -> [Observance] {
    if !forceRefresh, let cached = await PanchangCache.shared.observances { return cached }
    guard let url = URL(string: PANCHANG_CALENDAR_URL) else { return [] }
    var request = URLRequest(url: url, timeoutInterval: 7)
    request.setValue(forceRefresh ? "no-cache" : "max-age=300", forHTTPHeaderField: "Cache-Control")
    do {
        let (data, _) = try await URLSession.shared.data(for: request)
        guard let root = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any],
              let array = root["observances"] as? [[String: Any]] else { return [] }
        let parsed: [Observance] = array.compactMap { obj in
            guard let id = obj["id"] as? String, !id.isEmpty,
                  let name = obj["name"] as? String, !name.isEmpty,
                  let date = obj["date"] as? String, !date.isEmpty else { return nil }
            return Observance(
                id: id, name: name, type: (obj["type"] as? String) ?? "vrat", date: date,
                tithi: (obj["tithi"] as? String) ?? "", paksha: (obj["paksha"] as? String) ?? "",
                description: (obj["description"] as? String) ?? ""
            )
        }.sorted { $0.date < $1.date }
        await PanchangCache.shared.setObservances(parsed)
        return parsed
    } catch {
        return []
    }
}
