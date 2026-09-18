import SwiftUI

/// Palette ported from the Android app's BBColors (Kotlin `ui/theme/Color.kt`) — newsprint
/// cream ground, near-black ink, one vermillion accent, a little temple gold.
enum BBColors {
    static let ink = Color(hex: 0x17150F)
    static let inkOnDark = Color(hex: 0xF6F1E4)

    static let paper = Color(hex: 0xF2EEE4)
    static let card = Color(hex: 0xEDE7D8)

    static let vermillion = Color(hex: 0xB0421B)
    static let vermillionDeep = Color(hex: 0x8C3414)
    static let gold = Color(hex: 0xC7A05C)
    static let goldBright = Color(hex: 0xE8A03A)

    static let textPrimary = Color(hex: 0x17150F)
    static let textBody = Color(hex: 0x3A3527)
    static let textSecondary = Color(hex: 0x5F5844)
    static let textMuted = Color(hex: 0x6E6857)
    static let textFaint = Color(hex: 0x8C7F63)
    static let textFainter = Color(hex: 0xA0947A)
    static let textGhost = Color(hex: 0x7D7359)
    static let textHeading2 = Color(hex: 0x2B2718)

    static let borderSoft = Color(hex: 0x17150F, alpha: 0.14)
    static let borderMed = Color(hex: 0x17150F, alpha: 0.18)
    static let borderStrong = Color(hex: 0x17150F, alpha: 0.22)
    static let borderCard = Color(hex: 0x17150F, alpha: 0.16)

    static let queueLightBg = Color(hex: 0x1F4F4A, alpha: 0.10)
    static let queueLightFg = Color(hex: 0x1F4F4A)
    static let queueLightDot = Color(hex: 0x2F6E66)

    static let queueModerateBg = Color(hex: 0x9A7B2F, alpha: 0.14)
    static let queueModerateFg = Color(hex: 0x7A5F1E)
    static let queueModerateDot = Color(hex: 0x9A7B2F)

    static let queueHeavyBg = Color(hex: 0xB0421B, alpha: 0.12)
    static let queueHeavyFg = Color(hex: 0x8C3414)
    static let queueHeavyDot = Color(hex: 0xB0421B)

    static let alertAartiBg = Color(hex: 0xB0421B, alpha: 0.12)
    static let alertAartiFg = Color(hex: 0x8C3414)
    static let alertNewsBg = Color(hex: 0x17150F, alpha: 0.08)
    static let alertNewsFg = Color(hex: 0x3A3527)
    static let alertEventBg = Color(hex: 0x9A7B2F, alpha: 0.16)
    static let alertEventFg = Color(hex: 0x7A5F1E)
    static let alertBazaarBg = Color(hex: 0x1F4F4A, alpha: 0.10)
    static let alertBazaarFg = Color(hex: 0x1F4F4A)
}

/// Font stand-ins for the design's Newsreader / Archivo / IBM Plex Mono trio — system serif,
/// system default, and system monospaced, matching the Android build's own fallback approach.
enum BBFonts {
    static func headline(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }
    static func body(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .default)
    }
    static func mono(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
}

extension Color {
    init(hex: UInt32, alpha: Double = 1.0) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: alpha)
    }
}
