import Foundation

private let hiDigits: [Character] = Array("०१२३४५६७८९")

/// Converts any 0-9 Arabic digits inside `s` to Devanagari, for Hindi-mode display of times,
/// day numbers, etc. — ported from the Android app's DateUtils.kt.
func toHindiDigits(_ s: String) -> String {
    String(s.map { c -> Character in
        if let d = c.wholeNumberValue, c.isASCII, c.isNumber { return hiDigits[d] }
        return c
    })
}

let istTimeZone = TimeZone(identifier: "Asia/Kolkata")!

/// Today's date in IST, used to build the Events tab's rolling 7-day strip.
func todayIst() -> Date {
    var cal = Calendar(identifier: .gregorian)
    cal.timeZone = istTimeZone
    let comps = cal.dateComponents([.year, .month, .day], from: Date())
    return cal.date(from: comps) ?? Date()
}

func isoDateString(_ date: Date) -> String {
    let f = DateFormatter()
    f.calendar = Calendar(identifier: .gregorian)
    f.timeZone = istTimeZone
    f.dateFormat = "yyyy-MM-dd"
    return f.string(from: date)
}

/// "H:MM:SS" countdown to the next 18:45 IST (matching the design's live aarti-clock card).
func countdownToNextAarti(now: Date = Date()) -> String {
    var cal = Calendar(identifier: .gregorian)
    cal.timeZone = istTimeZone
    var target = cal.date(bySettingHour: 18, minute: 45, second: 0, of: now) ?? now
    if target.timeIntervalSince(now) <= 0 {
        target = cal.date(byAdding: .day, value: 1, to: target) ?? target
    }
    var seconds = Int(target.timeIntervalSince(now))
    let h = seconds / 3600; seconds -= h * 3600
    let m = seconds / 60; seconds -= m * 60
    return String(format: "%d:%02d:%02d", h, m, seconds)
}
