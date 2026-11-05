import SwiftUI

struct HomeScreen: View {
    @ObservedObject var store: BuzzStore
    @Environment(\.openURL) private var openURL

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 8) {
                    Text("🛕").font(.system(size: 34))
                    VStack(alignment: .leading, spacing: 0) {
                        Text("BANARAS BUZZ").font(.system(size: 25, weight: .heavy)).foregroundColor(BZ.saffron)
                        Text("अपना बनारस, हर दिन").font(.system(size: 14, weight: .medium)).foregroundColor(BZ.saffronDeep)
                    }
                    Spacer()
                    Button { store.go(.news) } label: {
                        Image(systemName: "bell.fill").font(.system(size: 20)).foregroundColor(BZ.saffron)
                    }
                    .accessibilityLabel("ताज़ा खबरें")
                }
                .padding(.horizontal, 18)
                .padding(.top, 8)

                let greeting = greetingNow()
                ZStack(alignment: .bottomLeading) {
                    BanarasScene(mood: greeting.1)
                    LinearGradient(colors: [.clear, .black.opacity(0.6)], startPoint: .center, endPoint: .bottom)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(greeting.0) ☀️").font(.system(size: 25, weight: .heavy))
                        Text("Your daily Banaras briefing").font(.system(size: 15))
                    }
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.5), radius: 4)
                    .padding(18)
                }
                .frame(height: 210)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .padding(.horizontal, 16)

                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                    QuickTile(emoji: "📰", title: "आज की\n5 बड़ी खबरें", subtitle: "Local News") { store.go(.news) }
                    QuickTile(emoji: "🌞", title: "आज का पंचांग", subtitle: "Tithi, Nakshatra") { store.selectedDate = nil; store.go(.panchang) }
                    QuickTile(emoji: "📅", title: "आज बनारस में", subtitle: "Events & More") { store.go(.events) }
                    QuickTile(emoji: "🏪", title: "लोकल बिजनेस", subtitle: "Shops & Markets") { store.go(.business) }
                }
                .padding(.horizontal, 16)

                Button { store.go(.community) } label: {
                    HStack(spacing: 12) {
                        Text("📍").font(.system(size: 22))
                        VStack(alignment: .leading, spacing: 1) {
                            Text("My Banaras").font(.system(size: 16, weight: .bold)).foregroundColor(BZ.ink)
                            Text("Stories • Photos • City pulse").font(.system(size: 13)).foregroundColor(BZ.muted)
                        }
                        Spacer()
                        Image(systemName: "chevron.right").foregroundColor(BZ.saffron)
                    }
                    .padding(.horizontal, 16).padding(.vertical, 14)
                    .background(BZ.tile)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 16)

                let top = Array(store.news.prefix(5))
                if !top.isEmpty {
                    HStack {
                        SectionTitle(text: "आज की 5 बड़ी खबरें")
                        Spacer()
                        Button("सभी देखें") { store.go(.news) }
                            .font(.system(size: 14, weight: .semibold)).foregroundColor(BZ.saffron)
                            .padding(.trailing, 16)
                    }
                    VStack(spacing: 10) {
                        ForEach(Array(top.enumerated()), id: \.element.id) { i, n in
                            Button { if let s = n.sourceUrl, let u = URL(string: s) { openURL(u) } } label: {
                                HStack(spacing: 12) {
                                    Text("\(i + 1)").font(.system(size: 15, weight: .bold)).foregroundColor(.white)
                                        .frame(width: 30, height: 30).background(BZ.saffron).clipShape(Circle())
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(n.title).font(.system(size: 15, weight: .semibold)).foregroundColor(BZ.ink)
                                            .lineLimit(2).multilineTextAlignment(.leading)
                                        Text([n.cityName, timeAgoHi(n.firstSeen)].filter { !$0.isEmpty }.joined(separator: " • "))
                                            .font(.system(size: 12)).foregroundColor(BZ.muted)
                                    }
                                    Spacer(minLength: 0)
                                }
                                .padding(12)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                }
                if store.offline {
                    Text("ऑफ़लाइन — पिछली सहेजी हुई जानकारी दिख रही है")
                        .font(.system(size: 12)).foregroundColor(BZ.muted)
                        .frame(maxWidth: .infinity).padding(12)
                }
            }
            .padding(.bottom, 20)
        }
    }
}

