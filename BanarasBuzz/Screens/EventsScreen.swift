// Ported from the Android app's ui/screens/EventsScreen.kt — Events, Today's Panchang,
// Vrat & Tyohar, and Aarti & Darshan all live in this one scrolling screen (matching the
// merge the Android app went through: "put arti and events together").
import SwiftUI

private let DAY_NUMS = [17, 18, 19, 20, 21, 22, 23]
private let MOCK_HI_DIGITS = ["१७", "१८", "१९", "२०", "२१", "२२", "२३"]
private let MONTH_ABBR_EN = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]

func eventSheetFor(_ e: EventItem, state: AppState) -> SheetContent {
    let lang = state.lang
    let s = strings(for: lang)
    let on = state.isGoing(e.id)
    let src = e.sourceUrl
    return SheetContent(
        image: e.image.of(lang), kicker: e.category.of(lang), meta: "\(e.start) · \(e.venue.of(lang))",
        title: e.title.of(lang), body1: e.body1.of(lang), body2: e.body2.of(lang),
        actionLabel: on ? s.goingOn : s.going, actionAccent: on,
        sourceLabel: src != nil ? s.openSource : nil,
        onOpenSource: src != nil ? { state.sourcePage = SourcePage(url: src!, title: e.title.of(lang)) } : nil
    ) {
        state.toggleGoing(e.id,
            addedMsg: lang == .hi ? "आयोजन सहेजा गया" : "Added to your events",
            removedMsg: lang == .hi ? "हटा दिया गया" : "Removed")
    }
}

func observanceSheetFor(_ o: Observance, state: AppState) -> SheetContent {
    let lang = state.lang
    let s = strings(for: lang)
    let typeLabel = o.type == "vrat" ? s.vratLabel : (o.type == "tyohar" ? s.tyoharLabel : s.bothLabel)
    let on = state.hasReminder(o.id)
    return SheetContent(
        image: lang == .hi ? "फ़ोटो: \(o.name)" : "photo: \(o.name)", kicker: typeLabel,
        meta: formatObservanceDate(o.date, lang: lang), title: o.name, body1: o.description,
        body2: "\(o.tithi) · \(o.paksha) Paksha", actionLabel: on ? s.remindOn : s.remindMe, actionAccent: on
    ) {
        state.toggleReminder(o.id, setMsg: s.remindOn)
    }
}

private func formatTime(_ hhmm: String, lang: Lang) -> String { lang == .hi ? toHindiDigits(hhmm) : hhmm }

private func formatObservanceDate(_ iso: String, lang: Lang) -> String {
    let parts = iso.split(separator: "-")
    guard parts.count == 3, let month = Int(parts[1]), let day = Int(parts[2]) else { return iso }
    let dayStr = lang == .hi ? toHindiDigits(String(day)) : String(day)
    let monthStr = MONTH_ABBR_EN.indices.contains(month - 1) ? MONTH_ABBR_EN[month - 1] : ""
    return "\(dayStr) \(monthStr)"
}

struct EventsScreen: View {
    @ObservedObject var state: AppState

