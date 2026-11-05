import SwiftUI

private let categoryHi = ["religious": "धार्मिक", "cultural": "सांस्कृतिक", "tourism": "पर्यटन", "general": "सामान्य"]

struct EventsScreen2: View {
    @ObservedObject var store: BuzzStore
    @Environment(\.openURL) private var openURL
    @State private var tab = 0

    var body: some View {
        let today = pkTodayKey()
        let end = pkAddDays(today, [0, 6, 30][tab])
        let list = store.events.filter { e in
            guard let d = e.dayKey else { return false }
            return d >= today && d <= end
        }
        let later = list.isEmpty ? Array(store.events.filter { ($0.dayKey ?? "") > end }.prefix(5)) : []
        let sunset = store.today.flatMap { $0.date == today ? $0.sunset : nil }

        VStack(spacing: 0) {
            ScreenHeader(title: "Events in Banaras", onBack: { store.back() })
            UnderlineTabs(labels: ["Today", "This Week", "This Month"], selected: $tab)
            ScrollView {
                LazyVStack(spacing: 16) {
                    // The evening Ganga Aarti happens every day, so it always leads the list.
                    EventCard(title: "Ganga Aarti at Dashashwamedh Ghat",
                              when: "रोज़ • सूर्यास्त के बाद" + (sunset.map { " (सूर्यास्त \(pkClock($0)))" } ?? ""),
                              venue: "Dashashwamedh Ghat", imageUrl: nil, mood: .night, description: "",
                              actionLabel: "Directions") {
                        if let u = mapsSearchURL("Dashashwamedh Ghat Varanasi") { openURL(u) }
                    }
                    ForEach(list) { e in card(e, today: today) }
                    if list.isEmpty {
                        Text(later.isEmpty ? "इस अवधि में कोई और कार्यक्रम दर्ज नहीं है।" : "इस अवधि में कोई और कार्यक्रम नहीं — आगे के कार्यक्रम:")
                            .font(.system(size: 14)).foregroundColor(BZ.muted).frame(maxWidth: .infinity, alignment: .leading)
                        ForEach(later) { e in card(e, today: today) }
                    }
                }
                .padding(16)
            }
        }
    }

    private func card(_ e: BuzzEvent, today: String) -> some View {
        let d = e.dayKey ?? ""
        let dayText = d == today ? "आज" : d == pkAddDays(today, 1) ? "कल" : pkHindiShortDate(d)
        let when = [dayText, (!e.allDay && e.start != nil) ? pkClock(e.start) : nil, categoryHi[e.category], e.approximate ? "तिथि अनुमानित" : nil]
            .compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " • ")
        return EventCard(title: e.name, when: when, venue: e.venue, imageUrl: e.imageUrl,
                         mood: e.category == "religious" ? .dusk : .dawn, description: e.description,
                         actionLabel: e.sourceUrl == nil ? nil : "View Details") {
            if let s = e.sourceUrl, let u = URL(string: s) { openURL(u) }
        }
    }
}

private struct EventCard: View {
    let title: String
    let when: String
    let venue: String?
    let imageUrl: String?
    let mood: SceneMood
    let description: String
    let actionLabel: String?
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            PhotoOrScene(url: imageUrl, mood: mood).frame(maxWidth: .infinity).frame(height: 150).clipped()
            VStack(alignment: .leading, spacing: 5) {
                Text(title).font(.system(size: 17, weight: .bold)).foregroundColor(BZ.ink).lineLimit(2)
                if !when.isEmpty { Text("📅 \(when)").font(.system(size: 13)).foregroundColor(BZ.inkSoft) }
                if let venue, !venue.isEmpty { Text("📍 \(venue)").font(.system(size: 13)).foregroundColor(BZ.inkSoft) }
                if !description.isEmpty { Text(description).font(.system(size: 13)).foregroundColor(BZ.muted).lineLimit(2) }
                if let actionLabel {
                    HStack { Spacer(); OutlineAction(label: actionLabel, action: action) }
                }
            }
            .padding(14)
        }
        .warmCard()
    }
}

