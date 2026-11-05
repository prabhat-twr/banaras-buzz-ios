// App state and data loading for the redesigned app (mirrors Android's FeedViewModel + Repository).
import Foundation
import SwiftUI

struct BuzzNews: Identifiable, Hashable {
    let id: String
    let title: String
    let summary: String
    let cityId: String
    let cityName: String
    let imageUrl: String?
    let sourceUrl: String?
    let sourceName: String
    let isBreaking: Bool
    let firstSeen: Date?
}

struct BuzzEvent: Identifiable, Hashable {
    let id: String
    let name: String
    let category: String
    let start: Date?
    let allDay: Bool
    let venue: String?
    let description: String
    let sourceUrl: String?
    let imageUrl: String?
    let approximate: Bool
    var dayKey: String? { start.map(pkDayKey) }
}

struct YearPanchang {
    let days: [String: PDay]
    let observances: [PObservance]
    let start: String
    let end: String
}

enum Route2: Hashable { case home, news, panchang, explore, more, events, business, community, year }

enum YearProblem { case notPublished, offline }

/// "2 घंटे पहले" style relative time.
func timeAgoHi(_ date: Date?) -> String {
    guard let date else { return "" }
    let m = Int(Date().timeIntervalSince(date) / 60)
    if m < 1 { return "अभी" }
    if m < 60 { return "\(m) मिनट पहले" }
    if m < 60 * 24 { return "\(m / 60) घंटे पहले" }
    if m < 60 * 24 * 7 { return "\(m / (60 * 24)) दिन पहले" }
    return pkHindiShortDate(pkDayKey(date))
}

/// UI state lives on the main thread; the async loaders below hop to it explicitly.
final class BuzzStore: ObservableObject {
    @Published var news: [BuzzNews] = []
    @Published var events: [BuzzEvent] = []
    @Published var today: PDay?
    @Published var nextDays: [String: PDay] = [:]
    @Published var observances: [PObservance] = []
    @Published var offline = false
    @Published var loading = false
    @Published var loaded = false

    @Published var year: YearPanchang?
    @Published var yearLoading = false
    @Published var yearProblem: YearProblem?

    /// Date shown on the Panchang screen; nil means today.
    @Published var selectedDate: String?
    @Published var stack: [Route2] = [.home]
    @Published var toast: String?

    @Published var cityId: String = UserDefaults.standard.string(forKey: "bz.city") ?? "varanasi" {
        didSet { UserDefaults.standard.set(cityId, forKey: "bz.city") }
    }
    @Published var saved: Set<String> = Set(UserDefaults.standard.stringArray(forKey: "bz.saved") ?? []) {
        didSet { UserDefaults.standard.set(Array(saved), forKey: "bz.saved") }
    }

    private var loadedAt = Date.distantPast
    private var loadedFor = ""

    var route: Route2 { stack.last ?? .home }

    // MARK: Navigation

    func go(_ r: Route2) {
        if [.home, .news, .panchang, .explore, .more].contains(r) {
            stack = [r]
        } else if stack.last != r {
            stack.append(r)
        }
    }

    func back() {
        if stack.count > 1 { stack.removeLast() } else { stack = [.home] }
    }

