import SwiftUI

struct CommunityScreen: View {
    @ObservedObject var store: BuzzStore
    @Environment(\.openURL) private var openURL
    @State private var tab = 0
    @AppStorage("bz.poll") private var vote = ""
    private let poll = ["अस्सी घाट", "दशाश्वमेध घाट", "सारनाथ", "बीएचयू", "रामनगर किला"]

    var body: some View {
        let withImages = store.news.filter { $0.imageUrl != nil }
        ZStack(alignment: .bottomTrailing) {
            VStack(spacing: 0) {
                ScreenHeader(title: "My Banaras", onBack: { store.back() })
                UnderlineTabs(labels: ["Stories", "Photos", "Polls"], selected: $tab)
                ScrollView {
                    switch tab {
                    case 0: stories(Array(withImages.prefix(40)))
                    case 1: photos(Array(withImages.prefix(60)))
                    default: pollView
                    }
                }
            }
            Button { store.say("पोस्ट करने की सुविधा जल्द आ रही है") } label: {
                Label("Post", systemImage: "plus").font(.system(size: 16, weight: .bold)).foregroundColor(.white)
                    .padding(.horizontal, 20).padding(.vertical, 14)
                    .background(BZ.saffron).clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .black.opacity(0.2), radius: 6, y: 3)
            }
            .padding(16)
        }
    }

    @ViewBuilder
    private func stories(_ list: [BuzzNews]) -> some View {
        if list.isEmpty { EmptyNote(text: "अभी कोई कहानी नहीं है।") }
        LazyVStack(spacing: 16) {
            ForEach(list) { n in
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 10) {
                        Text(String((n.sourceName.isEmpty ? "B" : n.sourceName).prefix(1)))
                            .font(.system(size: 16, weight: .bold)).foregroundColor(BZ.saffron)
                            .frame(width: 38, height: 38).background(BZ.tile).clipShape(Circle())
                            .overlay(Circle().stroke(BZ.saffron, lineWidth: 1))
                        VStack(alignment: .leading, spacing: 0) {
                            Text(n.sourceName.isEmpty ? "Banaras Buzz" : n.sourceName).font(.system(size: 14, weight: .bold)).foregroundColor(BZ.ink)
                            Text([timeAgoHi(n.firstSeen), n.cityName].filter { !$0.isEmpty }.joined(separator: " • "))
                                .font(.system(size: 12)).foregroundColor(BZ.muted)
                        }
                    }
                    .padding([.horizontal, .top], 12)
                    Text(n.title).font(.system(size: 15)).foregroundColor(BZ.ink).lineLimit(3).padding(.horizontal, 12)
                    PhotoOrScene(url: n.imageUrl, mood: .dusk).frame(maxWidth: .infinity).frame(height: 190).clipped()
                        .onTapGesture { open(n) }
                    HStack {
                        let liked = store.isSaved("like-" + n.id)
                        Button { store.toggleSaved("like-" + n.id) } label: {
                            Image(systemName: liked ? "heart.fill" : "heart").foregroundColor(liked ? BZ.heart : BZ.inkSoft)
                                .font(.system(size: 20)).frame(width: 40, height: 40)
                        }
                        .accessibilityLabel("पसंद")
                        if n.sourceUrl != nil {
                            Button("पूरी खबर →") { open(n) }.font(.system(size: 14, weight: .semibold)).foregroundColor(BZ.saffron)
                        }
                        Spacer()
                        if let s = n.sourceUrl, let u = URL(string: s) {
                            ShareLink(item: u, subject: Text(n.title), message: Text(n.title + "\n— via Banaras Buzz")) {
                                Image(systemName: "square.and.arrow.up").foregroundColor(BZ.inkSoft).frame(width: 40, height: 40)
                            }
                        }
                    }
                    .padding(.horizontal, 6).padding(.bottom, 4)
                }
                .warmCard()
            }
        }
        .padding(16).padding(.bottom, 70)
    }

    @ViewBuilder
    private func photos(_ list: [BuzzNews]) -> some View {
        if list.isEmpty { EmptyNote(text: "अभी कोई फ़ोटो नहीं है।") }
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 3), spacing: 6) {
            ForEach(list) { n in
                Color.clear.aspectRatio(1, contentMode: .fit)
                    .overlay(PhotoOrScene(url: n.imageUrl, mood: .dusk))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .onTapGesture { open(n) }
            }
        }
        .padding(12).padding(.bottom, 70)
    }

    private var pollView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("बनारस में आपकी पसंदीदा जगह?").font(.system(size: 18, weight: .bold)).foregroundColor(BZ.ink)
            ForEach(poll, id: \.self) { opt in
                Button { vote = opt } label: {
                    Text((opt == vote ? "✓  " : "") + opt)
                        .font(.system(size: 15, weight: opt == vote ? .bold : .medium))
                        .foregroundColor(opt == vote ? .white : BZ.ink)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 14).padding(.vertical, 12)
                        .background(opt == vote ? BZ.saffron : BZ.tile)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
            if !vote.isEmpty { Text("धन्यवाद! सामुदायिक नतीजे जल्द दिखेंगे।").font(.system(size: 13)).foregroundColor(BZ.muted) }
        }
        .padding(16)
        .warmCard()
        .padding(16)
    }

    private func open(_ n: BuzzNews) { if let s = n.sourceUrl, let u = URL(string: s) { openURL(u) } }
}

