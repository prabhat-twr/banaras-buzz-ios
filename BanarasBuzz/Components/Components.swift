// Ported from the Android app's ui/components/Header.kt and Components.kt.
import SwiftUI

struct Masthead: View {
    let dateline: String
    let title: String
    let lang: Lang
    let hasUnread: Bool
    let onToggleLang: () -> Void
    let onOpenAlerts: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(dateline)
                        .font(BBFonts.mono(9.5, weight: .semibold))
                        .foregroundColor(BBColors.vermillion)
                        .tracking(0.8)
                    Text(title)
                        .font(BBFonts.headline(25, weight: .bold))
                        .foregroundColor(BBColors.textPrimary)
                }
                Spacer()
                HStack(spacing: 8) {
                    HStack(spacing: 0) {
                        Text("EN")
                            .font(BBFonts.mono(10.5, weight: .semibold))
                            .foregroundColor(lang == .en ? BBColors.inkOnDark : BBColors.textMuted)
                            .padding(.horizontal, 9)
                            .frame(height: 28)
                            .background(lang == .en ? BBColors.ink : .clear)
                        Text("हिं")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(lang == .hi ? BBColors.inkOnDark : BBColors.textMuted)
                            .padding(.horizontal, 9)
                            .frame(height: 28)
                            .background(lang == .hi ? BBColors.ink : .clear)
                    }
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(BBColors.borderStrong, lineWidth: 1))
                    .onTapGesture(perform: onToggleLang)

                    ZStack(alignment: .topTrailing) {
                        Circle()
                            .stroke(BBColors.borderStrong, lineWidth: 1)
                            .frame(width: 28, height: 28)
                            .overlay(BellGlyph(color: BBColors.textHeading2, size: 11))
                        if hasUnread {
                            Circle()
                                .fill(BBColors.vermillion)
                                .frame(width: 7, height: 7)
                                .overlay(Circle().stroke(BBColors.paper, lineWidth: 1.5))
                        }
                    }
                    .onTapGesture(perform: onOpenAlerts)
                }
            }
            Rectangle()
                .fill(BBColors.ink.opacity(0.85))
                .frame(height: 1)
                .padding(.top, 12)
        }
        .padding(.horizontal, 18)
        .background(BBColors.paper)
    }
}

/// The small hand-drawn bell glyph the design uses (three sides only, no bottom stroke).
struct BellGlyph: View {
    let color: Color
    var size: CGFloat = 9

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            let r = size * 0.28
            Path { p in
                p.move(to: CGPoint(x: 0, y: h))
                p.addLine(to: CGPoint(x: 0, y: r))
                p.addQuadCurve(to: CGPoint(x: r, y: 0), control: CGPoint(x: 0, y: 0))
                p.addLine(to: CGPoint(x: w - r, y: 0))
                p.addQuadCurve(to: CGPoint(x: w, y: r), control: CGPoint(x: w, y: 0))
                p.addLine(to: CGPoint(x: w, y: h))
            }
            .stroke(color, style: StrokeStyle(lineWidth: 1.6, lineCap: .round))
        }
        .frame(width: size, height: size)
    }
}

/// A small speech-bubble outline for the Kashi Assistant chat entry point.
struct ChatGlyph: View {
    let color: Color
    var size: CGFloat = 20

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let bodyH = geo.size.height * 0.74
            let r = w * 0.22
            Path { p in
                p.move(to: CGPoint(x: r, y: 0))
                p.addLine(to: CGPoint(x: w - r, y: 0))
                p.addQuadCurve(to: CGPoint(x: w, y: r), control: CGPoint(x: w, y: 0))
                p.addLine(to: CGPoint(x: w, y: bodyH - r))
                p.addQuadCurve(to: CGPoint(x: w - r, y: bodyH), control: CGPoint(x: w, y: bodyH))
                p.addLine(to: CGPoint(x: w * 0.4, y: bodyH))
                p.addLine(to: CGPoint(x: w * 0.24, y: geo.size.height))
                p.addLine(to: CGPoint(x: w * 0.3, y: bodyH))
                p.addLine(to: CGPoint(x: r, y: bodyH))
                p.addQuadCurve(to: CGPoint(x: 0, y: bodyH - r), control: CGPoint(x: 0, y: bodyH))
                p.addLine(to: CGPoint(x: 0, y: r))
                p.addQuadCurve(to: CGPoint(x: r, y: 0), control: CGPoint(x: 0, y: 0))
            }
            .stroke(color, style: StrokeStyle(lineWidth: 1.7, lineCap: .round, lineJoin: .round))
        }
        .frame(width: size, height: size)
    }
}

struct ThumbSlot: View {
    var size: CGFloat
    var body: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(BBColors.card)
            .frame(width: size, height: size)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(BBColors.borderCard, lineWidth: 1))
    }
}

struct PlaceholderSlot: View {
    let label: String
    let height: CGFloat

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 10)
                .fill(BBColors.card)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(BBColors.borderCard, lineWidth: 1))
            Text(label)
                .font(BBFonts.mono(9.5))
                .foregroundColor(BBColors.textGhost)
                .padding(.horizontal, 6)
                .padding(.vertical, 4)
                .background(BBColors.paper.opacity(0.9))
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .padding(10)
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
    }
}

struct PillOption: Identifiable {
    let id = UUID()
    let label: String
    let active: Bool
    let onClick: () -> Void
}

struct PillFilterRow: View {
    let options: [PillOption]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 7) {
                ForEach(options) { opt in
                    Text(opt.label)
                        .font(BBFonts.body(12, weight: .medium))
                        .foregroundColor(opt.active ? BBColors.inkOnDark : BBColors.textBody)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(opt.active ? BBColors.ink : .clear)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(opt.active ? BBColors.ink : BBColors.borderStrong, lineWidth: 1))
                        .onTapGesture(perform: opt.onClick)
                }
            }
        }
    }
}

struct BottomTabBar: View {
    let tabs: [(label: String, active: Bool)]
    let onSelect: (Int) -> Void

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(tabs.enumerated()), id: \.offset) { i, tab in
                VStack(spacing: 7) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(tab.active ? BBColors.vermillion : .clear)
                        .frame(width: 16, height: 2)
                    Text(tab.label)
                        .font(BBFonts.body(11.5, weight: tab.active ? .semibold : .medium))
                        .foregroundColor(tab.active ? BBColors.textPrimary : BBColors.textFaint)
                }
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
                .onTapGesture { onSelect(i) }
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, 11)
        .padding(.bottom, 22)
        .background(BBColors.paper.opacity(0.96))
    }
}

struct ToastHost: View {
    let message: String?

    var body: some View {
        if let message {
            Text(message)
                .font(BBFonts.body(12.5, weight: .medium))
                .foregroundColor(BBColors.inkOnDark)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(BBColors.ink)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
}
