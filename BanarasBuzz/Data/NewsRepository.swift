// Ported from the Android app's data/NewsRepository.kt.
import Foundation

private let NEWS_API_URL = "https://raw.githubusercontent.com/prabhat-twr/vns-news-api/main/news.json"

let ALL_CITIES = "all"

let CITY_LABELS: [(String, Bi)] = [
    (ALL_CITIES, Bi(en: "All", hi: "सभी")),
    ("varanasi", Bi(en: "Varanasi", hi: "वाराणसी")),
    ("mirzapur", Bi(en: "Mirzapur", hi: "मिर्जापुर")),
    ("jaunpur", Bi(en: "Jaunpur", hi: "जौनपुर")),
]

struct NewsArticle: Identifiable, Hashable {
    let id: String
    let cityId: String
    let cityName: String
    let title: String
    let summary: String
    let content: String
    let location: String
    let date: String
    var publishedAt: String? = nil
    var imageUrl: String? = nil
    var sourceUrl: String? = nil
    var sourceName: String? = nil
    var isBreaking: Bool = false
}

private actor NewsCache {
    static let shared = NewsCache()
    var articles: [NewsArticle]?
}

func fetchNewsArticles(forceRefresh: Bool = false) async -> [NewsArticle] {
    if !forceRefresh, let cached = await NewsCache.shared.articles { return cached }
    guard let url = URL(string: NEWS_API_URL) else { return [] }
    var request = URLRequest(url: url, timeoutInterval: 7)
    request.setValue(forceRefresh ? "no-cache" : "max-age=300", forHTTPHeaderField: "Cache-Control")
    do {
        let (data, _) = try await URLSession.shared.data(for: request)
        let parsed = parseNewsJson(data)
        await NewsCache.shared.setArticles(parsed)
        return parsed
    } catch {
        return []
    }
}

private extension NewsCache {
    func setArticles(_ articles: [NewsArticle]) { self.articles = articles }
}

private func parseNewsJson(_ data: Data) -> [NewsArticle] {
    guard let array = (try? JSONSerialization.jsonObject(with: data)) as? [[String: Any]] else { return [] }
    return array.compactMap { item -> NewsArticle? in
        let summary = (item["summary"] as? String) ?? ""
        let cityId = (item["cityId"] as? String) ?? "varanasi"
        let cityName = (item["cityName"] as? String) ?? (item["location"] as? String) ?? "वाराणसी"
        let title = (item["title"] as? String) ?? ""
        guard !title.isEmpty, !summary.isEmpty else { return nil }
        return NewsArticle(
            id: (item["id"] as? String) ?? UUID().uuidString,
            cityId: cityId, cityName: cityName, title: title, summary: summary,
            content: (item["content"] as? String) ?? summary,
            location: (item["location"] as? String) ?? cityName,
            date: (item["date"] as? String) ?? "आज",
            publishedAt: (item["publishedAt"] as? String).flatMap { $0.isEmpty ? nil : $0 },
            imageUrl: (item["imageUrl"] as? String).flatMap { $0.isEmpty ? nil : $0 },
            sourceUrl: (item["sourceUrl"] as? String).flatMap { $0.isEmpty ? nil : $0 },
            sourceName: (item["sourceName"] as? String).flatMap { $0.isEmpty ? nil : $0 },
            isBreaking: (item["isBreaking"] as? Bool) ?? false
        )
    }
}

/// "2h ago" / "2 घंटे पहले" style relative time, matching the design's feed rhythm.
func relativeTime(for article: NewsArticle, lang: Lang) -> String {
    let iso = ISO8601DateFormatter()
    iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    let instant = article.publishedAt.flatMap { iso.date(from: $0) ?? ISO8601DateFormatter().date(from: $0) }
    guard let instant else {
        return article.date == "आज" ? (lang == .hi ? "आज" : "Today") : article.date
    }
    let minutes = max(0, Int(Date().timeIntervalSince(instant) / 60))
    if minutes < 1 { return lang == .hi ? "अभी" : "just now" }
    if minutes < 60 { return lang == .hi ? "\(minutes) मिनट पहले" : "\(minutes)m ago" }
    if minutes < 60 * 24 {
        let h = minutes / 60
        return lang == .hi ? "\(h) घंटे पहले" : "\(h)h ago"
    }
    let d = minutes / (60 * 24)
    return lang == .hi ? "\(d) दिन पहले" : "\(d)d ago"
}