struct LocalPlace: Identifiable {
    let id: String
    let name: String
    let tagline: String
    let area: String
    let category: String
    let emoji: String
    let colors: [Color]
    let mapsQuery: String
    var tag: String? = nil
}

private let warm = [Color(hex: 0xFFC56E), Color(hex: 0xE5732E)]
private let silk = [Color(hex: 0xB83B5E), Color(hex: 0xF08A5D)]
private let river = [Color(hex: 0x7FB3D5), Color(hex: 0x2E5E8C)]

let localPlaces: [LocalPlace] = [
    LocalPlace(id: "kachori-gali", name: "Kachori Gali", tagline: "Kachori-sabzi & jalebi breakfast lane", area: "Chowk", category: "Food", emoji: "🥟", colors: warm, mapsQuery: "Kachori Gali Varanasi", tag: "सुबह का नाश्ता"),
    LocalPlace(id: "godowlia-chaat", name: "Godowlia Chaat", tagline: "Tamatar chaat, palak patta chaat", area: "Godowlia", category: "Food", emoji: "🍲", colors: warm, mapsQuery: "Chaat Godowlia Varanasi"),
    LocalPlace(id: "malaiyo", name: "Malaiyo", tagline: "Winter-only saffron milk foam", area: "Chowk & Pakka Mahal", category: "Food", emoji: "🥛", colors: [Color(hex: 0xFFE9A8), Color(hex: 0xF2B33D)], mapsQuery: "Malaiyo Varanasi", tag: "सर्दियों में"),
    LocalPlace(id: "banarasi-silk", name: "Banarasi Silk Weavers", tagline: "Handloom sarees & brocade", area: "Peeli Kothi", category: "Shopping", emoji: "🧣", colors: silk, mapsQuery: "Banarasi saree weavers Peeli Kothi Varanasi"),
    LocalPlace(id: "thatheri-bazaar", name: "Thatheri Bazaar", tagline: "Brass & copper utensils", area: "Chowk", category: "Shopping", emoji: "🏺", colors: [Color(hex: 0xE8B04B), Color(hex: 0x9C6A1E)], mapsQuery: "Thatheri Bazaar Varanasi"),
    LocalPlace(id: "vishwanath-gali", name: "Vishwanath Gali", tagline: "Puja items, bangles, wooden toys", area: "Near Kashi Vishwanath", category: "Shopping", emoji: "🪔", colors: silk, mapsQuery: "Vishwanath Gali Varanasi"),
    LocalPlace(id: "godowlia-market", name: "Godowlia Market", tagline: "Clothes, footwear, everyday shopping", area: "Godowlia", category: "Shopping", emoji: "🛍️", colors: [Color(hex: 0xF7A072), Color(hex: 0xD1495B)], mapsQuery: "Godowlia Market Varanasi"),
    LocalPlace(id: "boat-ride", name: "Boat Rides", tagline: "Sunrise & aarti boat rides", area: "Dashashwamedh Ghat", category: "Services", emoji: "⛵", colors: river, mapsQuery: "Boat ride Dashashwamedh Ghat Varanasi"),
    LocalPlace(id: "prepaid-auto", name: "Prepaid Auto Booth", tagline: "Fixed-fare autos from the station", area: "Varanasi Junction", category: "Services", emoji: "🛺", colors: [Color(hex: 0x9BD17B), Color(hex: 0x3F8F4E)], mapsQuery: "Prepaid auto booth Varanasi Junction"),
    LocalPlace(id: "tourist-info", name: "Tourist Information", tagline: "Maps, guides and help desks", area: "Varanasi Cantt", category: "Services", emoji: "ℹ️", colors: river, mapsQuery: "Tourist information centre Varanasi"),
]

struct BusinessScreen: View {
    @ObservedObject var store: BuzzStore
    @Environment(\.openURL) private var openURL
    @State private var cat = 0
    private let cats = ["All", "Food", "Shopping", "Services"]

