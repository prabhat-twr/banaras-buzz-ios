// App shell: the redesigned five-tab app (Home, News, Panchang, Explore, More), matching the
// Android app. The Kashi Assistant chat keeps its own AppState and opens as a sheet from
// Explore and More.
import SwiftUI

struct RootView: View {
    @StateObject private var state = AppState() // Kashi Assistant chat
    @StateObject private var store = BuzzStore()
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                screen
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                BuzzTabBar(store: store)
            }
            .background(BZ.cream.ignoresSafeArea())

            if !store.loaded && store.loading {
                ProgressView().tint(BZ.saffron).frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            if let message = store.toast {
                Text(message)
                    .font(.system(size: 14, weight: .medium)).foregroundColor(.white)
                    .padding(.horizontal, 16).padding(.vertical, 12)
                    .background(BZ.ink.opacity(0.92)).clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.bottom, 92)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: store.toast)
        .preferredColorScheme(.light)
        .sheet(isPresented: $state.chatOpen) { KashiChatSheet(state: state) }
        .task { await store.refresh() }
        // Data for the Kashi Assistant's answers.
        .task {
            state.panchang = await fetchTodayPanchang()
            state.panchangLoading = false
        }
        .task {
            state.upcomingObservances = await fetchUpcomingObservances()
            state.observancesLoading = false
        }
        .task {
            state.liveEvents = await fetchLiveEvents()
            state.liveEventsLoading = false
        }
        .onChange(of: scenePhase) { phase in
            if phase == .active { store.refreshIfStale() }
        }
        .onOpenURL { url in
            if url.host == "panchang" { openPanchang() }
        }
        .onAppear {
            NotificationRouter.shared.openPanchang = { openPanchang() }
            PanchangAlerts.reschedule(store: nil)
        }
    }

    private func openPanchang() {
        store.selectedDate = nil
        store.go(.panchang)
    }

    @ViewBuilder
    private var screen: some View {
        switch store.route {
        case .home: HomeScreen(store: store)
        case .news: NewsScreen(store: store)
        case .panchang: PanchangScreen(store: store)
        case .explore: ExploreScreen(store: store, openChat: { state.chatOpen = true })
        case .more: MoreScreen(store: store, openChat: { state.chatOpen = true })
        case .events: EventsScreen2(store: store)
        case .business: BusinessScreen(store: store)
        case .community: CommunityScreen(store: store)
        case .year: YearScreen(store: store)
        }
    }
}

private struct BuzzTabBar: View {
    @ObservedObject var store: BuzzStore

    private let tabs: [(Route2, String, String)] = [
        (.home, "Home", "house.fill"),
        (.news, "News", "newspaper.fill"),
        (.panchang, "Panchang", "calendar"),
        (.explore, "Explore", "safari.fill"),
        (.more, "More", "square.grid.2x2.fill"),
    ]

    private var activeTab: Route2 {
        switch store.route {
        case .events, .business, .community: return .explore
        case .year: return .panchang
        default: return store.route
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(tabs, id: \.0) { tab in
                let route = tab.0, label = tab.1, icon = tab.2
                let on = activeTab == route
                Button {
                    if route == .panchang { store.selectedDate = nil }
                    store.go(route)
                } label: {
                    VStack(spacing: 3) {
                        Image(systemName: icon)
                            .font(.system(size: 18, weight: .semibold))
                            .frame(width: 52, height: 28)
                            .background(on ? BZ.tile : .clear)
                            .clipShape(Capsule())
                        Text(label).font(.system(size: 11, weight: on ? .bold : .medium))
                    }
                    .foregroundColor(on ? BZ.saffron : BZ.muted)
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(on ? .isSelected : [])
            }
        }
        .padding(.top, 8)
        .padding(.bottom, 4)
        .background(Color.white.ignoresSafeArea(edges: .bottom))
        .overlay(Rectangle().fill(BZ.line).frame(height: 1), alignment: .top)
    }
}