    var body: some View {
        let lang = state.lang
        let s = strings(for: lang)
        let usingLive = !state.liveEvents.isEmpty
        let activeEvents = usingLive ? state.liveEvents : MOCK_EVENTS
        var istCal = Calendar(identifier: .gregorian)
        istCal.timeZone = istTimeZone
        let liveWeek: [Date]? = usingLive ? (0..<7).map { istCal.date(byAdding: .day, value: $0, to: todayIst())! } : nil

        let filterLabels = usingLive ? s.eventFiltersLive : s.eventFilters
        let filterTagEn = (usingLive ? StringsEN.eventFiltersLive : StringsEN.eventFilters).indices.contains(state.eventFilterIndex)
            ? (usingLive ? StringsEN.eventFiltersLive : StringsEN.eventFilters)[state.eventFilterIndex] : "All"

        let dayEvents = activeEvents.filter { e in
            let dayMatches = usingLive ? (e.fullDate == state.selectedDayIso) : (e.day == state.selectedDay)
            return dayMatches && (state.eventFilterIndex == 0 || e.tag == filterTagEn)
        }.sorted { $0.start < $1.start }

        return ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                Text(s.eventsTitle)
                    .font(BBFonts.headline(30, weight: .semibold))
                    .foregroundColor(BBColors.textPrimary)
                    .padding(.top, 18)
                Text(usingLive ? s.liveEventsSub : s.eventsSub)
                    .font(BBFonts.mono(12.5))
                    .foregroundColor(BBColors.textFaint)
                    .padding(.top, 8)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        if usingLive, let liveWeek {
                            ForEach(liveWeek, id: \.self) { date in
                                let iso = isoDateString(date)
                                let active = state.selectedDayIso == iso
                                let has = activeEvents.contains { $0.fullDate == iso }
                                let wdIndex = (istCal.component(.weekday, from: date) + 5) % 7 // Mon=0..Sun=6
                                let dayNum = istCal.component(.day, from: date)
                                DayCell(
                                    wdLabel: s.wd.indices.contains(wdIndex) ? s.wd[wdIndex] : "",
                                    dayLabel: lang == .hi ? toHindiDigits(String(dayNum)) : String(dayNum),
                                    active: active, hasEvent: has
                                ) {
                                    state.selectedDay = dayNum
                                    state.selectedDayIso = iso
                                }
                            }
                        } else {
                            ForEach(Array(DAY_NUMS.enumerated()), id: \.offset) { i, day in
                                let active = state.selectedDay == day
                                let has = MOCK_EVENTS.contains { $0.day == day }
                                DayCell(
                                    wdLabel: s.wd.indices.contains(i) ? s.wd[i] : "",
                                    dayLabel: lang == .hi ? MOCK_HI_DIGITS[i] : String(day),
                                    active: active, hasEvent: has
                                ) {
                                    state.selectedDay = day
                                }
                            }
                        }
                    }
                }
                .padding(.top, 18)

                PillFilterRow(options: filterLabels.enumerated().map { i, label in
                    PillOption(label: label, active: state.eventFilterIndex == i) { state.eventFilterIndex = i }
                })
                .padding(.top, 18)

                if dayEvents.isEmpty {
                    Text(s.noEvents)
                        .font(BBFonts.body(13))
                        .foregroundColor(BBColors.textFainter)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                        .padding(.vertical, 44)
                } else {
                    ForEach(Array(dayEvents.enumerated()), id: \.element.id) { index, e in
                        let on = state.isGoing(e.id)
                        VStack(spacing: 0) {
                            HStack(alignment: .top, spacing: 0) {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(e.start).font(BBFonts.mono(13, weight: .semibold)).foregroundColor(BBColors.textPrimary)
                                    Text(e.duration.of(lang)).font(BBFonts.mono(11)).foregroundColor(BBColors.textFainter)
                                }
                                .frame(width: 62, alignment: .leading)
                                Rectangle().fill(on ? BBColors.vermillion : BBColors.borderMed).frame(width: 2)
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(e.category.of(lang).uppercased())
                                        .font(BBFonts.mono(9.5, weight: .semibold)).foregroundColor(BBColors.vermillion).tracking(0.9)
                                    Text(e.title.of(lang))
                                        .font(BBFonts.headline(18, weight: .semibold)).foregroundColor(BBColors.textPrimary)
                                    Text(e.venue.of(lang))
                                        .font(BBFonts.body(12.5)).foregroundColor(BBColors.textMuted)
                                    HStack {
                                        Text(e.price.of(lang)).font(BBFonts.mono(11)).foregroundColor(BBColors.textFaint)
                                        Spacer()
                                        Text(on ? s.goingOn : s.going)
                                            .font(BBFonts.body(11.5, weight: .medium))
                                            .foregroundColor(on ? BBColors.inkOnDark : BBColors.textBody)
                                            .padding(.horizontal, 12).padding(.vertical, 6)
                                            .background(on ? BBColors.vermillion : .clear)
                                            .clipShape(Capsule())
                                            .overlay(Capsule().stroke(on ? BBColors.vermillion : BBColors.borderStrong, lineWidth: 1))
                                            .onTapGesture {
                                                state.toggleGoing(e.id,
                                                    addedMsg: lang == .hi ? "आयोजन सहेजा गया" : "Added to your events",
                                                    removedMsg: lang == .hi ? "हटा दिया गया" : "Removed")
                                            }
                                    }
                                    .padding(.top, 4)
                                }
                                .padding(.leading, 14)
                            }
                            .padding(.vertical, 17)
                            if index != dayEvents.indices.last {
                                Rectangle().fill(BBColors.borderSoft).frame(height: 1)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture { state.sheet = eventSheetFor(e, state: state) }
                    }
                }

                // Today's Panchang.
                Text(s.panchangTitle)
                    .font(BBFonts.headline(22, weight: .semibold))
                    .foregroundColor(BBColors.textPrimary)
                    .padding(.top, 36)
                Text(s.panchangSub)
                    .font(BBFonts.mono(12.5))
                    .foregroundColor(BBColors.textFaint)
                    .padding(.top, 8)

                if let p = state.panchang {
                    VStack(alignment: .leading, spacing: 0) {
                        PanchangAngaRow(label: s.tithiLabel, angas: p.tithi, lang: lang)
                        PanchangAngaRow(label: s.nakshatraLabel, angas: p.nakshatra, lang: lang).padding(.top, 12)
                        PanchangAngaRow(label: s.yogaLabel, angas: p.yoga, lang: lang).padding(.top, 12)
                        PanchangAngaRow(label: s.karanaLabel, angas: p.karana, lang: lang).padding(.top, 12)

                        Rectangle().fill(BBColors.borderSoft).frame(height: 1).padding(.vertical, 14)

                        HStack {
                            PanchangStat(label: s.sunriseLabel, time: p.sunrise, lang: lang)
                            Spacer()
                            PanchangStat(label: s.sunsetLabel, time: p.sunset, lang: lang)
                        }
                        HStack {
                            PanchangStat(label: s.moonriseLabel, time: p.moonrise, lang: lang)
                            Spacer()
                            PanchangStat(label: s.moonsetLabel, time: p.moonset, lang: lang)
                        }
                        .padding(.top, 12)

                        if let w = p.rahuKaal {
                            HStack {
                                Text(s.rahuKaalLabel).font(BBFonts.mono(11.5, weight: .semibold)).foregroundColor(BBColors.alertEventFg)
                                Spacer()
                                Text("\(formatTime(w.start, lang: lang)) – \(formatTime(w.end, lang: lang))")
                                    .font(BBFonts.mono(11.5)).foregroundColor(BBColors.alertEventFg)
                            }
                            .padding(.horizontal, 12).padding(.vertical, 10)
                            .background(BBColors.alertEventBg)
                            .clipShape(RoundedRectangle(cornerRadius: 9))
                            .padding(.top, 14)
                        }
                        if let w = p.abhijitMuhurat {
                            HStack {
                                Text(s.abhijitLabel).font(BBFonts.mono(11.5, weight: .semibold)).foregroundColor(BBColors.queueLightFg)
                                Spacer()
                                Text("\(formatTime(w.start, lang: lang)) – \(formatTime(w.end, lang: lang))")
                                    .font(BBFonts.mono(11.5)).foregroundColor(BBColors.queueLightFg)
                            }
                            .padding(.horizontal, 12).padding(.vertical, 10)
                            .background(BBColors.queueLightBg)
                            .clipShape(RoundedRectangle(cornerRadius: 9))
                            .padding(.top, 8)
                        }
                    }
                    .padding(15)
                    .background(BBColors.card)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(BBColors.borderCard, lineWidth: 1))
                    .padding(.top, 16)
                } else {
                    Text(s.noPanchang)
                        .font(BBFonts.body(13))
                        .foregroundColor(BBColors.textFainter)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                        .padding(.vertical, 24)
                }

                // Vrat & Tyohar.
                Text(s.vratTyoharTitle)
                    .font(BBFonts.headline(22, weight: .semibold))
                    .foregroundColor(BBColors.textPrimary)
                    .padding(.top, 30)
                Text(s.vratTyoharSub)
                    .font(BBFonts.mono(12.5))
                    .foregroundColor(BBColors.textFaint)
                    .padding(.top, 8)

                if state.upcomingObservances.isEmpty {
                    Text(s.noObservances)
                        .font(BBFonts.body(13))
                        .foregroundColor(BBColors.textFainter)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                        .padding(.vertical, 24)
                } else {
                    VStack(spacing: 8) {
                        ForEach(state.upcomingObservances) { o in
                            let typeLabel = o.type == "vrat" ? s.vratLabel : (o.type == "tyohar" ? s.tyoharLabel : s.bothLabel)
                            HStack(spacing: 12) {
                                Text(formatObservanceDate(o.date, lang: lang))
                                    .font(BBFonts.mono(12, weight: .semibold))
                                    .foregroundColor(BBColors.textPrimary)
                                    .frame(width: 52)
                                    .multilineTextAlignment(.center)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(o.name).font(BBFonts.headline(15, weight: .semibold)).foregroundColor(BBColors.textPrimary)
                                    Text(typeLabel).font(BBFonts.mono(10.5)).foregroundColor(BBColors.vermillion)
                                }
                                Spacer()
                                if state.hasReminder(o.id) {
                                    BellGlyph(color: BBColors.vermillion)
                                }
                            }
                            .padding(14)
                            .background(BBColors.card)
                            .clipShape(RoundedRectangle(cornerRadius: 11))
                            .overlay(RoundedRectangle(cornerRadius: 11).stroke(BBColors.borderCard, lineWidth: 1))
                            .contentShape(Rectangle())
                            .onTapGesture { state.sheet = observanceSheetFor(o, state: state) }
                        }
                    }
                    .padding(.top, 12)
                }

                // Aarti & Darshan.
                Text(s.aartiTitle)
                    .font(BBFonts.headline(22, weight: .semibold))
                    .foregroundColor(BBColors.textPrimary)
                    .padding(.top, 36)
                Text(s.aartiSub)
                    .font(BBFonts.mono(12.5))
                    .foregroundColor(BBColors.textFaint)
                    .padding(.top, 8)

                VStack(spacing: 0) {
                    ForEach(Array(MOCK_AARTIS.enumerated()), id: \.element.id) { index, a in
                        let on = state.hasReminder(a.id)
                        VStack(spacing: 0) {
                            HStack {
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(a.place.of(lang)).font(BBFonts.headline(16, weight: .semibold)).foregroundColor(BBColors.textPrimary)
                                    Text(a.note.of(lang)).font(BBFonts.body(11.5)).foregroundColor(BBColors.textMuted)
                                }
                                Spacer()
                                VStack(alignment: .trailing, spacing: 6) {
                                    Text(a.time).font(BBFonts.mono(13, weight: .semibold)).foregroundColor(BBColors.textPrimary)
                                    Text(a.status.of(lang))
                                        .font(BBFonts.mono(10, weight: .medium))
                                        .foregroundColor(a.hot ? BBColors.vermillion : BBColors.textFaint)
                                }
                                .padding(.trailing, 12)
                                Circle()
                                    .fill(on ? BBColors.vermillion : .clear)
                                    .frame(width: 30, height: 30)
                                    .overlay(Circle().stroke(on ? BBColors.vermillion : BBColors.borderStrong, lineWidth: 1))
                                    .overlay(BellGlyph(color: on ? BBColors.inkOnDark : BBColors.textBody))
                                    .onTapGesture {
                                        state.toggleReminder(a.id, setMsg: lang == .hi ? "याद दिलाया जाएगा" : "Reminder set")
                                    }
                            }
                            .padding(15)
                            .background(index == 0 ? BBColors.card : .clear)
                            if index != MOCK_AARTIS.indices.last {
                                Rectangle().fill(BBColors.borderSoft).frame(height: 1)
                            }
                        }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(BBColors.borderCard, lineWidth: 1))
                .padding(.top, 18)

                Text(s.darshan.uppercased())
                    .font(BBFonts.mono(10, weight: .semibold))
                    .foregroundColor(BBColors.textFaint)
                    .tracking(1)
                    .padding(.top, 26)

                VStack(spacing: 10) {
                    ForEach(MOCK_TEMPLES) { t in
                        let (qBg, qFg, qDot): (Color, Color, Color) = {
                            switch t.level {
                            case 2: return (BBColors.queueHeavyBg, BBColors.queueHeavyFg, BBColors.queueHeavyDot)
                            case 1: return (BBColors.queueModerateBg, BBColors.queueModerateFg, BBColors.queueModerateDot)
                            default: return (BBColors.queueLightBg, BBColors.queueLightFg, BBColors.queueLightDot)
                            }
                        }()
                        HStack(spacing: 12) {
                            ThumbSlot(size: 44)
                            VStack(alignment: .leading, spacing: 5) {
                                Text(t.name.of(lang)).font(BBFonts.headline(16, weight: .semibold)).foregroundColor(BBColors.textPrimary)
                                Text(t.hours.of(lang)).font(BBFonts.body(11.5)).foregroundColor(BBColors.textMuted)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 7) {
                                HStack(spacing: 6) {
                                    Circle().fill(qDot).frame(width: 5, height: 5)
                                    Text(t.queue.of(lang)).font(BBFonts.mono(10.5, weight: .medium)).foregroundColor(qFg)
                                }
                                .padding(.horizontal, 9).padding(.vertical, 5)
                                .background(qBg)
                                .clipShape(Capsule())
                                Text(t.wait.of(lang)).font(BBFonts.mono(10.5)).foregroundColor(BBColors.textFainter)
                            }
                        }
                        .padding(14)
                        .background(BBColors.card)
                        .clipShape(RoundedRectangle(cornerRadius: 11))
                        .overlay(RoundedRectangle(cornerRadius: 11).stroke(BBColors.borderCard, lineWidth: 1))
                        .contentShape(Rectangle())
                        .onTapGesture { state.sheet = templeSheetFor(t, state: state) }
                    }
                }
                .padding(.top, 12)

                Color.clear.frame(height: 110)
            }
            .padding(.horizontal, 18)
        }
    }
}

