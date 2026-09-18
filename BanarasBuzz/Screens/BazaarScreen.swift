// Ported from the Android app's ui/screens/BazaarScreen.kt.
import SwiftUI

struct BazaarScreen: View {
    @ObservedObject var state: AppState

    var body: some View {
        let lang = state.lang
        let s = strings(for: lang)
        let postAdMsg = lang == .hi ? "विज्ञापन फ़ॉर्म खुलेगा (प्रोटोटाइप)" : "Post-ad form would open (prototype)"
        let filterTagEn = StringsEN.bazaarFilters[state.bazaarFilterIndex]
        let listings = MOCK_LISTINGS.filter { state.bazaarFilterIndex == 0 || $0.tag == filterTagEn }

        return ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(s.bazaarTitle)
                            .font(BBFonts.headline(30, weight: .semibold))
                            .foregroundColor(BBColors.textPrimary)
                        Text(s.bazaarSub)
                            .font(BBFonts.mono(12.5))
                            .foregroundColor(BBColors.textFaint)
                    }
                    Spacer()
                    Text(s.postAd)
                        .font(BBFonts.body(12, weight: .medium))
                        .foregroundColor(BBColors.inkOnDark)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 9)
                        .background(BBColors.ink)
                        .clipShape(Capsule())
                        .onTapGesture { state.say(postAdMsg) }
                }
                .padding(.top, 18)

                PillFilterRow(options: s.bazaarFilters.enumerated().map { i, label in
                    PillOption(label: label, active: state.bazaarFilterIndex == i) { state.bazaarFilterIndex = i }
                })
                .padding(.top, 18)

                Color.clear.frame(height: 16)

                ForEach(listings) { l in
                    let saved = state.isSaved(l.id)
                    HStack(alignment: .top, spacing: 13) {
                        ThumbSlot(size: 64)
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(alignment: .bottom) {
                                Text(l.category.of(lang).uppercased())
                                    .font(BBFonts.mono(9.5, weight: .semibold))
                                    .foregroundColor(BBColors.vermillion)
                                    .tracking(0.8)
                                Spacer()
                                Text(l.age.of(lang))
                                    .font(BBFonts.mono(10.5))
                                    .foregroundColor(BBColors.textFainter)
                            }
                            Text(l.title.of(lang))
                                .font(BBFonts.headline(16, weight: .semibold))
                                .foregroundColor(BBColors.textPrimary)
                            HStack(alignment: .bottom, spacing: 10) {
                                Text(l.price.of(lang))
                                    .font(BBFonts.mono(14, weight: .semibold))
                                    .foregroundColor(BBColors.textPrimary)
                                Text(l.area.of(lang))
                                    .font(BBFonts.body(11.5))
                                    .foregroundColor(BBColors.textMuted)
                                Spacer()
                                Text(saved ? s.saved : s.save)
                                    .font(BBFonts.mono(11, weight: .medium))
                                    .foregroundColor(saved ? BBColors.vermillion : BBColors.textFaint)
                                    .onTapGesture { state.toggleSaved(l.id) }
                            }
                            .padding(.top, 1)
                        }
                    }
                    .padding(13)
                    .background(BBColors.card)
                    .clipShape(RoundedRectangle(cornerRadius: 11))
                    .overlay(RoundedRectangle(cornerRadius: 11).stroke(BBColors.borderCard, lineWidth: 1))
                    .padding(.bottom, 11)
                }
                Color.clear.frame(height: 110)
            }
            .padding(.horizontal, 18)
        }
    }
}
