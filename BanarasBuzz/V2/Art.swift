// The illustrated Banaras riverfront used for banners and tiles (same artwork as Android's Art.kt).
import SwiftUI

enum SceneMood { case dawn, dusk, night }

private struct ScenePalette {
    let sky: [Color]
    let sun: Color
    let far: Color
    let near: Color
    let water: [Color]
    let glow: Color
    let lamps: Bool
    let sunY: CGFloat
}

private func palette(_ m: SceneMood) -> ScenePalette {
    switch m {
    case .dawn:
        return ScenePalette(sky: [Color(hex: 0x6E5A9E), Color(hex: 0xE77A63), Color(hex: 0xF7B267), Color(hex: 0xFCD9A0)],
                            sun: Color(hex: 0xFFE08A), far: Color(hex: 0x8A4B3A), near: Color(hex: 0x5B2E24),
                            water: [Color(hex: 0xE59A6A), Color(hex: 0x7D4E5C)], glow: Color(hex: 0xFFD27A), lamps: false, sunY: 0.55)
    case .dusk:
        return ScenePalette(sky: [Color(hex: 0x3E3B73), Color(hex: 0xC0546A), Color(hex: 0xF08A4B), Color(hex: 0xF9C46B)],
                            sun: Color(hex: 0xFFC857), far: Color(hex: 0x6B3226), near: Color(hex: 0x3D1C17),
                            water: [Color(hex: 0xD9774A), Color(hex: 0x4B2A3D)], glow: Color(hex: 0xFFB347), lamps: true, sunY: 0.55)
    case .night:
        return ScenePalette(sky: [Color(hex: 0x0E1630), Color(hex: 0x1F2752), Color(hex: 0x4A3260), Color(hex: 0x8C4A3C)],
                            sun: Color(hex: 0xFFF3C4), far: Color(hex: 0x9C5A22), near: Color(hex: 0x3A2015),
                            water: [Color(hex: 0x3A2A3E), Color(hex: 0x0E1226)], glow: Color(hex: 0xFFB13B), lamps: true, sunY: 0.25)
    }
}

private let buildings: [(CGFloat, CGFloat, CGFloat)] = [
    (0.00, 0.07, 0.10), (0.06, 0.05, 0.14), (0.13, 0.06, 0.09), (0.27, 0.05, 0.12), (0.33, 0.06, 0.08), (0.47, 0.05, 0.13),
    (0.53, 0.07, 0.10), (0.70, 0.06, 0.11), (0.77, 0.05, 0.15), (0.83, 0.07, 0.09), (0.92, 0.08, 0.12),
]
private let spires: [(CGFloat, CGFloat, CGFloat)] = [(0.22, 0.07, 0.30), (0.41, 0.10, 0.42), (0.64, 0.08, 0.34), (0.88, 0.05, 0.22)]

struct BanarasScene: View {
    let mood: SceneMood