    func say(_ message: String) {
        toast = message
        let current = message
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 2_200_000_000)
            if toast == current { toast = nil }
        }
    }

    func isSaved(_ id: String) -> Bool { saved.contains(id) }
    func toggleSaved(_ id: String) {
        if saved.contains(id) { saved.remove(id) } else { saved.insert(id) }
    }

    func cities() -> [(String, String)] {
        var seen = Set<String>()
        var out: [(String, String)] = []
        for n in news where !n.cityId.isEmpty && !seen.contains(n.cityId) {
            seen.insert(n.cityId)
            out.append((n.cityId, n.cityName))
        }
        return out
    }

    var cityName: String { cities().first { $0.0 == cityId }?.1 ?? "वाराणसी" }

    // MARK: Panchang lookups

    func panchang(for key: String) -> PDay? {
        if key == pkTodayKey() {
            if let t = today, t.date == key { return t }
            return year?.days[key] ?? nextDays[key] ?? today
        }
        return year?.days[key] ?? nextDays[key]
    }

    /// Whole year's vrat and tyohar when loaded, else the next 45 days.
    var allObservances: [PObservance] { year?.observances ?? observances }

    // MARK: Loading

    private func cacheURL(_ name: String) -> URL {
        let dir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        return dir.appendingPathComponent(name)
    }

    /// Network first; on failure the last saved copy (and `offline` is set).
    private func fetchCached(_ name: String) async -> (Data?, Bool) {
        switch await pkFetch(name) {
        case .ok(let data):
            try? data.write(to: cacheURL(name))
            return (data, false)
        case .notFound:
            try? FileManager.default.removeItem(at: cacheURL(name))
            return (nil, false)
        case .failed:
            return (try? Data(contentsOf: cacheURL(name)), true)
        }
    }

    @MainActor
    func refresh() async {
        if loading { return }
        loading = true
        loadedAt = Date()
        loadedFor = pkTodayKey()
        let names = ["news.json", "manual-news.json", "events.json", "manual-events.json", "hidden.json",
                     "varanasi-panchang-days.json", "varanasi-panchang-daily.json", "varanasi-panchang-calendar.json"]
        var files: [String: Data] = [:]
        var anyOffline = false
        await withTaskGroup(of: (String, Data?, Bool).self) { group in
            for n in names {
                group.addTask { [weak self] in
                    guard let self else { return (n, nil, false) }
                    let (d, off) = await self.fetchCached(n)
                    return (n, d, off)
                }
            }
            for await (n, d, off) in group {
                if let d { files[n] = d }
                anyOffline = anyOffline || off
            }
        }

        let hidden = pkJSON(files["hidden.json"]) as? [String: Any]
        let hiddenNews = Set((hidden?["news"] as? [String]) ?? [])
        let hiddenEvents = Set((hidden?["events"] as? [String]) ?? [])

        var seen = Set<String>()
        news = (parseNews(files["manual-news.json"]) + parseNews(files["news.json"]))
            .filter { !hiddenNews.contains($0.id) && seen.insert($0.id).inserted }
            .sorted { ($0.firstSeen ?? .distantPast) > ($1.firstSeen ?? .distantPast) }
        events = (parseEvents(files["events.json"]) + parseEvents(files["manual-events.json"]))
            .filter { !hiddenEvents.contains($0.id) }
            .sorted { ($0.start ?? .distantFuture) < ($1.start ?? .distantFuture) }

        let days = parsePDays(pkJSON(files["varanasi-panchang-days.json"]))
        nextDays = days
        today = days[pkTodayKey()] ?? parsePDay(pkJSON(files["varanasi-panchang-daily.json"]))
        observances = parsePObservances((pkJSON(files["varanasi-panchang-calendar.json"]) as? [String: Any])?["observances"])
        offline = anyOffline
        loaded = true
        loading = false
        PanchangAlerts.reschedule(store: self)
    }

    /// Reload when coming back to the app if the data is over 15 minutes old or the day changed.
    func refreshIfStale() {
        if loaded && (Date().timeIntervalSince(loadedAt) > 15 * 60 || loadedFor != pkTodayKey()) {
            Task { @MainActor in await self.refresh() }
        }
    }

    /// The year file (~60 KB): fetched the first time someone looks beyond the next week,
    /// kept for 12 hours, and used from the cache when offline.
    func ensureYear(force: Bool = false) {
        if yearLoading || (year != nil && !force) { return }
        yearLoading = true
        yearProblem = nil
        Task { @MainActor in
            let name = "varanasi-panchang-year.json"
            let url = cacheURL(name)
            let cached = (try? Data(contentsOf: url)).flatMap { self.parseYear($0) }
            let age = (try? url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate).map { Date().timeIntervalSince($0) } ?? .infinity
            if !force, let c = cached, age < 12 * 3600, c.start <= pkTodayKey() {
                self.year = c
            } else {
                switch await pkFetch(name, timeout: 30) {
                case .ok(let data):
                    if let y = parseYear(data) {
                        try? data.write(to: url)
                        year = y
                    } else {
                        year = cached
                        if cached == nil { yearProblem = .offline }
                    }
                case .notFound:
                    year = cached
                    if cached == nil { yearProblem = .notPublished }
                case .failed:
                    year = cached
                    if cached == nil { yearProblem = .offline }
                }
            }
            yearLoading = false
            if year != nil { PanchangAlerts.reschedule(store: self) }
        }
    }

    // MARK: Parsing

    private func parseYear(_ data: Data) -> YearPanchang? {
        guard let root = pkJSON(data) as? [String: Any] else { return nil }
        let days = parsePDays(root)
        guard !days.isEmpty else { return nil }
        let window = root["window"] as? [String: Any]
        let keys = days.keys.sorted()
        return YearPanchang(
            days: days,
            observances: parsePObservances(root["observances"]),
            start: (window?["start"] as? String) ?? keys.first ?? "",
            end: (window?["end"] as? String) ?? keys.last ?? ""
        )
    }

    private func str(_ o: [String: Any]?, _ k: String) -> String? {
        guard let v = o?[k] as? String else { return nil }
        let t = v.trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? nil : t
    }

    private func parseNews(_ data: Data?) -> [BuzzNews] {
        guard let arr = pkJSON(data) as? [[String: Any]] else { return [] }
        return arr.compactMap { o in
            guard let title = str(o, "title") else { return nil }
            return BuzzNews(
                id: str(o, "id") ?? title, title: title,
                summary: str(o, "summary") ?? str(o, "content") ?? "",
                cityId: str(o, "cityId") ?? "", cityName: str(o, "cityName") ?? "",
                imageUrl: str(o, "imageUrl"), sourceUrl: str(o, "sourceUrl"),
                sourceName: str(o, "sourceName") ?? "", isBreaking: (o["isBreaking"] as? Bool) ?? false,
                firstSeen: pkParseIso(o["firstSeenAt"])
            )
        }
    }

    private func parseEvents(_ data: Data?) -> [BuzzEvent] {
        guard let root = pkJSON(data) as? [String: Any], let arr = root["events"] as? [[String: Any]] else { return [] }
        return arr.compactMap { o in
            guard let name = str(o, "name") else { return nil }
            return BuzzEvent(
                id: str(o, "id") ?? name, name: name, category: str(o, "category") ?? "general",
                start: pkParseIso(o["start"]), allDay: (o["all_day"] as? Bool) ?? true,
                venue: str(o["location"] as? [String: Any], "name"), description: str(o, "description") ?? "",
                sourceUrl: str(o, "source_url"), imageUrl: str(o, "image_url"),
                approximate: (str(o, "date_confidence") ?? "confirmed") != "confirmed"
            )
        }
    }
}

func mapsSearchURL(_ query: String) -> URL? {
    let q = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
    return URL(string: "https://maps.apple.com/?q=\(q)")
}
