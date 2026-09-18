// Ported from the Android app's ui/screens/AlertsScreen.kt.
import SwiftUI

struct AlertsScreen: View {
    @ObservedObject var state: AppState

    var body: some View {
        let lang = state.lang
        let s = strings(for: lang)

        return ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .bottom) {
                    Text(s.alertsTitle)
                        .font(BBFonts.headline(30, weight: .semibold))
                        .foregroundColor(BBColors.textPrimary)
                    Spacer()
                    Text(s.markRead)
                        .font(BBFonts.body(11.5, weight: .medium))
                        .foregroundColor(BBColors.vermillion)
                        .onTapGesture { state.markAllRead(MOCK_ALERTS.map { $0.id }) }
                }
                .padding(.top, 18)

                Color.clear.frame(height: 14)

                ForEach(Array(MOCK_ALERTS.enumerated()), id: \.element.id) { index, n in
                    let unread = n.unread && !state.isRead(n.id)
                    let (chipBg, chipFg): (Color, Color) = {
                        switch n.kind {
                        case "aarti": return (BBColors.alertAartiBg, BBColors.alertAartiFg)
                        case "event": return (BBColors.alertEventBg, BBColors.alertEventFg)
                        case "bazaar": return (BBColors.alertBazaarBg, BBColors.alertBazaarFg)
                        default: return (BBColors.alertNewsBg, BBColors.alertNewsFg)
                        }
                    }()
                    VStack(spacing: 0) {
                        HStack(alignment: .top, spacing: 13) {
                            Circle().fill(chipBg).frame(width: 32, height: 32)
                                .overlay(Text(n.tag.of(lang)).font(BBFonts.mono(10, weight: .semibold)).foregroundColor(chipFg))
                            VStack(alignment: .leading, spacing: 7) {
                                Text(n.text.of(lang))
                                    .font(BBFonts.body(14, weight: .medium))
                                    .foregroundColor(BBColors.textHeading2)
                                Text(n.time.of(lang))
                                    .font(BBFonts.mono(10.5))
                                    .foregroundColor(BBColors.textFainter)
                            }
                            Spacer()
                            if unread {
                                Circle().fill(BBColors.vermillion).frame(width: 7, height: 7).padding(.top, 6)
                            }
                        }
                        .opacity(unread ? 1 : 0.62)
                        .padding(.vertical, 15)
                        if index != MOCK_ALERTS.indices.last {
                            Rectangle().fill(BBColors.borderSoft).frame(height: 1)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        state.markRead(n.id)
                        switch n.kind {
                        case "event":
                            if let e = MOCK_EVENTS.first(where: { $0.id == n.ref }) {
                                state.sheet = eventSheetFor(e, state: state)
                            } else {
                                state.go(.events)
                            }
                        case "aarti":
                            state.go(.events)
                        case "bazaar":
                            state.go(.bazaar)
                        default:
                            state.go(.buzz)
                        }
                    }
                }
                Color.clear.frame(height: 110)
            }
            .padding(.horizontal, 18)
        }
    }
}