private struct QuickTile: View {
    let emoji: String
    let title: String
    let subtitle: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(emoji).font(.system(size: 30))
                Text(title).font(.system(size: 16, weight: .bold)).foregroundColor(BZ.ink).multilineTextAlignment(.center)
                Text(subtitle).font(.system(size: 12.5)).foregroundColor(BZ.saffronDeep)
            }
            .frame(maxWidth: .infinity, minHeight: 128)
            .background(BZ.tile)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

struct NewsScreen: View {
    @ObservedObject var store: BuzzStore
    @Environment(\.openURL) private var openURL
    @State private var tab = 0
    @State private var searching = false
    @State private var query = ""

    var body: some View {
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        let list = store.news.filter { n in
            let inTab = tab == 1 ? n.cityId == store.cityId : tab == 2 ? n.isBreaking : true
            return inTab && (q.isEmpty || (n.title + " " + n.summary).lowercased().contains(q))
        }.prefix(150)
        let lead = list.first { $0.imageUrl != nil } ?? list.first

        VStack(spacing: 0) {
            ScreenHeader(title: "Top News", onBack: { store.back() }) {
                Button { searching.toggle(); if !searching { query = "" } } label: {
                    Image(systemName: searching ? "xmark" : "magnifyingglass").foregroundColor(BZ.ink).frame(width: 40, height: 40)
                }
                Menu {
                    ForEach(store.cities(), id: \.0) { c in
                        Button(c.1) { store.cityId = c.0; tab = 1 }
                    }
                } label: {
                    HStack(spacing: 2) {
                        Text(store.cityName).font(.system(size: 14, weight: .semibold))
                        Image(systemName: "chevron.down").font(.system(size: 11, weight: .bold))
                    }
                    .foregroundColor(BZ.ink)
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(BZ.tile).clipShape(Capsule())
                }
            }
            if searching {
                TextField("खबरें खोजें…", text: $query)
                    .padding(12).background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(BZ.line))
                    .padding(.horizontal, 16).padding(.vertical, 4)
            }
            UnderlineTabs(labels: ["Top Stories", "Local", "Breaking"], selected: $tab)
            if let lead {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        LeadStory(n: lead) { open(lead) }
                        ForEach(list.filter { $0.id != lead.id }) { n in
                            StoryRow(n: n) { open(n) }
                        }
                    }
                    .padding(16)
                }
            } else {
                EmptyNote(text: "अभी यहाँ कोई खबर नहीं है।")
                Spacer()
            }
        }
    }

    private func open(_ n: BuzzNews) {
        if let s = n.sourceUrl, let u = URL(string: s) { openURL(u) }
    }
}

private struct LeadStory: View {
    let n: BuzzNews
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            ZStack(alignment: .bottomLeading) {
                PhotoOrScene(url: n.imageUrl, mood: .night)
                    .frame(maxWidth: .infinity).frame(height: 230).clipped()
                LinearGradient(colors: [.clear, .black.opacity(0.85)], startPoint: .center, endPoint: .bottom)
                VStack(alignment: .leading, spacing: 6) {
                    if n.isBreaking {
                        Text("ब्रेकिंग").font(.system(size: 11, weight: .bold)).foregroundColor(.white)
                            .padding(.horizontal, 8).padding(.vertical, 2).background(BZ.saffron)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    Text(n.title).font(.system(size: 20, weight: .bold)).foregroundColor(.white)
                        .lineLimit(3).multilineTextAlignment(.leading)
                    Text(["🕑 " + timeAgoHi(n.firstSeen), n.cityName, n.sourceName].filter { !$0.isEmpty && $0 != "🕑 " }.joined(separator: " • "))
                        .font(.system(size: 12)).foregroundColor(Color(hex: 0xF3E6D6))
                }
                .padding(16)
            }
            .frame(height: 230)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private struct StoryRow: View {
    let n: BuzzNews
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                PhotoOrScene(url: n.imageUrl, mood: .dusk)
                    .frame(width: 104, height: 78).clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                VStack(alignment: .leading, spacing: 4) {
                    Text(n.title).font(.system(size: 15, weight: .semibold)).foregroundColor(BZ.ink)
                        .lineLimit(3).multilineTextAlignment(.leading)
                    Text([timeAgoHi(n.firstSeen), n.sourceName].filter { !$0.isEmpty }.joined(separator: " • "))
                        .font(.system(size: 12)).foregroundColor(BZ.muted).lineLimit(1)
                }
                Spacer(minLength: 0)
            }
            .padding(10)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}