    var body: some View {
        VStack(spacing: 0) {
            ScreenHeader(title: "Local Business", onBack: { store.back() })
            PillChips(labels: cats, selected: $cat)
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(localPlaces.filter { cat == 0 || $0.category == cats[cat] }) { p in
                        HStack(spacing: 12) {
                            EmojiArt(emoji: p.emoji, colors: p.colors).frame(width: 100, height: 86)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                            VStack(alignment: .leading, spacing: 3) {
                                Text(p.name).font(.system(size: 16, weight: .bold)).foregroundColor(BZ.ink)
                                Text(p.tagline).font(.system(size: 13)).foregroundColor(BZ.inkSoft).lineLimit(2)
                                HStack {
                                    Text("📍 \(p.area)").font(.system(size: 12)).foregroundColor(BZ.muted)
                                    if let tag = p.tag {
                                        Text(tag).font(.system(size: 11, weight: .bold)).foregroundColor(.white)
                                            .padding(.horizontal, 6).padding(.vertical, 2).background(BZ.saffron)
                                            .clipShape(RoundedRectangle(cornerRadius: 6))
                                    }
                                }
                            }
                            Spacer(minLength: 0)
                            Button {
                                store.toggleSaved(p.id)
                                store.say(store.isSaved(p.id) ? "सहेजा गया" : "हटाया गया")
                            } label: {
                                Image(systemName: store.isSaved(p.id) ? "heart.fill" : "heart")
                                    .font(.system(size: 20)).foregroundColor(store.isSaved(p.id) ? BZ.saffron : BZ.muted)
                                    .frame(width: 40, height: 40)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("सहेजें")
                        }
                        .padding(10)
                        .warmCard()
                        .contentShape(Rectangle())
                        .onTapGesture { if let u = mapsSearchURL(p.mapsQuery) { openURL(u) } }
                    }
                    Button { store.say("बिज़नेस लिस्टिंग जल्द आ रही है") } label: {
                        VStack(spacing: 2) {
                            Text("🏪  अपना बिज़नेस जोड़ें").font(.system(size: 16, weight: .bold)).foregroundColor(BZ.ink)
                            Text("Offers & deals from local shops — coming soon").font(.system(size: 12.5)).foregroundColor(BZ.muted)
                        }
                        .frame(maxWidth: .infinity).padding(18)
                        .background(BZ.tile).clipShape(RoundedRectangle(cornerRadius: 18))
                    }
                    .buttonStyle(.plain)
                }
                .padding(16)
            }
        }
    }
}

struct ExploreScreen: View {
    @ObservedObject var store: BuzzStore
    let openChat: () -> Void
    @Environment(\.openURL) private var openURL
    @State private var query = ""

    private struct Tile: Identifiable {
        let id: String
        let mood: SceneMood?
        let emoji: String
        let colors: [Color]
        let action: (ExploreScreen) -> Void
    }

    private var tiles: [Tile] {
        [
            Tile(id: "Temples", mood: .dawn, emoji: "🛕", colors: []) { $0.openMaps("Temples in Varanasi") },
            Tile(id: "Ghats", mood: .dusk, emoji: "🌅", colors: []) { $0.openMaps("Ghats in Varanasi") },
            Tile(id: "Food", mood: nil, emoji: "🥟", colors: warm) { $0.store.go(.business) },
            Tile(id: "Culture", mood: nil, emoji: "🪔", colors: [Color(hex: 0x8E2D4F), Color(hex: 0xF2A541)]) { $0.store.go(.events) },
            Tile(id: "Shopping", mood: nil, emoji: "🧣", colors: silk) { $0.store.go(.business) },
            Tile(id: "Tourism", mood: .night, emoji: "⛵", colors: []) { $0.openMaps("Tourist attractions in Varanasi") },
        ]
    }

    fileprivate func openMaps(_ q: String) { if let u = mapsSearchURL(q) { openURL(u) } }

