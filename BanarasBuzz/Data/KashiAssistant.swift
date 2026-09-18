// Ported from the Android app's data/KashiAssistant.kt.
//
// "Kashi Assistant" — a small rule-based Q&A helper for the in-app chat sheet. It is NOT a
// hosted LLM: there's no API key to manage, no network call, no cost. It matches simple
// keywords in the user's question against the app's own live state (today's panchang, the
// upcoming vrat/tyohar calendar, live/mock events, and the curated ghat/temple/aarti mock data)
// and returns a short, templated answer in the current UI language.
import Foundation

private let monthAbbrEnAssistant = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]

private func tokenize(_ s: String) -> Set<String> {
    let lowered = s.lowercased()
    let parts = lowered.components(separatedBy: CharacterSet.alphanumerics.inverted)
    return Set(parts.filter { !$0.isEmpty })
}

private func hasAny(_ haystack: String, _ tokens: Set<String>, _ keywords: [String]) -> Bool {
    keywords.contains { kw in kw.contains(" ") ? haystack.contains(kw) : tokens.contains(kw) }
}

private func formatShortDate(_ iso: String, _ lang: Lang) -> String {
    let parts = iso.split(separator: "-")
    guard parts.count == 3, let month = Int(parts[1]), let day = Int(parts[2]) else { return iso }
    let dayStr = lang == .hi ? toHindiDigits(String(day)) : String(day)
    let monthStr = monthAbbrEnAssistant.indices.contains(month - 1) ? monthAbbrEnAssistant[month - 1] : ""
    return "\(dayStr) \(monthStr)"
}

