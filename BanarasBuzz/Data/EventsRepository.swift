// Ported from the Android app's data/EventsRepository.kt.
import Foundation

private let EVENTS_API_URL = "https://raw.githubusercontent.com/prabhat-twr/vns-news-api/main/events.json"

private let MONTH_EN = ["JAN", "FEB", "MAR", "APR", "MAY", "JUN", "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"]
private let MONTH_HI = ["जन", "फ़र", "मार्च", "अप्रैल", "मई", "जून", "जुल", "अग", "सित", "अक्तू", "नव", "दिस"]

private struct RawLiveEvent {
    let id: String
    let name: String
    let category: String
    let start: Date
    let end: Date?
    let allDay: Bool
    let dateNote: String?
    let locationName: String
    let description: String
    let sourceUrl: String?
}

private actor EventsCache {
    static let shared = EventsCache()
    var events: [EventItem]?
    func set(_ v: [EventItem]) { events = v }
}

/// Fetches events.json (produced daily by a scheduled Claude run against the varanasi-events
/// skill, committed to the vns-news-api repo) and maps it onto `EventItem`. Falls back to an
/// empty list on any failure; the caller then falls back to MOCK_EVENTS.
func fetchLiveEvents(forceRefresh: Bool = false) async -> [EventItem] {
    if !forceRefresh, let cached = await EventsCache.shared.events { return cached }
    guard let url = URL(string: EVENTS_API_URL) else { return [] }
    var request = URLRequest(url: url, timeoutInterval: 7)
    request.setValue(forceRefresh ? "no-cache" : "max-age=300", forHTTPHeaderField: "Cache-Control")
    do {
        let (data, _) = try await URLSession.shared.data(for: request)
        let parsed = parseEventsJson(data)
        await EventsCache.shared.set(parsed)
        return parsed
    } catch {
        return []
    }
}

private let isoParser: ISO8601DateFormatter = {
    let f = ISO8601DateFormatter()
    f.formatOptions = [.withInternetDateTime, .withFractionalSeconds, .withTimeZone]
    return f
}()
private let isoParserNoFraction: ISO8601DateFormatter = {
    let f = ISO8601DateFormatter()
    f.formatOptions = [.withInternetDateTime, .withTimeZone]
    return f
}()

private func parseIsoDate(_ s: String) -> Date? {
    isoParser.date(from: s) ?? isoParserNoFraction.date(from: s)
}

private func parseEventsJson(_ data: Data) -> [EventItem] {
    guard let root = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any],
          let array = root["events"] as? [[String: Any]] else { return [] }
    let raw: [RawLiveEvent] = array.compactMap { obj in
        guard let id = obj["id"] as? String, !id.isEmpty,
              let name = obj["name"] as? String, !name.isEmpty,
              let startStr = obj["start"] as? String, let start = parseIsoDate(startStr) else { return nil }
        let end = (obj["end"] as? String).flatMap(parseIsoDate)
        let location = obj["location"] as? [String: Any]
        return RawLiveEvent(
            id: id, name: name, category: (obj["category"] as? String) ?? "tourism",
            start: start, end: end, allDay: (obj["all_day"] as? Bool) ?? false,
            dateNote: (obj["date_note"] as? String).flatMap { $0.isEmpty ? nil : $0 },
            locationName: (location?["name"] as? String) ?? "Varanasi",
            description: (obj["description"] as? String) ?? "",
            sourceUrl: (obj["source_url"] as? String).flatMap { $0.isEmpty ? nil : $0 }
        )
    }
    return raw.map { $0.toEventItem() }
}

private extension RawLiveEvent {
    func toEventItem() -> EventItem {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = istTimeZone
        let dateComps = cal.dateComponents([.year, .month, .day], from: start)
        let date = cal.date(from: dateComps) ?? start
        let day = dateComps.day ?? 1

        let categoryLabel = category.prefix(1).uppercased() + category.dropFirst()
        let hm = DateFormatter()
        hm.timeZone = istTimeZone
        hm.dateFormat = "HH:mm"
        let startTime = allDay ? "ALL DAY" : hm.string(from: start)

        let durationBi: Bi
        if allDay {
            durationBi = Bi(en: "All day", hi: "पूरा दिन")
        } else if let end {
            let minutes = max(0, Int(end.timeIntervalSince(start) / 60))
            if minutes < 60 {
                durationBi = Bi(en: "\(minutes) min", hi: "\(minutes) मिनट")
            } else if minutes % 60 == 0 {
                durationBi = Bi(en: "\(minutes / 60) hr", hi: "\(minutes / 60) घं")
            } else {
                durationBi = Bi(en: "\(minutes / 60)h \(minutes % 60)m", hi: "\(minutes / 60)घं \(minutes % 60)मि")
            }
        } else {
            durationBi = Bi(en: "—", hi: "—")
        }

        let monthIdx = (dateComps.month ?? 1) - 1
        let monthBi = Bi(en: MONTH_EN.indices.contains(monthIdx) ? MONTH_EN[monthIdx] : "",
                          hi: MONTH_HI.indices.contains(monthIdx) ? MONTH_HI[monthIdx] : "")

        var body2 = ""
        if let dateNote, !dateNote.isEmpty { body2 += dateNote }
        if let sourceUrl {
            if !body2.isEmpty { body2 += " " }
            body2 += "Source: \(sourceUrl)"
        }
        if body2.isEmpty { body2 = "Details from the daily Varanasi events feed." }

        let fullDate = isoDateString(date)

        return EventItem(
            id: "live-\(id)", day: day, tag: categoryLabel,
            category: Bi(en: categoryLabel, hi: categoryLabel), start: startTime, duration: durationBi,
            title: Bi(en: name, hi: name), venue: Bi(en: locationName, hi: locationName),
            price: Bi(en: "See source", hi: "स्रोत देखें"), month: monthBi,
            image: Bi(en: "photo: \(categoryLabel) event", hi: "फ़ोटो: \(categoryLabel) आयोजन"),
            body1: Bi(en: description, hi: description), body2: Bi(en: body2, hi: body2),
            fullDate: fullDate, sourceUrl: sourceUrl
        )
    }
}
