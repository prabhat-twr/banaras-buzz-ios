// Ported from the Android app's ui/screens/GhatsScreen.kt.
import SwiftUI

private let HI_ORDINAL = ["०१", "०२", "०३", "०४", "०५"]

struct GhatsScreen: View {
    @ObservedObject var state: AppState

    var body: some View {
        let lang = state.lang
        let s = strings(for: lang)

        return ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                Text(s.ghatsTitle)
                    .font(BBFonts.headline(30, weight: .semibold))
                    .foregroundColor(BBColors.textPrimary)
                    .padding(.top, 18)
                Text(s.ghatsSub)
                    .font(BBFonts.mono(12.5))
                    .foregroundColor(BBColors.textFaint)
                    .padding(.top, 8)

                PlaceholderSlot(label: s.mapSlot, height: 132)
                    .padding(.top, 16)

                ForEach(Array(MOCK_GHATS.enumerated()), id: \.element.id) { index, g in
                    VStack(spacing: 0) {
                        HStack(alignment: .center) {
                            Text(lang == .hi ? HI_ORDINAL[index] : String(format: "%02d", index + 1))
                                .font(BBFonts.mono(11, weight: .medium))
                                .foregroundColor(BBColors.textFainter)
                                .frame(width: 20, alignment: .leading)
                            VStack(alignment: .leading, spacing: 5) {
                                Text(g.name.of(lang))
                                    .font(BBFonts.headline(17, weight: .semibold))
                                    .foregroundColor(BBColors.textPrimary)
                                Text(g.blurb.of(lang))
                                    .font(BBFonts.body(12.5))
                                    .foregroundColor(BBColors.textMuted)
                            }
                            .padding(.leading, 13)
                            Spacer()
                            VStack(alignment: .trailing, spacing: 6) {
                                Text(g.walk.of(lang))
                                    .font(BBFonts.mono(11, weight: .medium))
                                    .foregroundColor(BBColors.textPrimary)
                                Text(g.crowd.of(lang))
                                    .font(BBFonts.mono(10))
                                    .foregroundColor(BBColors.textFainter)
                            }
                        }
                        .padding(.vertical, 16)
                        if index != MOCK_GHATS.indices.last {
                            Rectangle().fill(BBColors.borderSoft).frame(height: 1)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { state.sheet = ghatSheetFor(g, state: state) }
                }
                Color.clear.frame(height: 110)
            }
            .padding(.horizontal, 18)
        }
    }
}
