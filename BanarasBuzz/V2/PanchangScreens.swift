import SwiftUI

struct PanchangScreen: View {
    @ObservedObject var store: BuzzStore
    @State private var showAlerts = false
    @State private var showPicker = false

    var body: some View {
        let today = pkTodayKey()
        let sel = store.selectedDate.flatMap { $0 > today ? $0 : nil } ?? today
        let isToday = sel == today
        let lastDay = store.year?.end ?? pkAddDays(today, 365)
        let p = store.panchang(for: sel)

        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 10) {
                    HStack {
                        Text("☀️").font(.system(size: 28))
                        Spacer()
                        VStack(spacing: 2) {
                            Text(isToday ? "आज का पंचांग" : "पंचांग").font(.system(size: 27, weight: .heavy)).foregroundColor(BZ.ink)
                            Text(pkHindiLongDate(isToday ? (p?.date ?? today) : sel))
                                .font(.system(size: 15, weight: .medium)).foregroundColor(BZ.inkSoft)
                        }
                        Spacer()
                        Text("🔆").font(.system(size: 28))
                    }
                    .padding(.horizontal, 18).padding(.top, 12)
                    .id("top")

                    // Day navigation.
                    HStack(spacing: 8) {
                        DayButton(label: "◀", enabled: !isToday) { store.selectedDate = pkAddDays(sel, -1) }
                        Button { showPicker = true } label: {
                            Text("📅 तारीख चुनें").font(.system(size: 15, weight: .semibold)).foregroundColor(BZ.ink)
                                .frame(maxWidth: .infinity).padding(.vertical, 10)
                                .background(Color.white).clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                        DayButton(label: "▶", enabled: sel < lastDay) { store.selectedDate = pkAddDays(sel, 1) }
                        if !isToday { DayButton(label: "आज", enabled: true) { store.selectedDate = nil } }
                    }
                    .padding(.horizontal, 16)

                    if let p {
                        content(p, isToday: isToday, today: today)
                    } else {
                        missing(isToday: isToday)
                    }
                }
                .padding(.bottom, 24)
            }
            .background(LinearGradient(colors: [Color(hex: 0xFFEBCF), BZ.cream], startPoint: .top, endPoint: .center).ignoresSafeArea())
            .onChange(of: sel) { _ in
                withAnimation { proxy.scrollTo("top", anchor: .top) }
                if !isToday && store.nextDays[sel] == nil { store.ensureYear() }
            }
            .onAppear { if !isToday && store.nextDays[sel] == nil { store.ensureYear() } }
        }
        .sheet(isPresented: $showAlerts) { AlertSettingsSheet(store: store) }
        .sheet(isPresented: $showPicker) {
            DatePickSheet(selected: sel, first: today, last: lastDay) { key in
                store.selectedDate = key == today ? nil : key
            }
        }
    }

    @ViewBuilder
    private func missing(isToday: Bool) -> some View {
        if isToday {
            EmptyNote(text: "अभी पंचांग उपलब्ध नहीं है। थोड़ी देर बाद फिर देखें।")
        } else if store.yearLoading || (store.year == nil && store.yearProblem == nil) {
            EmptyNote(text: "साल भर का पंचांग लाया जा रहा है…")
        } else if let problem = store.yearProblem {
            Button { store.ensureYear(force: true) } label: {
                Text(problem == .notPublished
                     ? "इस तारीख का पंचांग अभी सर्वर पर प्रकाशित नहीं हुआ है। अभी अगले 7 दिन देखे जा सकते हैं। दोबारा जाँचने के लिए टैप करें।"
                     : "इंटरनेट नहीं मिला, इसलिए इस तारीख का पंचांग नहीं लाया जा सका। दोबारा कोशिश के लिए टैप करें।")
                    .font(.system(size: 14, weight: .semibold)).foregroundColor(BZ.saffronDeep)
                    .multilineTextAlignment(.center).padding(12).frame(maxWidth: .infinity)
                    .background(BZ.tileStrong).clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain).padding(16)
        } else {
            EmptyNote(text: "इस तारीख का पंचांग उपलब्ध नहीं है।")
        }
    }

    @ViewBuilder
    private func content(_ p: PDay, isToday: Bool, today: String) -> some View {
        if isToday && p.date != today {
            Button { Task { await store.refresh() } } label: {
                Text(store.loading ? "नया पंचांग लाया जा रहा है…" : "यह पंचांग \(pkHindiShortDate(p.date)) का है — ताज़ा करने के लिए यहाँ टैप करें")
                    .font(.system(size: 13, weight: .semibold)).foregroundColor(BZ.saffronDeep)
                    .multilineTextAlignment(.center).padding(8).frame(maxWidth: .infinity)
                    .background(BZ.tileStrong).clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain).padding(.horizontal, 16)
        } else if let m = p.monthHi {
            Text("\(m) मास").font(.system(size: 13)).foregroundColor(BZ.saffronDeep)
        }

        VStack(spacing: 10) {
            HStack(spacing: 10) {
                InfoTile(label: "तिथि") {
                    if let t = p.tithi.first {
                        Text(pkPakshaInHindi(t.paksha)).font(.system(size: 15)).foregroundColor(BZ.inkSoft)
                        BigValue(text: t.display)
                        EndsAt(date: t.endsAt)
                    } else { BigValue(text: "—") }
                }
                InfoTile(label: "नक्षत्र") {
                    if let n = p.nakshatra.first {
                        BigValue(text: n.display)
                        EndsAt(date: n.endsAt)
                    } else { BigValue(text: "—") }
                }
            }
            HStack(spacing: 10) {
                InfoTile(label: "राहुकाल") {
                    Text(p.rahu?.range ?? "—").font(.system(size: 15, weight: .bold)).foregroundColor(BZ.saffronDeep)
                        .lineLimit(1).minimumScaleFactor(0.8)
                    Text("(सावधान रहें)").font(.system(size: 12)).foregroundColor(BZ.muted)
                }
                InfoTile(label: "") {
                    HStack(spacing: 6) {
                        Text("☀️").font(.system(size: 22))
                        VStack(alignment: .leading, spacing: 0) {
                            Text("सूर्योदय").font(.system(size: 14, weight: .semibold)).foregroundColor(BZ.inkSoft)
                            Text(pkClockPadded(p.sunrise)).font(.system(size: 16, weight: .bold)).foregroundColor(BZ.saffronDeep)
                        }
                    }
                    Text("सूर्यास्त \(pkClockPadded(p.sunset))").font(.system(size: 13)).foregroundColor(BZ.saffronDeep)
                }
            }

            Button { showAlerts = true } label: {
                let on = PanchangAlerts.anyEnabled
                HStack(spacing: 10) {
                    Text("🔔").font(.system(size: 18))
                    VStack(alignment: .leading, spacing: 1) {
                        Text("राहुकाल और शुभ मुहूर्त अलर्ट").font(.system(size: 15, weight: .semibold)).foregroundColor(BZ.ink)
                        Text(on ? "चालू — बदलने के लिए टैप करें" : "सूचना और लॉक स्क्रीन विजेट").font(.system(size: 12.5)).foregroundColor(BZ.muted)
                    }
                    Spacer()
                    Text(on ? "चालू" : "चालू करें").font(.system(size: 13, weight: .bold))
                        .foregroundColor(on ? BZ.saffron : .white)
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .background(on ? BZ.tile : BZ.saffron).clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .padding(.horizontal, 14).padding(.vertical, 10)
                .background(Color.white).clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)

            GoldBand {
                Text("शुभ मुहूर्त").font(.system(size: 23, weight: .heavy)).foregroundColor(BZ.ink)
                Text("अभिजित मुहूर्त").font(.system(size: 16, weight: .semibold)).foregroundColor(BZ.inkSoft)
                Text(p.abhijit?.range ?? "उपलब्ध नहीं").font(.system(size: 19, weight: .bold)).foregroundColor(BZ.ink)
            }

            let todays = uniq(p.festivals + store.allObservances.filter { $0.date == p.date }.map { $0.display })
            GoldBand {
                Text(isToday ? "आज के व्रत और त्योहार" : "इस दिन के व्रत और त्योहार").font(.system(size: 17, weight: .bold)).foregroundColor(BZ.ink)
                Text(todays.isEmpty ? "कोई विशेष व्रत या त्योहार नहीं" : todays.joined(separator: " • "))
                    .font(.system(size: 15)).foregroundColor(BZ.inkSoft).multilineTextAlignment(.center)
            }

            HStack(spacing: 10) {
                SmallFact(label: "योग", value: p.yoga.first?.display ?? "—")
                SmallFact(label: "करण", value: p.karana.first?.display ?? "—")
                SmallFact(label: "चंद्रोदय", value: p.moonrise.map { pkClockPadded($0) } ?? "—")
            }
        }
        .padding(.horizontal, 16)

        BanarasScene(mood: .dawn).frame(height: 160).padding(.top, 6)

        let upcoming = store.allObservances.filter { $0.date >= today }.prefix(12)
        HStack {
            SectionTitle(text: "आने वाले व्रत और त्योहार")
            Spacer()
            Button("पूरा साल →") { store.go(.year) }
                .font(.system(size: 15, weight: .bold)).foregroundColor(BZ.saffron).padding(.trailing, 16)
        }
        if upcoming.isEmpty { EmptyNote(text: "आने वाले दिनों की सूची जल्द अपडेट होगी।") }
        VStack(spacing: 10) {
            ForEach(Array(upcoming)) { o in
                Button { store.selectedDate = o.date } label: { ObservanceRow(o: o, showDescription: true) }
                    .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
    }

    private func uniq(_ xs: [String]) -> [String] {
        var seen = Set<String>()
        return xs.filter { seen.insert($0).inserted }
    }
}

struct ObservanceRow: View {
    let o: PObservance
    var showDescription = false
    var weekdayLabel = false
    var body: some View {
        HStack(spacing: 12) {
            DateBox(key: o.date, label: weekdayLabel ? pkWeekdaysShortHi[pkWeekdayMon0(o.date)] : nil)
            VStack(alignment: .leading, spacing: 2) {
                Text(o.display).font(.system(size: 15, weight: .bold)).foregroundColor(BZ.ink)
                Text([o.typeHi, [pkPakshaInHindi(o.paksha), pkTithiInHindi(o.tithi)].filter { !$0.isEmpty }.joined(separator: " ")]
                        .filter { !$0.isEmpty }.joined(separator: " • "))
                    .font(.system(size: 12.5)).foregroundColor(BZ.saffronDeep)
                if showDescription && !o.description.isEmpty {
                    Text(o.description).font(.system(size: 13)).foregroundColor(BZ.muted).lineLimit(2)
                }
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right").font(.system(size: 12)).foregroundColor(BZ.muted)
        }
        .padding(12)
        .background(o.type == "vrat" ? Color.white : BZ.tile)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

private struct DayButton: View {
    let label: String
    let enabled: Bool
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(label).font(.system(size: 15, weight: .bold))
                .foregroundColor(enabled ? BZ.saffron : BZ.line)
                .padding(.horizontal, 14).padding(.vertical, 10)
                .background(Color.white).clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }
}

private struct InfoTile<Content: View>: View {
    let label: String
    @ViewBuilder let content: () -> Content
    var body: some View {
        VStack(spacing: 2) {
            if !label.isEmpty { Text(label).font(.system(size: 18, weight: .bold)).foregroundColor(BZ.ink) }
            content()
        }
        .frame(maxWidth: .infinity, minHeight: 118)
        .padding(10)
        .background(BZ.panchangTile)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct BigValue: View {
    let text: String
    var body: some View {
        Text(text).font(.system(size: 23, weight: .heavy)).foregroundColor(BZ.ink)
            .multilineTextAlignment(.center).minimumScaleFactor(0.7)
    }
}

private struct EndsAt: View {
    let date: Date?
    var body: some View {
        if let date { Text("\(pkClock(date)) तक").font(.system(size: 12)).foregroundColor(BZ.muted) }
    }
}

private struct GoldBand<Content: View>: View {
    @ViewBuilder let content: () -> Content
    var body: some View {
        VStack(spacing: 2) { content() }
            .frame(maxWidth: .infinity)
            .padding(14)
            .background(BZ.panchangGold)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct SmallFact: View {
    let label: String
    let value: String
    var body: some View {
        VStack(spacing: 2) {
            Text(label).font(.system(size: 13, weight: .semibold)).foregroundColor(BZ.inkSoft)
            Text(value).font(.system(size: 14, weight: .bold)).foregroundColor(BZ.ink).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(10)
        .background(BZ.panchangTile)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

/// Graphical date picker limited to the days we have panchang for.
private struct DatePickSheet: View {
    let selected: String
    let first: String
    let last: String
    let onPick: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var date = Date()

    var body: some View {
        NavigationStack {
            VStack {
                DatePicker("तारीख", selection: $date,
                           in: (pkStartOfDay(first) ?? Date())...(pkStartOfDay(last) ?? Date()),
                           displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .tint(BZ.saffron)
                    .environment(\.timeZone, pkIST)
                    .padding()
                Spacer()
            }
            .navigationTitle("तारीख चुनें")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("रद्द करें") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("दिखाएँ") { onPick(pkDayKey(date)); dismiss() }.foregroundColor(BZ.saffron)
                }
            }
            .onAppear { date = pkStartOfDay(selected)?.addingTimeInterval(12 * 3600) ?? Date() }
        }
        .presentationDetents([.medium, .large])
    }
}

/// Every vrat and tyohar of the next 12 months, by month.
struct YearScreen: View {
    @ObservedObject var store: BuzzStore
    @State private var filter = 0
    private let filters = ["सभी", "त्योहार", "एकादशी", "अन्य व्रत"]

    var body: some View {
        VStack(spacing: 0) {
            ScreenHeader(title: "साल भर के व्रत-त्योहार", onBack: { store.back() })
            PillChips(labels: filters, selected: $filter)
            if let year = store.year {
                let today = pkTodayKey()
                let list = year.observances.filter { o in
                    guard o.date >= today else { return false }
                    switch filter {
                    case 1: return o.type != "vrat"
                    case 2: return o.name.contains("Ekadashi")
                    case 3: return o.type == "vrat" && !o.name.contains("Ekadashi")
                    default: return true
                    }
                }
                let months = Array(Set(list.map { String($0.date.prefix(7)) })).sorted()
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        Text("\(list.count) व्रत-त्योहार · \(pkHindiShortDate(year.start)) से \(pkHindiShortDate(year.end)) \(String(year.end.prefix(4))) तक")
                            .font(.system(size: 12.5)).foregroundColor(BZ.muted)
                        ForEach(months, id: \.self) { ym in
                            Text("\(pkMonthHi(ym + "-01")) \(String(ym.prefix(4)))")
                                .font(.system(size: 18, weight: .bold)).foregroundColor(BZ.ink).padding(.top, 10)
                            ForEach(list.filter { $0.date.hasPrefix(ym) }) { o in
                                Button { store.selectedDate = o.date; store.go(.panchang) } label: {
                                    ObservanceRow(o: o, weekdayLabel: true)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal, 16).padding(.bottom, 24)
                }
            } else if store.yearLoading || store.yearProblem == nil {
                EmptyNote(text: "साल भर का पंचांग लाया जा रहा है…")
                Spacer()
            } else {
                Button { store.ensureYear(force: true) } label: {
                    Text(store.yearProblem == .notPublished
                         ? "साल भर की सूची अभी सर्वर पर प्रकाशित नहीं हुई है। दोबारा जाँचने के लिए टैप करें।"
                         : "इंटरनेट नहीं मिला, इसलिए सूची नहीं लाई जा सकी। दोबारा कोशिश के लिए टैप करें।")
                        .font(.system(size: 14, weight: .semibold)).foregroundColor(BZ.saffronDeep)
                        .multilineTextAlignment(.center).padding(12).frame(maxWidth: .infinity)
                        .background(BZ.tileStrong).clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain).padding(16)
                Spacer()
            }
        }
        .onAppear { store.ensureYear() }
    }
}
