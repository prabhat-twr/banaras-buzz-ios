// Ported from the Android app's ui/BanarasBuzzApp.kt — the app shell: masthead, active
// screen, bottom tab bar, toast host, and the shared detail sheet.
import SwiftUI

private let TAB_SCREENS: [Screen] = [.buzz, .events, .ghats, .bazaar]

struct RootView: View {
    @StateObject private var state = AppState()

    var body: some View {
        let s = strings(for: state.lang)

        Group {
            if let sourcePage = state.sourcePage {
                SourceWebPage(sourcePage: sourcePage, lang: state.lang) { state.sourcePage = nil }
            } else {
                VStack(spacing: 0) {
                    Masthead(
                        dateline: s.dateline, title: s.masthead, lang: state.lang,
                        hasUnread: MOCK_ALERTS.contains { $0.unread && !state.isRead($0.id) },
                        onToggleLang: { state.toggleLang() },
                        onOpenAlerts: { state.go(.alerts) }
                    )
                    .padding(.top, 8)

                    ZStack(alignment: .bottom) {
                        Group {
                            switch state.screen {
                            case .buzz: BuzzScreen(state: state)
                            case .events: EventsScreen(state: state)
                            case .ghats: GhatsScreen(state: state)
                            case .bazaar: BazaarScreen(state: state)
                            case .alerts: AlertsScreen(state: state)
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                        ToastHost(message: state.toast)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 14)
                            .animation(.easeInOut, value: state.toast)
                    }

                    BottomTabBar(
                        tabs: s.tabs.enumerated().map { i, label in (label, state.screen == TAB_SCREENS[i]) },
                        onSelect: { i in state.go(TAB_SCREENS[i]) }
                    )
                }
                .background(BBColors.paper.ignoresSafeArea())
            }
        }
        .sheet(item: $state.sheet) { sheet in
            DetailSheetView(sheet: sheet, closeLabel: s.close) { state.sheet = nil }
        }
        .task {
            state.articlesLoading = true
            state.articles = await fetchNewsArticles()
            state.articlesLoading = false
        }
        .task {
            state.liveEventsLoading = true
            state.liveEvents = await fetchLiveEvents()
            state.liveEventsLoading = false
        }
        .task {
            state.panchangLoading = true
            state.panchang = await fetchTodayPanchang()
            state.panchangLoading = false
        }
        .task {
            state.observancesLoading = true
            state.upcomingObservances = await fetchUpcomingObservances()
            state.observancesLoading = false
        }
        .onChange(of: state.toast) { newValue in
            guard newValue != nil else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.9) {
                state.toast = nil
            }
        }
        .onChange(of: state.mapQuery) { newValue in
            guard let q = newValue else { return }
            openMap(query: q)
            state.mapQuery = nil
        }
    }
}

extension SheetContent: Identifiable {
    var id: String { title }
}
