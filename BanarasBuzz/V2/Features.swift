// Which sections are live. News and Panchang are; the rest show a "coming soon" screen until
// their data is ready. Set a flag to true to bring that section back unchanged.
import SwiftUI

enum Features {
    static let events = false
    static let business = false
    static let community = false
    static let explore = false
    /// The Kashi Assistant chat (Explore and More).
    static let assistant = false

    static func isLive(_ route: Route2) -> Bool {
        switch route {
        case .events: return events
        case .business: return business
        case .community: return community
        case .explore: return explore
        default: return true
        }
    }
}

/// Small grey "जल्द आ रहा है" badge for tiles and rows that lead to a coming-soon section.
struct SoonBadge: View {
    var body: some View {
        Text("जल्द आ रहा है")
            .font(.system(size: 11, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 7).padding(.vertical, 2)
            .background(BZ.muted)
            .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

struct ComingSoonView: View {
    let route: Route2
    @ObservedObject var store: BuzzStore

    private var info: (title: String, emoji: String, tagline: String, points: [String]) {
        switch route {
        case .events:
            return ("आज बनारस में", "📅", "शहर के कार्यक्रम, एक जगह",
                    ["घाटों और मंदिरों के आयोजन", "संगीत, नाटक और प्रदर्शनियाँ", "देव दीपावली, नाग नथैया जैसे बड़े पर्व"])
        case .business:
            return ("लोकल बिजनेस", "🏪", "बनारस की दुकानें और ऑफ़र",
                    ["खाने-पीने की मशहूर जगहें", "बनारसी साड़ी और हस्तशिल्प", "अपना बिज़नेस जोड़ने की सुविधा"])
        case .community:
            return ("My Banaras", "📍", "बनारस वालों की कहानियाँ",
                    ["फ़ोटो और कहानियाँ साझा करें", "शहर से जुड़े पोल", "मोहल्ले की ख़बरें"])
        default:
            return ("Explore Banaras", "🧭", "मंदिर, घाट और शहर की जानकारी",
                    ["मंदिर और घाट गाइड", "खाना, ख़रीदारी और संस्कृति", "लाइव दर्शन और यात्रा जानकारी", "काशी असिस्टेंट से सवाल पूछें"])
        }
    }

    var body: some View {
        let s = info
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                if route == .explore {
                    ScreenHeader(title: s.title)
                } else {
                    ScreenHeader(title: s.title, onBack: { store.back() })
                }
                ZStack {
                    BanarasScene(mood: .dusk)
                    LinearGradient(colors: [.clear, .black.opacity(0.45)], startPoint: .center, endPoint: .bottom)
                    Text(s.emoji).font(.system(size: 52))
                }
                .frame(height: 170)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .padding(.horizontal, 16)

                VStack(spacing: 4) {
                    Text("जल्द आ रहा है").font(.system(size: 27, weight: .heavy)).foregroundColor(BZ.saffron)
                    Text(s.tagline).font(.system(size: 16)).foregroundColor(BZ.inkSoft).multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)

                VStack(alignment: .leading, spacing: 10) {
                    Text("इसमें क्या होगा").font(.system(size: 15, weight: .bold)).foregroundColor(BZ.ink)
                    ForEach(s.points, id: \.self) { p in
                        HStack(spacing: 10) {
                            Circle().fill(BZ.saffron).frame(width: 8, height: 8)
                            Text(p).font(.system(size: 15)).foregroundColor(BZ.inkSoft)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(BZ.tile)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .padding(.horizontal, 16)

                Text("तब तक").font(.system(size: 13)).foregroundColor(BZ.muted).padding(.horizontal, 20)
                HStack(spacing: 12) {
                    LiveLink(emoji: "📰", label: "ताज़ा खबरें") { store.go(.news) }
                    LiveLink(emoji: "🌞", label: "आज का पंचांग") { store.selectedDate = nil; store.go(.panchang) }
                }
                .padding(.horizontal, 16)
            }
            .padding(.bottom, 20)
        }
    }
}

private struct LiveLink: View {
    let emoji: String
    let label: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text(emoji).font(.system(size: 26))
                Text(label).font(.system(size: 14, weight: .bold)).foregroundColor(BZ.ink)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}