    var body: some View {
        Canvas { ctx, size in
            let p = palette(mood)
            let w = size.width, h = size.height
            let horizon = h * 0.66
            ctx.fill(Path(CGRect(x: 0, y: 0, width: w, height: horizon + 1)),
                     with: .linearGradient(Gradient(colors: p.sky), startPoint: .zero, endPoint: CGPoint(x: 0, y: horizon)))

            let sun = CGPoint(x: w * 0.78, y: horizon * p.sunY)
            let r = min(w, h) * 0.09
            ctx.fill(Path(ellipseIn: CGRect(x: sun.x - r * 3.2, y: sun.y - r * 3.2, width: r * 6.4, height: r * 6.4)),
                     with: .radialGradient(Gradient(colors: [p.sun.opacity(0.55), p.sun.opacity(0)]), center: sun, startRadius: 0, endRadius: r * 3.2))
            ctx.fill(Path(ellipseIn: CGRect(x: sun.x - r, y: sun.y - r, width: r * 2, height: r * 2)), with: .color(p.sun))

            for (x, bw, bh) in buildings {
                ctx.fill(Path(CGRect(x: x * w, y: horizon - bh * h, width: bw * w + 1, height: bh * h)), with: .color(p.far))
            }
            for (cx0, sw, sh) in spires {
                let cx = cx0 * w, half = sw * w / 2, ht = sh * h, top = horizon - ht, sww = sw * w
                var spire = Path()
                spire.move(to: CGPoint(x: cx - half, y: horizon))
                spire.addCurve(to: CGPoint(x: cx, y: top),
                               control1: CGPoint(x: cx - half * 1.05, y: horizon - ht * 0.55),
                               control2: CGPoint(x: cx - half * 0.35, y: horizon - ht * 0.85))
                spire.addCurve(to: CGPoint(x: cx + half, y: horizon),
                               control1: CGPoint(x: cx + half * 0.35, y: horizon - ht * 0.85),
                               control2: CGPoint(x: cx + half * 1.05, y: horizon - ht * 0.55))
                spire.closeSubpath()
                ctx.fill(spire, with: .color(p.far))
                let k = sww * 0.07
                ctx.fill(Path(ellipseIn: CGRect(x: cx - k, y: top - sww * 0.05 - k, width: k * 2, height: k * 2)), with: .color(p.far))
                var pole = Path()
                pole.move(to: CGPoint(x: cx, y: top)); pole.addLine(to: CGPoint(x: cx, y: top - sww * 0.45))
                ctx.stroke(pole, with: .color(p.far), lineWidth: max(1, sww * 0.03))
                var flag = Path()
                flag.move(to: CGPoint(x: cx, y: top - sww * 0.45))
                flag.addLine(to: CGPoint(x: cx + sww * 0.28, y: top - sww * 0.36))
                flag.addLine(to: CGPoint(x: cx, y: top - sww * 0.27))
                flag.closeSubpath()
                ctx.fill(flag, with: .color(Color(hex: 0xFF7A1A)))
            }
            if p.lamps {
                var x = w * 0.03
                let lr = max(1, h * 0.008)
                while x < w {
                    ctx.fill(Path(ellipseIn: CGRect(x: x - lr, y: horizon - h * 0.035 - lr, width: lr * 2, height: lr * 2)), with: .color(p.glow))
                    x += w * 0.045
                }
            }
            let step = h * 0.018
            for i in 0..<3 {
                ctx.fill(Path(CGRect(x: 0, y: horizon + CGFloat(i) * step, width: w, height: step * 0.7)),
                         with: .color(p.near.opacity(0.85 - Double(i) * 0.15)))
            }
            let river = horizon + 3 * step
            ctx.fill(Path(CGRect(x: 0, y: river, width: w, height: h - river)),
                     with: .linearGradient(Gradient(colors: p.water), startPoint: CGPoint(x: 0, y: river), endPoint: CGPoint(x: 0, y: h)))
            var y = river + h * 0.03
            var k = 0
            while y < h {
                let len = w * max(0.03, 0.10 - CGFloat(k) * 0.008)
                var line = Path()
                line.move(to: CGPoint(x: sun.x - len / 2, y: y)); line.addLine(to: CGPoint(x: sun.x + len / 2, y: y))
                ctx.stroke(line, with: .color(p.glow.opacity(0.55)), lineWidth: max(1, h * 0.008))
                y += h * 0.035; k += 1
            }
            func boat(_ c: GraphicsContext, _ x: CGFloat, _ by: CGFloat, _ bw: CGFloat) {
                var b = Path()
                b.move(to: CGPoint(x: x, y: by))
                b.addQuadCurve(to: CGPoint(x: x + bw, y: by), control: CGPoint(x: x + bw / 2, y: by + bw * 0.22))
                b.addLine(to: CGPoint(x: x + bw * 0.85, y: by + bw * 0.06))
                b.addLine(to: CGPoint(x: x + bw * 0.15, y: by + bw * 0.06))
                b.closeSubpath()
                c.fill(b, with: .color(p.near))
            }
            boat(ctx, w * 0.12, river + h * 0.12, w * 0.16)
            boat(ctx, w * 0.42, river + h * 0.2, w * 0.12)
        }
        .accessibilityHidden(true)
    }
}

/// A warm gradient tile with a big emoji, used where there is no photo.
struct EmojiArt: View {
    let emoji: String
    let colors: [Color]
    var size: CGFloat = 38
    var body: some View {
        ZStack {
            LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
            Text(emoji).font(.system(size: size))
        }
    }
}

/// A news photo, or the riverfront illustration when there is none or it fails to load.
struct PhotoOrScene: View {
    let url: String?
    let mood: SceneMood
    var body: some View {
        if let s = url, let u = URL(string: s) {
            AsyncImage(url: u) { phase in
                if let image = phase.image {
                    image.resizable().scaledToFill()
                } else {
                    BanarasScene(mood: mood)
                }
            }
        } else {
            BanarasScene(mood: mood)
        }
    }
}

func greetingNow() -> (String, SceneMood) {
    let h = pkCalendar.component(.hour, from: Date())
    switch h {
    case 4..<12: return ("शुभ प्रभात, बनारस!", .dawn)
    case 12..<17: return ("नमस्ते, बनारस!", .dusk)
    case 17..<21: return ("शुभ संध्या, बनारस!", .dusk)
    default: return ("शुभ रात्रि, बनारस!", .night)
    }
}
