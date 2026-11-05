// "आज का पंचांग" widget for the home screen and the lock screen — the iOS counterpart of the
// Android app's pinned notification and home-screen widget. It shows what is happening now
// (Rahu Kaal / Shubh Muhurat) or what comes next, with a live countdown, plus tithi and
// nakshatra. It fetches the 8-day panchang file itself and falls back to sunrise-based
// calculation, so it needs no shared container with the app.
import SwiftUI
import WidgetKit

private enum W {
    static let saffron = Color(red: 0.95, green: 0.42, blue: 0.11)
    static let saffronDeep = Color(red: 0.83, green: 0.32, blue: 0.05)
    static let ink = Color(red: 0.17, green: 0.10, blue: 0.06)
    static let inkSoft = Color(red: 0.29, green: 0.21, blue: 0.15)
    static let muted = Color(red: 0.54, green: 0.46, blue: 0.39)
    static let cream = Color(red: 1.0, green: 0.95, blue: 0.89)
    static let rahuBg = Color(red: 0.99, green: 0.89, blue: 0.88)
    static let shubhBg = Color(red: 1.0, green: 0.95, blue: 0.79)
}

struct PanchangEntry: TimelineEntry {
    let date: Date
    let status: PStatus
}

struct PanchangProvider: TimelineProvider {
    private var cacheURL: URL {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("widget-panchang-days.json")
    }

    func placeholder(in context: Context) -> PanchangEntry {
        PanchangEntry(date: Date(), status: pkStatus(at: Date(), today: nil, tomorrow: nil))
    }

    func getSnapshot(in context: Context, completion: @escaping (PanchangEntry) -> Void) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PanchangEntry>) -> Void) {
        Task {
            var data: Data?
            if case .ok(let fresh) = await pkFetch("varanasi-panchang-days.json", timeout: 10) {
                data = fresh
                try? fresh.write(to: cacheURL)
            } else {
                data = try? Data(contentsOf: cacheURL)
            }
            let days = parsePDays(pkJSON(data))

            // One entry per change (each Rahu Kaal / Abhijit start and end, and midnight) for ~2 days.
            let now = Date()
            var entries: [PanchangEntry] = []
            var t = now
            while entries.count < 16 && t.timeIntervalSince(now) < 2 * 86400 {
                let key = pkDayKey(t)
                let st = pkStatus(at: t, today: days[key], tomorrow: days[pkAddDays(key, 1)])
                entries.append(PanchangEntry(date: t, status: st))
                t = st.nextChange.addingTimeInterval(1)
            }
            // Ask again within a few hours so new panchang data (and tithi changes) show up.
            let refresh = min(t, now.addingTimeInterval(4 * 3600))
            completion(Timeline(entries: entries, policy: .after(refresh)))
        }
    }
}

extension View {
    @ViewBuilder
    func panchangWidgetBackground(_ color: Color) -> some View {
        if #available(iOSApplicationExtension 17.0, *) {
            containerBackground(for: .widget) { color }
        } else {
            background(color)
        }
    }
}

/// Live countdown text; plain text when the target is already past.
private struct Countdown: View {
    let from: Date
    let to: Date?
    var body: some View {
        if let to, to > from {
            Text(timerInterval: from...to, countsDown: true)
        } else {
            Text("")
        }
    }
}

struct PanchangWidgetView: View {
    let entry: PanchangEntry
    @Environment(\.widgetFamily) private var family

    private var st: PStatus { entry.status }
    private var background: Color { st.inRahu ? W.rahuBg : st.inShubh ? W.shubhBg : W.cream }

    var body: some View {
        content
            .widgetURL(URL(string: "banarasbuzz://panchang"))
    }

    @ViewBuilder
    private var content: some View {
        switch family {
        case .accessoryInline:
            Text(st.shortTitle)
                .panchangWidgetBackground(.clear)
        case .accessoryCircular:
            ZStack {
                AccessoryWidgetBackground()
                VStack(spacing: 0) {
                    Image(systemName: st.inRahu ? "moon.fill" : "sun.max.fill").font(.system(size: 13))
                    Text(st.inRahu ? "राहु" : st.inShubh ? "शुभ" : "अगला").font(.system(size: 10, weight: .semibold))
                    Text(pkClock(st.countdownTo).replacingOccurrences(of: " AM", with: "").replacingOccurrences(of: " PM", with: ""))
                        .font(.system(size: 11, weight: .bold)).minimumScaleFactor(0.7)
                }
            }
            .panchangWidgetBackground(.clear)
        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 1) {
                Text(st.shortTitle).font(.system(size: 14, weight: .bold)).lineLimit(1).minimumScaleFactor(0.8)
                HStack(spacing: 4) {
                    Countdown(from: entry.date, to: st.countdownTo).font(.system(size: 14, weight: .semibold)).monospacedDigit()
                    if let label = st.countdownLabel { Text(label).font(.system(size: 11)) }
                }
                Text(st.line2).font(.system(size: 12)).lineLimit(1).minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .panchangWidgetBackground(.clear)
        case .systemSmall:
            VStack(alignment: .leading, spacing: 4) {
                Text("🛕 आज का पंचांग").font(.system(size: 11, weight: .bold)).foregroundColor(W.saffronDeep)
                Text(st.shortTitle).font(.system(size: 14, weight: .bold)).foregroundColor(W.ink).lineLimit(2)
                Countdown(from: entry.date, to: st.countdownTo)
                    .font(.system(size: 22, weight: .bold)).foregroundColor(W.saffron).monospacedDigit()
                if let label = st.countdownLabel { Text(label).font(.system(size: 11)).foregroundColor(W.muted) }
                Spacer(minLength: 0)
                Text(st.line2).font(.system(size: 11)).foregroundColor(W.inkSoft).lineLimit(2)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .panchangWidgetBackground(background)
        default:
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("🛕 आज का पंचांग").font(.system(size: 12, weight: .bold)).foregroundColor(W.saffronDeep)
                    Spacer()
                    Text(pkHindiShortDate(st.date)).font(.system(size: 12)).foregroundColor(W.muted)
                }
                Text(st.title).font(.system(size: 15, weight: .bold)).foregroundColor(W.ink).lineLimit(2)
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Countdown(from: entry.date, to: st.countdownTo)
                        .font(.system(size: 22, weight: .bold)).foregroundColor(W.saffron).monospacedDigit()
                    if let label = st.countdownLabel { Text(label).font(.system(size: 12)).foregroundColor(W.muted) }
                }
                Text(st.line2).font(.system(size: 13)).foregroundColor(W.inkSoft).lineLimit(1)
                HStack(spacing: 6) {
                    Chip(text: "🌑 राहुकाल\n\(st.rahuRange)")
                    Chip(text: "✨ शुभ (अभिजित)\n\(st.shubhRange ?? "बुधवार को नहीं")")
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .panchangWidgetBackground(background)
        }
    }
}

private struct Chip: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.system(size: 11))
            .foregroundColor(W.ink)
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .minimumScaleFactor(0.8)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 5)
            .background(Color.white.opacity(0.8))
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

struct PanchangWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "PanchangWidget", provider: PanchangProvider()) { entry in
            PanchangWidgetView(entry: entry)
        }
        .configurationDisplayName("आज का पंचांग")
        .description("राहुकाल, शुभ मुहूर्त और तिथि, उलटी गिनती के साथ")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular, .accessoryInline, .accessoryCircular])
    }
}

@main
struct BanarasBuzzWidgets: WidgetBundle {
    var body: some Widget {
        PanchangWidget()
    }
}
