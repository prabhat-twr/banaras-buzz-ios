// Ported from the Android app's ui/components/DetailSheet.kt.
import SwiftUI

struct DetailSheetView: View {
    let sheet: SheetContent
    let closeLabel: String
    let onDismiss: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                PlaceholderSlot(label: sheet.image, height: 150)

                HStack(spacing: 8) {
                    Text(sheet.kicker.uppercased())
                        .font(BBFonts.mono(9.5, weight: .semibold))
                        .foregroundColor(BBColors.vermillion)
                        .tracking(0.9)
                    Text(sheet.meta)
                        .font(BBFonts.mono(11))
                        .foregroundColor(BBColors.textFaint)
                }
                .padding(.top, 14)

                Text(sheet.title)
                    .font(BBFonts.headline(25, weight: .semibold))
                    .foregroundColor(BBColors.textPrimary)
                    .padding(.top, 8)
                    .fixedSize(horizontal: false, vertical: true)

                Text(sheet.body1)
                    .font(BBFonts.headline(15, weight: .regular))
                    .foregroundColor(BBColors.textBody)
                    .lineSpacing(6)
                    .padding(.top, 12)
                    .fixedSize(horizontal: false, vertical: true)

                if !sheet.body2.isEmpty {
                    Text(sheet.body2)
                        .font(BBFonts.headline(15, weight: .regular))
                        .foregroundColor(BBColors.textBody)
                        .lineSpacing(6)
                        .padding(.top, 12)
                        .fixedSize(horizontal: false, vertical: true)
                }

                HStack(spacing: 9) {
                    Text(sheet.actionLabel)
                        .font(BBFonts.body(13.5, weight: .medium))
                        .foregroundColor(BBColors.inkOnDark)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(sheet.actionAccent ? BBColors.vermillion : BBColors.ink)
                        .clipShape(Capsule())
                        .onTapGesture(perform: sheet.onAction)

                    Text(closeLabel)
                        .font(BBFonts.body(13.5, weight: .medium))
                        .foregroundColor(BBColors.textHeading2)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 13)
                        .overlay(Capsule().stroke(BBColors.borderStrong, lineWidth: 1))
                        .onTapGesture(perform: onDismiss)
                }
                .padding(.top, 20)

                if let sourceLabel = sheet.sourceLabel, let onOpenSource = sheet.onOpenSource {
                    Text("\(sourceLabel) ↗")
                        .font(BBFonts.mono(12, weight: .medium))
                        .foregroundColor(BBColors.vermillion)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .padding(.top, 16)
                        .onTapGesture(perform: onOpenSource)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 30)
            .padding(.top, 24)
        }
        .background(BBColors.paper)
        .presentationDragIndicator(.visible)
    }
}
