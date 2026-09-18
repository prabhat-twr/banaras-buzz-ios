import Foundation

/// A bilingual (English / Hindi) string pair, mirroring the Android app's `Bi` model.
struct Bi: Hashable {
    let en: String
    let hi: String

    func of(_ lang: Lang) -> String { lang == .hi ? hi : en }
}

enum Lang { case en, hi }

/// The four bottom-tab screens (Aarti & Darshan lives inside Events as a scrolled-down
/// section, matching the Android layout), plus Alerts which is reached from the masthead bell.
enum Screen: Equatable {
    case buzz, events, ghats, bazaar, alerts
}

struct EventItem: Identifiable, Hashable {
    let id: String
    let day: Int
    let tag: String
    let category: Bi
    let start: String
    let duration: Bi
    let title: Bi
    let venue: Bi
    let price: Bi
    let month: Bi
    let image: Bi
    let body1: Bi
    let body2: Bi
    /// ISO "yyyy-MM-dd" for live (fetched) events — lets the UI match an exact date instead
    /// of just a day-of-month. Nil for the static mock placeholders.
    var fullDate: String? = nil
    /// Where a live event's data came from, shown in the detail sheet as a source link.
    var sourceUrl: String? = nil
}

struct AartiItem: Identifiable, Hashable {
    let id: String
    let place: Bi
    let note: Bi
    let time: String
    let status: Bi
    var hot: Bool = false
}

struct TempleItem: Identifiable, Hashable {
    let id: String
    let name: Bi
    let hours: Bi
    let queue: Bi
    let wait: Bi
    /// 0 = light, 1 = moderate, 2 = heavy — drives the queue chip color.
    let level: Int
    let image: Bi
    let body1: Bi
    let body2: Bi
}

struct GhatItem: Identifiable, Hashable {
    let id: String
    let name: Bi
    let blurb: Bi
    let walk: Bi
    let crowd: Bi
    let image: Bi
    let body1: Bi
    let body2: Bi
}

struct ListingItem: Identifiable, Hashable {
    let id: String
    let tag: String
    let category: Bi
    let title: Bi
    let price: Bi
    let area: Bi
    let age: Bi
}

struct AlertItem: Identifiable, Hashable {
    let id: String
    let tag: Bi
    let kind: String
    let ref: String?
    let text: Bi
    let time: Bi
    var unread: Bool = false
}

struct SourcePage: Identifiable, Hashable {
    var id: String { url }
    let url: String
    let title: String
}

/// Content shown in the bottom detail sheet, resolved for the current language.
struct SheetContent {
    let image: String
    let kicker: String
    let meta: String
    let title: String
    let body1: String
    let body2: String
    let actionLabel: String
    var actionAccent: Bool = false
    /// When set, the sheet loads and shows this real photo instead of the placeholder slot.
    var imageUrl: String? = nil
    /// When both are set, the sheet shows a secondary "view source" link below the main
    /// action row — used by live (fetched) events to link back to where the listing came from.
    var sourceLabel: String? = nil
    var onOpenSource: (() -> Void)? = nil
    let onAction: () -> Void
}

/// One anga (tithi/nakshatra/yoga/karana) entry from the daily panchang feed. `endsAt` is
/// already formatted "HH:mm" IST for direct display; nil means it runs past the visible
/// window (last entry of the day) rather than missing data.
struct PanchangAnga: Hashable {
    let name: String
    var paksha: String? = nil
    var endsAt: String? = nil
}

/// A start/end clock-time window (Rahu Kaal, Abhijit Muhurat, …), already formatted "HH:mm" IST.
struct PanchangWindow: Hashable {
    let start: String
    let end: String
}

/// One day's Varanasi panchang, fetched from the daily-updated panchang feed.
struct PanchangDay {
    let date: String
    let vara: String
    let tithi: [PanchangAnga]
    let nakshatra: [PanchangAnga]
    let yoga: [PanchangAnga]
    let karana: [PanchangAnga]
    let sunrise: String?
    let sunset: String?
    let moonrise: String?
    let moonset: String?
    let rahuKaal: PanchangWindow?
    let abhijitMuhurat: PanchangWindow?
    let festivalsToday: [String]
}

/// One upcoming vrat (fasting day) or tyohar (festival) from the panchang calendar feed.
struct Observance: Identifiable, Hashable {
    let id: String
    let name: String
    /// "vrat" | "tyohar" | "both"
    let type: String
    /// ISO "yyyy-MM-dd".
    let date: String
    let tithi: String
    let paksha: String
    let description: String
}

enum ChatRole { case user, bot }

/// One turn in the Kashi Assistant chat (see Data/KashiAssistant.swift) — a lightweight
/// rule-based helper that answers Varanasi questions from the app's own live data, not a
/// hosted LLM.
struct ChatMessage: Identifiable, Hashable {
    let id: String
    let role: ChatRole
    let text: String

    static func == (lhs: ChatMessage, rhs: ChatMessage) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
