// Ported from the Android app's ui/screens/BuzzScreen.kt.
import SwiftUI

struct BuzzScreen: View {
    @ObservedObject var state: AppState

    var body: some View {
        let lang = state.lang
        let readFull = lang == .hi ? "पूरी खबर पढ़ें" : "Read full story"
        let visible = state.articles.filter { state.feedCityFilter == ALL_CITIES || $0.cityId == state.feedCityFilter }
        let lead = visible.first(where: { $0.isBreaking }) ?? visible.first
        let rest = visible.filter { $0.id != lead?.id }

        func openArticle(_ article: NewsArticle) {
            state.sheet = SheetContent(
                image: article.title, kicker: article.cityName, meta: relativeTime(for: article, lang: lang),
                title: article.title, body1: article.content.isEmpty ? article.summary : article.content,
                body2: article.content != article.summary ? article.summary : "",
                actionLabel: readFull, imageUrl: article.imageUrl
            ) {
                if let src = article.sourceUrl {
                    state.sourcePage = SourcePage(url: src, title: article.sourceName ?? article.title)
                }
                state.sheet = nil
            }
        }

        return ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                // Next Ganga Aarti card.
                HStack(spacing: 14) {
                    AartiFlame()
                        .frame(width: 22, height: 34, alignment: .bottom)
                    VStack(alignment: .leading, spacing: 6) {
                        Text(lang == .hi ? "अगली गंगा आरती" : "Next Ganga Aarti")
                            .font(BBFonts.mono(9.5, weight: .semibold))
                            .foregroundColor(BBColors.gold)
                            .tracking(0.9)
                        Text(MOCK_AARTIS[0].place.of(lang))
                            .font(BBFonts.headline(16.5, weight: .medium))
                            .foregroundColor(BBColors.inkOnDark)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 5) {
                        TimelineView(.periodic(from: .now, by: 1)) { context in
                            Text(countdownToNextAarti(now: context.date))
                                .font(BBFonts.mono(19, weight: .semibold))
                                .foregroundColor(BBColors.inkOnDark)
                        }
                        Text(MOCK_AARTIS[0].time)
                            .font(BBFonts.mono(10.5))
                            .foregroundColor(BBColors.inkOnDark.opacity(0.65))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(BBColors.ink)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(BBColors.borderCard, lineWidth: 1))
                .padding(.top, 16)

                PillFilterRow(options: CITY_LABELS.map { id, bi in
                    PillOption(label: bi.of(lang), active: state.feedCityFilter == id) { state.feedCityFilter = id }
                })
                .padding(.top, 16)

                if state.articlesLoading && state.articles.isEmpty {
                    HStack { Spacer(); ProgressView().tint(BBColors.ink); Spacer() }
                        .padding(.vertical, 48)
                } else if lead == nil {
                    Text(lang == .hi ? "अभी कोई खबर उपलब्ध नहीं है।" : "No news available right now.")
                        .font(BBFonts.body(14))
                        .foregroundColor(BBColors.textFaint)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                        .padding(.vertical, 48)
                } else if let lead {
                    VStack(alignment: .leading, spacing: 0) {
                        PlaceholderSlot(label: lead.title, height: 172)
                        HStack {
                            Text(lead.cityName.uppercased())
                                .font(BBFonts.mono(9.5, weight: .semibold))
                                .foregroundColor(BBColors.vermillion)
                                .tracking(0.9)
                            Text(" · \(relativeTime(for: lead, lang: lang))")
                                .font(BBFonts.mono(11))
                                .foregroundColor(BBColors.textFaint)
                        }
                        .padding(.top, 12)
                        Text(lead.title)
                            .font(BBFonts.headline(26, weight: .semibold))
                            .foregroundColor(BBColors.textPrimary)
                            .padding(.top, 7)
                        Text(lead.summary)
                            .font(BBFonts.body(14))
                            .foregroundColor(BBColors.textSecondary)
                            .lineLimit(3)
                            .padding(.top, 8)
                    }
                    .padding(.top, 18)
                    .contentShape(Rectangle())
                    .onTapGesture { openArticle(lead) }

                    Rectangle().fill(BBColors.borderSoft).frame(height: 1).padding(.vertical, 20)

                    ForEach(Array(rest.enumerated()), id: \.element.id) { index, article in
                        VStack(alignment: .leading, spacing: 0) {
                            HStack(alignment: .top, spacing: 14) {
                                VStack(alignment: .leading, spacing: 0) {
                                    HStack(spacing: 8) {
                                        Text(article.cityName.uppercased())
                                            .font(BBFonts.mono(9.5, weight: .semibold))
                                            .foregroundColor(BBColors.vermillion)
                                            .tracking(0.9)
                                        Text(relativeTime(for: article, lang: lang))
                                            .font(BBFonts.mono(11))
                                            .foregroundColor(BBColors.textFaint)
                                    }
                                    Text(article.title)
                                        .font(BBFonts.headline(18, weight: .semibold))
                                        .foregroundColor(BBColors.textPrimary)
                                        .padding(.top, 7)
                                    Text(article.summary)
                                        .font(BBFonts.body(13))
                                        .foregroundColor(BBColors.textMuted)
                                        .lineLimit(3)
                                        .padding(.top, 6)
                                }
                                PlaceholderSlot(label: article.title, height: 84).frame(width: 84)
                            }
                            .padding(.vertical, 16)
                            if index != rest.indices.last {
                                Rectangle().fill(BBColors.borderSoft).frame(height: 1)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture { openArticle(article) }
                    }
                    Color.clear.frame(height: 110)
                }
            }
            .padding(.horizontal, 18)
        }
    }
}

/// The pulsing lamp-flame glyph on the "next aarti" card.
struct AartiFlame: View {
    @State private var animate = false
    var body: some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(LinearGradient(colors: [BBColors.goldBright, BBColors.vermillion], startPoint: .top, endPoint: .bottom))
            .frame(width: 12, height: 26)
            .scaleEffect(x: 1, y: animate ? 1.06 : 0.92)
            .opacity(animate ? 1 : 0.55)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) { animate = true }
            }
    }
}