struct MoreScreen: View {
    @ObservedObject var store: BuzzStore
    let openChat: () -> Void
    @Environment(\.openURL) private var openURL
    @State private var showAlerts = false
    @State private var showAbout = false
    @State private var showCity = false

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                ScreenHeader(title: "More")
                VStack(spacing: 0) {
                    MoreRow(icon: "location.fill", title: "My City Settings", subtitle: "आपका शहर: \(store.cityName)") { showCity = true }
                    MoreRow(icon: "bell.fill", title: "Notifications & Widgets", subtitle: "राहुकाल और शुभ मुहूर्त अलर्ट") { showAlerts = true }
                    MoreRow(icon: "bubble.left.and.bubble.right.fill", title: "Kashi Assistant",
                            subtitle: Features.assistant ? "बनारस के बारे में पूछें" : "जल्द आ रहा है", action: openChat)
                    MoreRow(icon: "arrow.clockwise", title: "Refresh", subtitle: store.loading ? "अपडेट हो रहा है…" : "ताज़ा खबरें और पंचांग लाएँ") {
                        Task { await store.refresh(); store.say("अपडेट हो गया") }
                    }
                    MoreRow(icon: "info.circle.fill", title: "About Banaras Buzz", subtitle: "Our Mission") { showAbout = true }
                    ShareLink(item: URL(string: "https://prabhat-twr.github.io/vns-news-api/")!,
                              message: Text("Banaras Buzz — अपना बनारस, हर दिन")) {
                        MoreRowLabel(icon: "square.and.arrow.up", title: "Share App", subtitle: "With Friends & Family")
                    }
                    .buttonStyle(.plain)
                    MoreRow(icon: "lock.fill", title: "Terms & Privacy", subtitle: "Your Data Matters", divider: false) {
                        if let u = URL(string: "https://prabhat-twr.github.io/vns-news-api/privacy.html") { openURL(u) }
                    }
                }
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .padding(.horizontal, 16)

                ZStack(alignment: .trailing) {
                    BanarasScene(mood: .dawn)
                    LinearGradient(colors: [.clear, Color(hex: 0xFFF3E0, alpha: 0.75)], startPoint: .leading, endPoint: .trailing)
                    Text("Together for a\nBetter Banaras ❤️").font(.system(size: 16, weight: .bold)).foregroundColor(BZ.ink)
                        .multilineTextAlignment(.trailing).padding(.trailing, 18)
                }
                .frame(height: 130)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .padding(.horizontal, 16)
            }
            .padding(.bottom, 20)
        }
        .sheet(isPresented: $showAlerts) { AlertSettingsSheet(store: store) }
        .confirmationDialog("अपना शहर चुनें", isPresented: $showCity, titleVisibility: .visible) {
            ForEach(store.cities(), id: \.0) { c in Button(c.1) { store.cityId = c.0 } }
        }
        .alert("Banaras Buzz", isPresented: $showAbout) {
            Button("ठीक है", role: .cancel) {}
        } message: {
            Text("वाराणसी, मिर्ज़ापुर और जौनपुर की ताज़ा खबरें, रोज़ का पंचांग, व्रत-त्योहार और शहर के कार्यक्रम — एक ही जगह। खबरें मूल स्रोतों से ली जाती हैं और हर खबर पर उसका स्रोत दिखाया जाता है।")
        }
    }
}

private struct MoreRowLabel: View {
    let icon: String
    let title: String
    let subtitle: String
    var divider = true
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                Image(systemName: icon).font(.system(size: 17)).foregroundColor(BZ.saffron)
                    .frame(width: 40, height: 40).background(BZ.tile).clipShape(Circle())
                VStack(alignment: .leading, spacing: 1) {
                    Text(title).font(.system(size: 16, weight: .semibold)).foregroundColor(BZ.ink)
                    Text(subtitle).font(.system(size: 13)).foregroundColor(BZ.muted)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 13, weight: .semibold)).foregroundColor(BZ.muted)
            }
            .padding(.horizontal, 14).padding(.vertical, 11)
            .contentShape(Rectangle())
            if divider { Rectangle().fill(BZ.line).frame(height: 1).padding(.leading, 68) }
        }
    }
}

private struct MoreRow: View {
    let icon: String
    let title: String
    let subtitle: String
    var divider = true
    let action: () -> Void
    var body: some View {
        Button(action: action) { MoreRowLabel(icon: icon, title: title, subtitle: subtitle, divider: divider) }
            .buttonStyle(.plain)
    }
}
