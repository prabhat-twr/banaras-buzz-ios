// Ported from the Android app's ui/screens/ChatScreen.kt.
//
// "Kashi Assistant" chat sheet — a lightweight rule-based Q&A helper (see
// Data/KashiAssistant.swift), reached from a floating button over every tab. It answers from
// the app's own live data (panchang, vrat/tyohar calendar, events, ghats, temples) rather than
// calling a hosted LLM, so there's no API key or network cost involved.
import SwiftUI

struct KashiChatSheet: View {
    @ObservedObject var state: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var input: String = ""

    var body: some View {
        let lang = state.lang

        VStack(spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(lang == .hi ? "काशी सहायक" : "KASHI ASSISTANT")
                        .font(BBFonts.mono(9.5, weight: .semibold))
                        .foregroundColor(BBColors.vermillion)
                        .tracking(0.8)
                    Text(lang == .hi ? "पंचांग, आरती, त्योहार व घाट के बारे में पूछें" : "Ask about panchang, aarti, festivals & ghats")
                        .font(BBFonts.headline(17, weight: .semibold))
                        .foregroundColor(BBColors.textPrimary)
                }
                Spacer()
                Button(action: { dismiss() }) {
                    Text("\u{2715}")
                        .font(.system(size: 13))
                        .foregroundColor(BBColors.textHeading2)
                        .frame(width: 30, height: 30)
                        .overlay(Circle().stroke(BBColors.borderStrong, lineWidth: 1))
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)

            Rectangle()
                .fill(BBColors.borderSoft)
                .frame(height: 1)
                .padding(.top, 12)

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 10) {
                        if state.chatMessages.isEmpty {
                            ChatSuggestions(lang: lang) { send($0) }
                        }
                        ForEach(state.chatMessages) { msg in
                            ChatBubble(message: msg).id(msg.id)
                        }
                        if state.chatThinking {
                            TypingBubble(lang: lang).id("typing")
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 14)
                }
                .onChange(of: state.chatMessages.count) { _ in scrollToBottom(proxy) }
                .onChange(of: state.chatThinking) { _ in scrollToBottom(proxy) }
            }

            HStack(spacing: 8) {
                TextField(lang == .hi ? "अपना सवाल लिखें…" : "Ask a question…", text: $input)
                    .font(BBFonts.body(13.5))
                    .padding(.horizontal, 14)
                    .frame(height: 42)
                    .background(BBColors.card)
                    .clipShape(Capsule())
                    .submitLabel(.send)
                    .onSubmit { send(input) }

                Button(action: { send(input) }) {
                    SendGlyph(color: BBColors.inkOnDark)
                        .frame(width: 15, height: 15)
                        .frame(width: 42, height: 42)
                        .background(input.trimmingCharacters(in: .whitespaces).isEmpty ? BBColors.borderStrong : BBColors.vermillion)
                        .clipShape(Circle())
                }
                .disabled(input.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(BBColors.paper)
        }
        .background(BBColors.paper)
    }

    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        withAnimation {
            if state.chatThinking {
                proxy.scrollTo("typing", anchor: .bottom)
            } else if let last = state.chatMessages.last {
                proxy.scrollTo(last.id, anchor: .bottom)
            }
        }
    }

    private func send(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !state.chatThinking else { return }
        state.chatMessages.append(ChatMessage(id: UUID().uuidString, role: .user, text: trimmed))
        input = ""
        state.chatThinking = true
        let lang = state.lang
        let panchang = state.panchang
        let observances = state.upcomingObservances
        let events = state.liveEvents
        let now = state.nowMillis
        Task {
            // Try the real AI first (only active when a Gemini key is set in
            // Config/Secrets.swift — see Data/GeminiRepository.swift); fall back to the
            // instant offline rule-based assistant on any failure (no key, no network, bad
            // response).
            let aiReply = await fetchGeminiReply(
                question: trimmed,
                lang: lang,
                panchang: panchang,
                upcomingObservances: observances,
                liveEvents: events
            )
            let reply: String
            if let aiReply {
                reply = aiReply
            } else {
                try? await Task.sleep(nanoseconds: 300_000_000)
                reply = answerKashiQuestion(
                    question: trimmed,
                    lang: lang,
                    panchang: panchang,
                    upcomingObservances: observances,
                    liveEvents: events,
                    now: now
                )
            }
            state.chatMessages.append(ChatMessage(id: UUID().uuidString, role: .bot, text: reply))
            state.chatThinking = false
        }
    }
}

/// Chat-bubble corner treatment (a small "tail" corner on the side closest to its sender),
/// using SwiftUI's built-in uneven-corner shape rather than a hand-rolled Path.
private func bubbleShape(isUser: Bool) -> UnevenRoundedRectangle {
    UnevenRoundedRectangle(
        topLeadingRadius: 14,
        bottomLeadingRadius: isUser ? 14 : 3,
        bottomTrailingRadius: isUser ? 3 : 14,
        topTrailingRadius: 14
    )
}

private struct ChatBubble: View {
    let message: ChatMessage

    var body: some View {
        let isUser = message.role == .user
        HStack {
            if isUser { Spacer(minLength: 40) }
            Text(message.text)
                .font(BBFonts.body(13.5))
                .lineSpacing(4)
                .foregroundColor(isUser ? BBColors.inkOnDark : BBColors.textPrimary)
                .padding(.horizontal, 13)
                .padding(.vertical, 10)
                .background(isUser ? BBColors.ink : BBColors.card)
                .clipShape(bubbleShape(isUser: isUser))
            if !isUser { Spacer(minLength: 40) }
        }
        .frame(maxWidth: .infinity, alignment: isUser ? .trailing : .leading)
    }
}

private struct TypingBubble: View {
    let lang: Lang

    var body: some View {
        HStack {
            Text(lang == .hi ? "लिख रहा है…" : "typing…")
                .font(BBFonts.body(13))
                .foregroundColor(BBColors.textFaint)
                .padding(.horizontal, 13)
                .padding(.vertical, 10)
                .background(BBColors.card)
                .clipShape(bubbleShape(isUser: false))
            Spacer(minLength: 40)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct ChatSuggestions: View {
    let lang: Lang
    let onPick: (String) -> Void

    var body: some View {
        let prompts = lang == .hi
            ? ["आज का पंचांग", "अगली गंगा आरती", "आने वाले त्योहार", "सबसे अच्छा घाट कौन सा है"]
            : ["Today's panchang", "Next Ganga Aarti", "Upcoming festivals", "Best ghat to visit"]

        VStack(alignment: .leading, spacing: 10) {
            Text(lang == .hi ? "नमस्ते! मैं काशी सहायक हूँ। कुछ भी पूछें:" : "Namaste! I'm the Kashi Assistant. Try asking:")
                .font(BBFonts.headline(15))
                .foregroundColor(BBColors.textBody)
                .lineSpacing(4)
            ForEach(prompts, id: \.self) { p in
                Text(p)
                    .font(BBFonts.body(13, weight: .medium))
                    .foregroundColor(BBColors.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(BBColors.card)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(BBColors.borderCard, lineWidth: 1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .onTapGesture { onPick(p) }
            }
        }
    }
}

private struct SendGlyph: View {
    let color: Color

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            Path { p in
                p.move(to: CGPoint(x: 0, y: 0))
                p.addLine(to: CGPoint(x: w, y: h / 2))
                p.addLine(to: CGPoint(x: 0, y: h))
                p.addLine(to: CGPoint(x: w * 0.28, y: h / 2))
                p.closeSubpath()
            }
            .fill(color)
        }
    }
}
