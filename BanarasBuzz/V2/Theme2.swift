// Saffron-and-cream look shared with the Android app (Theme.kt).
import SwiftUI

enum BZ {
    static let saffron = Color(hex: 0xF26A1B)
    static let saffronDeep = Color(hex: 0xD4520C)
    static let gold = Color(hex: 0xF6B341)
    static let cream = Color(hex: 0xFFF8EF)
    static let tile = Color(hex: 0xFFEFD9)
    static let tileStrong = Color(hex: 0xFFE3BF)
    static let panchangTile = Color(hex: 0xFFF1DC)
    static let panchangGold = Color(hex: 0xFCE3B5)
    static let card = Color.white
    static let ink = Color(hex: 0x2B1A0F)
    static let inkSoft = Color(hex: 0x4A3526)
    static let muted = Color(hex: 0x8A7563)
    static let line = Color(hex: 0xF1E3D0)
    static let heart = Color(hex: 0xE5383B)
    static let rahu = Color(hex: 0xB3261E)
}

extension View {
    /// White rounded card with a soft warm shadow.
    func warmCard(radius: CGFloat = 18) -> some View {
        background(BZ.card)
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .shadow(color: BZ.saffron.opacity(0.14), radius: 8, x: 0, y: 4)
    }
}

/// Underlined text tabs ("Top Stories | Local | Breaking").
struct UnderlineTabs: View {
    let labels: [String]
    @Binding var selected: Int

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(Array(labels.enumerated()), id: \.offset) { i, label in
                        Button { selected = i } label: {
                            VStack(spacing: 6) {
                                Text(label)
                                    .font(.system(size: 15, weight: i == selected ? .bold : .medium))
                                    .foregroundColor(i == selected ? BZ.saffron : BZ.inkSoft)
                                Capsule().fill(i == selected ? BZ.saffron : .clear).frame(width: 36, height: 3)
                            }
                            .padding(.horizontal, 10)
                            .padding(.top, 8)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 12)
            }
            Rectangle().fill(BZ.line).frame(height: 1)
        }
    }
}

/// Pill chips ("All | Food | Shopping").
struct PillChips: View {
    let labels: [String]
    @Binding var selected: Int

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(labels.enumerated()), id: \.offset) { i, label in
                    Button { selected = i } label: {
                        Text(label)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(i == selected ? .white : BZ.ink)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(i == selected ? BZ.saffron : BZ.tile)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
        }
    }
}

/// Title row for inner screens: optional back button, title, trailing content.
struct ScreenHeader<Trailing: View>: View {
    let title: String
    var onBack: (() -> Void)? = nil
    @ViewBuilder var trailing: () -> Trailing

    var body: some View {
        HStack(spacing: 6) {
            if let onBack {
                Button(action: onBack) {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 19, weight: .semibold))
                        .foregroundColor(BZ.ink)
                        .frame(width: 40, height: 40)
                }
                .accessibilityLabel("वापस")
            }
            Text(title)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(BZ.ink)
                .lineLimit(1)
            Spacer(minLength: 0)
            trailing()
        }
        .padding(.leading, onBack == nil ? 20 : 6)
        .padding(.trailing, 12)
        .padding(.vertical, 6)
    }
}

extension ScreenHeader where Trailing == EmptyView {
    init(title: String, onBack: (() -> Void)? = nil) {
        self.init(title: title, onBack: onBack, trailing: { EmptyView() })
    }
}

struct SectionTitle: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.system(size: 18, weight: .bold))
            .foregroundColor(BZ.ink)
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
    }
}

struct EmptyNote: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.system(size: 15))
            .foregroundColor(BZ.muted)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(28)
    }
}

/// "View Details →" outline button.
struct OutlineAction: View {
    let label: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text("\(label)  →")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(BZ.saffron)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(BZ.saffron, lineWidth: 1.2))
        }
        .buttonStyle(.plain)
    }
}

/// Day box used in festival lists: big day number over a small label.
struct DateBox: View {
    let key: String
    var label: String? = nil
    var body: some View {
        VStack(spacing: 0) {
            Text("\(pkDayOfMonth(key))").font(.system(size: 20, weight: .heavy)).foregroundColor(BZ.saffron)
            Text(label ?? pkMonthHi(key)).font(.system(size: 11)).foregroundColor(BZ.inkSoft)
        }
        .frame(width: 58)
        .padding(.vertical, 8)
        .background(BZ.tile)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
