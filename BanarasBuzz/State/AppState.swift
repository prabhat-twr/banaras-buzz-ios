// Ported from the Android app's ui/state/AppState.kt.
import Foundation
import Combine

final class AppState: ObservableObject {
    @Published var lang: Lang = .en
    @Published var screen: Screen = .buzz

    @Published var feedCityFilter: String = ALL_CITIES
    @Published var eventFilterIndex: Int = 0
    @Published var bazaarFilterIndex: Int = 0
    @Published var selectedDay: Int = 17
    /// ISO "yyyy-MM-dd" companion to `selectedDay` when the live event feed is active.
    @Published var selectedDayIso: String? = nil

    @Published var going: [String: Bool] = [:]
    @Published var savedAds: [String: Bool] = [:]
    @Published var reminders: [String: Bool] = [:]
    @Published var readAlerts: [String: Bool] = [:]

    @Published var sheet: SheetContent? = nil
    @Published var toast: String? = nil
    @Published var sourcePage: SourcePage? = nil
    /// Set to a place-name query to open the device's maps app; reset to nil right after.
    @Published var mapQuery: String? = nil

    // Live data for the Buzz tab.
    @Published var articles: [NewsArticle] = []
    @Published var articlesLoading: Bool = true

    // Live data for the Events tab — falls back to MOCK_EVENTS when empty.
    @Published var liveEvents: [EventItem] = []
    @Published var liveEventsLoading: Bool = true

    // Live Varanasi panchang and upcoming vrat/tyohar calendar, shown inside the Events tab.
    @Published var panchang: PanchangDay? = nil
    @Published var panchangLoading: Bool = true
    @Published var upcomingObservances: [Observance] = []
    @Published var observancesLoading: Bool = true

    @Published var nowMillis: Date = Date()

    // Kashi Assistant chat sheet — a small rule-based helper (see Data/KashiAssistant.swift),
    // not a hosted LLM. Messages persist for the life of the app process so reopening the
    // sheet keeps the conversation, matching how the other sheets/tabs keep their state.
    @Published var chatOpen: Bool = false
    @Published var chatMessages: [ChatMessage] = []
    @Published var chatThinking: Bool = false

    func toggleLang() {
        lang = lang == .en ? .hi : .en
    }

    func go(_ target: Screen) {
        screen = target
        sheet = nil
    }

    func say(_ message: String) {
        toast = message
    }

    func isGoing(_ id: String) -> Bool { going[id] == true }
    func toggleGoing(_ id: String, addedMsg: String, removedMsg: String) {
        let now = !isGoing(id)
        going[id] = now
        say(now ? addedMsg : removedMsg)
        sheet = nil
    }

    func isSaved(_ id: String) -> Bool { savedAds[id] == true }
    func toggleSaved(_ id: String) {
        savedAds[id] = !isSaved(id)
    }

    func hasReminder(_ id: String) -> Bool { reminders[id] == true }
    func toggleReminder(_ id: String, setMsg: String) {
        let now = !hasReminder(id)
        reminders[id] = now
        if now { say(setMsg) }
    }

    func isRead(_ id: String) -> Bool { readAlerts[id] == true }
    func markRead(_ id: String) {
        readAlerts[id] = true
    }
    func markAllRead(_ ids: [String]) {
        for id in ids { readAlerts[id] = true }
    }
}