private struct DayCell: View {
    let wdLabel: String
    let dayLabel: String
    let active: Bool
    let hasEvent: Bool
    let onClick: () -> Void

    var body: some View {
        VStack(spacing: 6) {
            Text(wdLabel).font(BBFonts.mono(9.5, weight: .medium)).foregroundColor(active ? BBColors.gold : BBColors.textGhost)
            Text(dayLabel).font(BBFonts.headline(19, weight: .semibold)).foregroundColor(active ? BBColors.inkOnDark : BBColors.textPrimary)
            Circle()
                .fill(!hasEvent ? Color.clear : (active ? BBColors.goldBright : BBColors.vermillion))
                .frame(width: 4, height: 4)
        }
        .padding(.vertical, 9)
        .frame(width: 50)
        .background(active ? BBColors.ink : .clear)
        .clipShape(RoundedRectangle(cornerRadius: 9))
        .overlay(RoundedRectangle(cornerRadius: 9).stroke(active ? BBColors.ink : BBColors.borderMed, lineWidth: 1))
        .onTapGesture(perform: onClick)
    }
}

private struct PanchangAngaRow: View {
    let label: String
    let angas: [PanchangAnga]
    let lang: Lang

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label.uppercased()).font(BBFonts.mono(9.5, weight: .semibold)).foregroundColor(BBColors.textFaint).tracking(0.9)
            let value = angas.map { a -> String in
                let end = a.endsAt.map { " (\(formatTime($0, lang: lang)))" } ?? ""
                return "\(a.name)\(end)"
            }.joined(separator: " → ")
            Text(value.isEmpty ? "—" : value).font(BBFonts.body(13.5)).foregroundColor(BBColors.textPrimary)
        }
    }
}

private struct PanchangStat: View {
    let label: String
    let time: String?
    let lang: Lang

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label.uppercased()).font(BBFonts.mono(9, weight: .semibold)).foregroundColor(BBColors.textFaint).tracking(0.9)
            Text(time.map { formatTime($0, lang: lang) } ?? "—").font(BBFonts.mono(13, weight: .medium)).foregroundColor(BBColors.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