func answerKashiQuestion(
    question: String,
    lang: Lang,
    panchang: PanchangDay?,
    upcomingObservances: [Observance],
    liveEvents: [EventItem],
    now: Date
) -> String {
    let q = question.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
    let tokens = tokenize(question)
    let hi = lang == .hi

    func any(_ keywords: String...) -> Bool { hasAny(q, tokens, keywords) }

    // Small talk first, so it doesn't get swallowed by a broader topic match below.
    if any("hello", "hey", "namaste", "namaskar", "good morning", "good evening") {
        return hi
            ? "नमस्ते! मैं काशी सहायक हूँ। आज का पंचांग, अगली आरती, आने वाले त्योहार, इस सप्ताह के आयोजन या घाट/मंदिर के बारे में पूछें।"
            : "Namaste! I'm the Kashi Assistant. Ask me about today's panchang, the next Ganga Aarti, upcoming festivals, this week's events, or a ghat/temple."
    }
    if any("thanks", "thank you", "shukriya", "dhanyavad", "धन्यवाद", "शुक्रिया") {
        return hi ? "स्वागत है! और कुछ पूछना हो तो बताइए।" : "You're welcome! Ask me anything else about the city."
    }
    if any("help", "what can you do", "who are you", "about") {
        return hi
            ? "मैं इनमें मदद कर सकता हूँ: आज का पंचांग व तिथि, राहु काल, अभिजीत मुहूर्त, अगली गंगा आरती, आने वाले व्रत-त्योहार, इस सप्ताह के आयोजन, घाट व मंदिर की जानकारी, और बाज़ार के विज्ञापन।"
            : "I can help with: today's panchang & tithi, Rahu Kaal, Abhijit Muhurat, the next Ganga Aarti, upcoming vrat/tyohar, this week's events, ghat & temple info, and the local bazaar."
    }

    // Panchang facets, most specific first.
    if any("rahu", "rahukaal", "राहु") {
        let w = panchang?.rahuKaal
        if panchang == nil {
            return hi ? "आज का पंचांग अभी उपलब्ध नहीं है — इवेंट्स टैब में फिर देखें।" : "Today's panchang isn't available right now — check the Events tab shortly."
        } else if let w {
            return hi
                ? "आज राहु काल \(toHindiDigits(w.start)) से \(toHindiDigits(w.end)) तक है — इस अवधि में शुभ कार्य टालें।"
                : "Today's Rahu Kaal is from \(w.start) to \(w.end) — best to avoid starting anything auspicious in that window."
        } else {
            return hi ? "आज राहु काल की जानकारी उपलब्ध नहीं है।" : "Rahu Kaal timing isn't available for today."
        }
    }
    if any("abhijit", "muhurat", "अभिजीत", "मुहूर्त") {
        let w = panchang?.abhijitMuhurat
        if panchang == nil {
            return hi ? "आज का पंचांग अभी उपलब्ध नहीं है।" : "Today's panchang isn't available right now."
        } else if let w {
            return hi
                ? "आज अभिजीत मुहूर्त \(toHindiDigits(w.start)) से \(toHindiDigits(w.end)) तक है — शुभ कार्यों के लिए अच्छा समय।"
                : "Today's Abhijit Muhurat is from \(w.start) to \(w.end) — a good window for starting something important."
        } else {
            return hi ? "आज अभिजीत मुहूर्त की जानकारी उपलब्ध नहीं है।" : "Abhijit Muhurat timing isn't available for today."
        }
    }
    if any("sunrise", "sunset", "surya", "सूर्योदय", "सूर्यास्त") {
        guard let panchang else {
            return hi ? "आज का पंचांग अभी उपलब्ध नहीं है।" : "Today's panchang isn't available right now."
        }
        return hi
            ? "आज वाराणसी में सूर्योदय \(toHindiDigits(panchang.sunrise ?? "—")) और सूर्यास्त \(toHindiDigits(panchang.sunset ?? "—")) पर है।"
            : "In Varanasi today, sunrise is at \(panchang.sunrise ?? "—") and sunset at \(panchang.sunset ?? "—")."
    }
    if any("tithi", "panchang", "nakshatra", "yoga", "karana", "almanac", "तिथि", "पंचांग", "नक्षत्र", "योग", "करण") {
        guard let panchang else {
            return hi
                ? "आज का पंचांग अभी उपलब्ध नहीं है — इवेंट्स टैब में देखें या थोड़ी देर बाद पूछें।"
                : "Today's panchang isn't loaded yet — check the Events tab, or ask again in a moment."
        }
        let tithi = panchang.tithi.map { $0.name }.joined(separator: " → ")
        let nakshatra = panchang.nakshatra.map { $0.name }.joined(separator: " → ")
        let yoga = panchang.yoga.map { $0.name }.joined(separator: " → ")
        return hi
            ? "आज (\(panchang.vara)) तिथि है \(tithi.isEmpty ? "—" : tithi), नक्षत्र \(nakshatra.isEmpty ? "—" : nakshatra), योग \(yoga.isEmpty ? "—" : yoga)। पूरा विवरण इवेंट्स टैब में \"आज का पंचांग\" में देखें।"
            : "Today (\(panchang.vara)) the tithi is \(tithi.isEmpty ? "—" : tithi), nakshatra is \(nakshatra.isEmpty ? "—" : nakshatra), and yoga is \(yoga.isEmpty ? "—" : yoga). Full details are in the Events tab under \"Today's Panchang\"."
    }

    // Aarti timing.
    if any("aarti", "ganga aarti", "आरती", "गंगा आरती") {
        let countdown = countdownToNextAarti(now: now)
        let main = MOCK_AARTIS.first { $0.hot } ?? MOCK_AARTIS.first
        guard let main else {
            return hi ? "अगली गंगा आरती में \(countdown) बचा है।" : "The next Ganga Aarti is in \(countdown)."
        }
        return hi
            ? "अगली गंगा आरती \(main.place.of(.hi)) पर शाम \(toHindiDigits(main.time)) बजे है — \(countdown) बचा है। (\(main.note.of(.hi)))"
            : "The next Ganga Aarti is at \(main.place.of(.en)), \(main.time) — \(countdown) to go. (\(main.note.of(.en)))"
    }

    // Vrat / tyohar / festival calendar.
    if any("vrat", "festival", "tyohar", "ekadashi", "fast", "fasting", "व्रत", "त्योहार", "एकादशी", "पर्व") {
        let today = isoDateString(now)
        let upcoming = upcomingObservances.filter { $0.date >= today }.prefix(3)
        if upcoming.isEmpty {
            return hi
                ? "आने वाले व्रत/त्योहार की जानकारी अभी उपलब्ध नहीं है — इवेंट्स टैब में देखें।"
                : "The upcoming vrat/tyohar list isn't available right now — check the Events tab."
        }
        let lines = upcoming.map { "\($0.name) (\(formatShortDate($0.date, lang)))" }.joined(separator: "; ")
        return hi
            ? "आने वाले व्रत व त्योहार: \(lines)। पूरी सूची इवेंट्स टैब में \"व्रत व त्योहार\" में है।"
            : "Coming up: \(lines). See the full list in the Events tab under \"Vrat & Tyohar\"."
    }

    // Ghats — check for a specific named ghat first, else give a general recommendation.
    if any("ghat", "ghats", "riverfront", "घाट") {
        // Exclude the generic word "ghat" itself from the name match — every entry's name
        // contains it, so matching on it alone would always resolve to the first ghat in the
        // list even for a query with no specific ghat name in it.
        let named = MOCK_GHATS.first { g -> Bool in
            let nameWords = g.name.en.lowercased().split(separator: " ").map(String.init).filter { $0 != "ghat" && !$0.isEmpty }
            return nameWords.contains { tokens.contains($0) }
        }
        if let named {
            return hi
                ? "\(named.name.of(.hi)): \(named.blurb.of(.hi))। भीड़: \(named.crowd.of(.hi)), केंद्र से दूरी: \(named.walk.of(.hi))।"
                : "\(named.name.of(.en)): \(named.blurb.of(.en)). Crowd: \(named.crowd.of(.en)), distance: \(named.walk.of(.en))."
        }
        let top = MOCK_GHATS.prefix(3).map { "\($0.name.of(lang)) (\($0.crowd.of(lang)))" }.joined(separator: "; ")
        return hi
            ? "घाटों में शुरुआत के लिए अच्छे विकल्प: \(top)। किसी घाट का नाम लेकर पूछें, जैसे \"अस्सी घाट के बारे में बताओ\"।"
            : "Good ghats to start with: \(top). Ask about one by name, e.g. \"tell me about Assi Ghat\"."
    }

    // Temples / darshan queues.
    if any("temple", "mandir", "vishwanath", "darshan", "queue", "wait time", "मंदिर", "विश्वनाथ", "दर्शन") {
        // Same fix as ghats: drop generic words that appear in the trigger keywords above (and
        // in most of the temple names) so a plain "how busy are the temples" doesn't spuriously
        // resolve to "Durga Kund Mandir" just because its name contains "mandir".
        let genericWords: Set<String> = ["temple", "mandir", "darshan", "queue"]
        let named = MOCK_TEMPLES.first { t -> Bool in
            let nameWords = t.name.en.lowercased().split(separator: " ").map(String.init).filter { !genericWords.contains($0) && !$0.isEmpty }
            return nameWords.contains { tokens.contains($0) }
        }
        if let named {
            return hi
                ? "\(named.name.of(.hi)): \(named.hours.of(.hi))। भीड़: \(named.queue.of(.hi)), प्रतीक्षा \(named.wait.of(.hi))।"
                : "\(named.name.of(.en)): \(named.hours.of(.en)). Queue: \(named.queue.of(.en)), wait \(named.wait.of(.en))."
        }
        let lines = MOCK_TEMPLES.map { "\($0.name.of(lang)): \($0.queue.of(lang))" }.joined(separator: "; ")
        return hi
            ? "मंदिरों में भीड़ की स्थिति: \(lines)। किसी मंदिर का नाम लेकर पूछें, जैसे \"काशी विश्वनाथ में कितनी भीड़ है\"।"
            : "Current temple queues: \(lines). Ask about one by name, e.g. \"how busy is Kashi Vishwanath\"."
    }

    // Events.
    if any("event", "events", "happening", "concert", "mela", "fair", "program", "आयोजन", "कार्यक्रम", "मेला") {
        let activeEvents = liveEvents.isEmpty ? MOCK_EVENTS : liveEvents
        if activeEvents.isEmpty {
            return hi ? "अभी कोई आयोजन सूचीबद्ध नहीं है।" : "Nothing's listed right now."
        }
        let lines = activeEvents.prefix(3).map { "\($0.title.of(lang)) (\($0.venue.of(lang)), \($0.start))" }.joined(separator: "; ")
        return hi ? "जल्द होने वाले आयोजन: \(lines)। पूरी सूची इवेंट्स टैब में है।" : "Coming up: \(lines). See the full list in the Events tab."
    }

    // Bazaar.
    if any("bazaar", "buy", "sell", "rent", "room", "tutor", "job", "classified", "बाज़ार", "किराया", "नौकरी", "विज्ञापन") {
        return hi
            ? "बाज़ार टैब में स्थानीय विज्ञापन हैं — कमरे, ट्यूटर, नौकरी, वाद्य यंत्र, सेवाएँ। अपना विज्ञापन भी निःशुल्क दे सकते हैं।"
            : "The Bazaar tab has local classifieds — rooms, tutors, jobs, instruments, services. You can post your own ad there for free too."
    }

    return hi
        ? "मुझे ठीक से समझ नहीं आया। आज का पंचांग, अगली गंगा आरती, आने वाले त्योहार, इस सप्ताह के आयोजन, या किसी घाट/मंदिर के बारे में पूछकर देखें।"
        : "I didn't quite catch that. Try asking about today's panchang, the next Ganga Aarti, upcoming festivals, this week's events, or a ghat/temple by name."
}
