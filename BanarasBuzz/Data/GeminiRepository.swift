// Ported from the Android app's data/GeminiRepository.kt.
import Foundation

private let geminiURL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-latest:generateContent"

/// Optional "real AI" path for the Kashi Assistant chat, used only when a Gemini API key is
/// present in Config/Secrets.swift (gitignored — never hardcoded or committed; see
/// Config/Secrets.example.swift for the template, and .github/workflows/ios-build.yml for how
/// CI generates a harmless empty placeholder so the public repo still builds). Returns nil on
/// any failure (missing key, no network, bad response, timeout) so the caller falls back to the
/// offline rule-based answerKashiQuestion() in KashiAssistant.swift.
func fetchGeminiReply(
    question: String,
    lang: Lang,
    panchang: PanchangDay?,
    upcomingObservances: [Observance],
    liveEvents: [EventItem]
) async -> String? {
    let apiKey = Secrets.geminiAPIKey
    guard !apiKey.isEmpty else { return nil }
    guard let url = URL(string: "\(geminiURL)?key=\(apiKey)") else { return nil }

    let systemPrompt = buildGeminiSystemPrompt(lang: lang, panchang: panchang, upcomingObservances: upcomingObservances, liveEvents: liveEvents)
    let body: [String: Any] = [
        "systemInstruction": ["parts": [["text": systemPrompt]]],
        "contents": [["role": "user", "parts": [["text": question]]]],
        "generationConfig": ["temperature": 0.6, "maxOutputTokens": 300],
    ]
    guard let bodyData = try? JSONSerialization.data(withJSONObject: body) else { return nil }

    var request = URLRequest(url: url, timeoutInterval: 15)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpBody = bodyData

    do {
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else { return nil }
        guard let root = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else { return nil }
        guard let candidates = root["candidates"] as? [[String: Any]], let first = candidates.first else { return nil }
        guard let content = first["content"] as? [String: Any], let parts = content["parts"] as? [[String: Any]] else { return nil }
        let text = parts.compactMap { $0["text"] as? String }.joined().trimmingCharacters(in: .whitespacesAndNewlines)
        return text.isEmpty ? nil : text
    } catch {
        return nil
    }
}

/// Grounds the model in the app's own live data so it doesn't invent timings or facts.
private func buildGeminiSystemPrompt(
    lang: Lang,
    panchang: PanchangDay?,
    upcomingObservances: [Observance],
    liveEvents: [EventItem]
) -> String {
    let langName = lang == .hi ? "Hindi" : "English"
    let panchangLine: String
    if let panchang {
        let tithi = panchang.tithi.map { $0.name }.joined(separator: ", ")
        let nakshatra = panchang.nakshatra.map { $0.name }.joined(separator: ", ")
        let rahu = panchang.rahuKaal.map { "\($0.start)-\($0.end)" } ?? "n/a"
        panchangLine = "Today's panchang: vara=\(panchang.vara), tithi=\(tithi), nakshatra=\(nakshatra), sunrise=\(panchang.sunrise ?? "n/a"), sunset=\(panchang.sunset ?? "n/a"), rahuKaal=\(rahu)."
    } else {
        panchangLine = "Today's panchang is not loaded yet."
    }
    let vratLine: String
    if upcomingObservances.isEmpty {
        vratLine = "No upcoming vrat/tyohar data loaded."
    } else {
        vratLine = "Upcoming vrat/tyohar: " + upcomingObservances.prefix(5).map { "\($0.name) (\($0.date))" }.joined(separator: "; ") + "."
    }
    let eventsSource = liveEvents.isEmpty ? MOCK_EVENTS : liveEvents
    let eventsLine = "Upcoming events: " + eventsSource.prefix(5).map { "\($0.title.of(lang)) at \($0.venue.of(lang)), \($0.start)" }.joined(separator: "; ") + "."
    let aartiLine = "The main Ganga Aarti is every evening at 18:45 at Dashashwamedh Ghat."

    return """
    You are the "Kashi Assistant" inside the Banaras Buzz mobile app, a friendly local guide \
    for Varanasi (Kashi/Banaras), India. Answer briefly (2-4 sentences), warmly, and reply in \
    \(langName) since that's the app's current language. Use the live data below when it's \
    relevant to the question; don't invent specific timings or facts beyond it. If asked about \
    something entirely unrelated to Varanasi or the app, gently redirect back to what you can \
    actually help with.

    \(panchangLine)
    \(vratLine)
    \(eventsLine)
    \(aartiLine)
    """
}