    var body: some View {
        VStack(spacing: 0) {
            ScreenHeader(title: "Explore Banaras")
            HStack {
                Image(systemName: "magnifyingglass").foregroundColor(BZ.muted)
                TextField("Search news, events, places…", text: $query)
            }
            .padding(12).background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(BZ.line))
            .padding(.horizontal, 16).padding(.vertical, 4)

            ScrollView {
                if query.trimmingCharacters(in: .whitespaces).isEmpty {
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                        ForEach(tiles) { t in
                            Button { t.action(self) } label: {
                                ZStack(alignment: .bottomLeading) {
                                    if let mood = t.mood { BanarasScene(mood: mood) } else { EmojiArt(emoji: t.emoji, colors: t.colors, size: 46) }
                                    LinearGradient(colors: [.clear, .black.opacity(0.5)], startPoint: .center, endPoint: .bottom)
                                    Text(t.id).font(.system(size: 16, weight: .bold)).foregroundColor(.white)
                                        .shadow(color: .black.opacity(0.6), radius: 3).padding(12)
                                }
                                .frame(height: 118)
                                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(16)

                    SectionTitle(text: "Quick Links").frame(maxWidth: .infinity, alignment: .leading)
                    HStack(alignment: .top) {
                        QuickLink(emoji: "🙏", label: "Live Darshan") { if let u = URL(string: "https://shrikashivishwanath.org/") { openURL(u) } }
                        QuickLink(emoji: "💬", label: "Kashi Assistant", action: openChat)
                        QuickLink(emoji: "📍", label: "My Banaras") { store.go(.community) }
                        QuickLink(emoji: "🛺", label: "Bus/Auto") { openMaps("Bus stand Varanasi") }
                        QuickLink(emoji: "🗺️", label: "Maps") { openMaps("Varanasi") }
                    }
                    .padding(.horizontal, 10)
                } else {
                    results(query.trimmingCharacters(in: .whitespaces).lowercased())
                }
            }
        }
    }

    @ViewBuilder
    private func results(_ q: String) -> some View {
        let places = localPlaces.filter { ($0.name + " " + $0.tagline + " " + $0.area).lowercased().contains(q) }
        let events = store.events.filter { ($0.name + " " + $0.description + " " + ($0.venue ?? "")).lowercased().contains(q) }.prefix(10)
        let news = store.news.filter { ($0.title + " " + $0.summary).lowercased().contains(q) }.prefix(20)
        if places.isEmpty && events.isEmpty && news.isEmpty {
            EmptyNote(text: "कुछ नहीं मिला।")
        } else {
            LazyVStack(spacing: 8) {
                ForEach(places) { p in ResultRow(emoji: "🏪", title: p.name, sub: p.area) { openMaps(p.mapsQuery) } }
                ForEach(Array(events)) { e in ResultRow(emoji: "📅", title: e.name, sub: e.venue ?? "") { if let s = e.sourceUrl, let u = URL(string: s) { openURL(u) } } }
                ForEach(Array(news)) { n in ResultRow(emoji: "📰", title: n.title, sub: timeAgoHi(n.firstSeen)) { if let s = n.sourceUrl, let u = URL(string: s) { openURL(u) } } }
            }
            .padding(16)
        }
    }
}

private struct QuickLink: View {
    let emoji: String
    let label: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(emoji).font(.system(size: 24)).frame(width: 52, height: 52).background(BZ.tile).clipShape(Circle())
                Text(label).font(.system(size: 11.5)).foregroundColor(BZ.inkSoft).multilineTextAlignment(.center).lineLimit(2)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}

private struct ResultRow: View {
    let emoji: String
    let title: String
    let sub: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Text(emoji).font(.system(size: 20))
                VStack(alignment: .leading, spacing: 1) {
                    Text(title).font(.system(size: 15, weight: .semibold)).foregroundColor(BZ.ink).lineLimit(2).multilineTextAlignment(.leading)
                    if !sub.isEmpty { Text(sub).font(.system(size: 12)).foregroundColor(BZ.muted).lineLimit(1) }
                }
                Spacer(minLength: 0)
            }
            .padding(12).background(Color.white).clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }
}
