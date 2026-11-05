// Rahu Kaal and Shubh Muhurat alerts as local notifications (Android: Alerts.kt).
//
// iOS can't keep a notification pinned, so the "always visible" part is the lock-screen and
// home-screen widget (BanarasBuzzWidget). These alerts are scheduled ahead of time, so they
// fire on time even when the app isn't running.
import SwiftUI
import UserNotifications
import WidgetKit

enum PanchangAlerts {
    static let earlyMinutes = 10.0
    private static let idPrefix = "pk-alert-"
    private static let horizonDays = 14

    static var rahu: Bool {
        get { UserDefaults.standard.bool(forKey: "alert.rahu") }
        set { UserDefaults.standard.set(newValue, forKey: "alert.rahu") }
    }
    static var shubh: Bool {
        get { UserDefaults.standard.bool(forKey: "alert.shubh") }
        set { UserDefaults.standard.set(newValue, forKey: "alert.shubh") }
    }
    static var early: Bool {
        get { UserDefaults.standard.object(forKey: "alert.early") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "alert.early") }
    }
    static var anyEnabled: Bool { rahu || shubh }

    /// Asks for permission the first time; completes with whether notifications are allowed.
    static func requestPermission(_ done: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async { done(granted) }
        }
    }

    /// Replaces all pending panchang alerts with ones for the next two weeks (iOS allows 64).
    static func reschedule(store: BuzzStore?) {
        let center = UNUserNotificationCenter.current()
        // Gather everything on the calling (main) thread before going async.
        let today = pkTodayKey()
        var plans: [(id: String, at: Date, title: String, body: String)] = []
        let now = Date()
        if anyEnabled {
            for i in 0..<horizonDays {
                let key = pkAddDays(today, i)
                let w = pkWindows(key, day: store?.panchang(for: key))
                if rahu {
                    let range = w.rahu.range
                    plans.append(("\(idPrefix)rahu-\(key)", w.rahu.start, "राहुकाल शुरू — सावधान रहें", "\(range) • नए और शुभ काम अभी शुरू न करें"))
                    if early {
                        plans.append(("\(idPrefix)rahu-early-\(key)", w.rahu.start.addingTimeInterval(-earlyMinutes * 60),
                                      "राहुकाल 10 मिनट में", "\(range) • नए काम की शुरुआत टालें"))
                    }
                }
                if shubh && pkShubhObserved(key) {
                    let range = w.abhijit.range
                    plans.append(("\(idPrefix)shubh-\(key)", w.abhijit.start, "शुभ मुहूर्त शुरू ✨", "अभिजित मुहूर्त \(range) • शुभ काम के लिए अच्छा समय"))
                    if early {
                        plans.append(("\(idPrefix)shubh-early-\(key)", w.abhijit.start.addingTimeInterval(-earlyMinutes * 60),
                                      "शुभ मुहूर्त 10 मिनट में", "अभिजित मुहूर्त \(range)"))
                    }
                }
            }
        }
        let upcoming = plans.filter { $0.at > now }.sorted { $0.at < $1.at }.prefix(60)

        center.getPendingNotificationRequests { pending in
            let old = pending.map(\.identifier).filter { $0.hasPrefix(idPrefix) }
            center.removePendingNotificationRequests(withIdentifiers: old)
            for p in upcoming {
                let content = UNMutableNotificationContent()
                content.title = p.title
                content.body = p.body
                content.sound = .default
                content.threadIdentifier = "panchang"
                content.userInfo = ["route": "panchang"]
                let comps = pkCalendar.dateComponents(in: pkIST, from: p.at)
                let trigger = UNCalendarNotificationTrigger(
                    dateMatching: DateComponents(timeZone: pkIST, year: comps.year, month: comps.month, day: comps.day,
                                                 hour: comps.hour, minute: comps.minute),
                    repeats: false)
                center.add(UNNotificationRequest(identifier: p.id, content: content, trigger: trigger))
            }
        }
        // Widgets show the same windows; let them pick up fresh data too.
        WidgetCenter.shared.reloadAllTimelines()
    }
}

/// Shows alerts while the app is open, and opens the Panchang screen when one is tapped.
final class NotificationRouter: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationRouter()
    var openPanchang: (() -> Void)?

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .list])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        DispatchQueue.main.async { self.openPanchang?() }
        completionHandler()
    }
}

struct AlertSettingsSheet: View {
    @ObservedObject var store: BuzzStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @State private var rahu = PanchangAlerts.rahu
    @State private var shubh = PanchangAlerts.shubh
    @State private var early = PanchangAlerts.early
    @State private var denied = false

    var body: some View {
        let today = pkTodayKey()
        let w = pkWindows(today, day: store.panchang(for: today))
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text("शुरू होने पर सूचना (आवाज़ के साथ)").font(.system(size: 13, weight: .semibold)).foregroundColor(BZ.muted)
                    AlertToggle(emoji: "🌑", title: "राहुकाल अलर्ट", subtitle: "आज \(w.rahu.range)", isOn: $rahu)
                    AlertToggle(emoji: "✨", title: "शुभ मुहूर्त (अभिजित) अलर्ट",
                                subtitle: pkShubhObserved(today) ? "आज \(w.abhijit.range)" : "बुधवार को अभिजित मुहूर्त नहीं माना जाता",
                                isOn: $shubh)
                    AlertToggle(emoji: "⏰", title: "10 मिनट पहले भी याद दिलाएँ", subtitle: "शुरू होने से पहले एक सूचना", isOn: $early)

                    if denied {
                        Button { if let u = URL(string: UIApplication.openSettingsURLString) { openURL(u) } } label: {
                            Text("सूचनाएँ बंद हैं। यहाँ टैप करके सेटिंग में Banaras Buzz की सूचनाएँ चालू करें।")
                                .font(.system(size: 13, weight: .medium)).foregroundColor(BZ.saffronDeep)
                                .frame(maxWidth: .infinity, alignment: .leading).padding(10)
                                .background(BZ.tileStrong).clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(.plain)
                    }

                    Text("📌 हमेशा दिखने वाला विजेट").font(.system(size: 17, weight: .bold)).foregroundColor(BZ.ink).padding(.top, 8)
                    Text("iPhone पर सूचना को पिन नहीं किया जा सकता। इसके बदले \"आज का पंचांग\" विजेट लगाएँ — यह लॉक स्क्रीन और होम स्क्रीन पर हमेशा दिखेगा, उलटी गिनती के साथ।")
                        .font(.system(size: 14)).foregroundColor(BZ.inkSoft)
                    HowTo(title: "🔒 लॉक स्क्रीन पर", steps: [
                        "लॉक स्क्रीन को दबाकर रखें → Customize → Lock Screen",
                        "समय के नीचे वाले विजेट बॉक्स पर टैप करें",
                        "Banaras Buzz → आज का पंचांग चुनें",
                    ])
                    HowTo(title: "🏠 होम स्क्रीन पर", steps: [
                        "होम स्क्रीन पर खाली जगह को दबाकर रखें",
                        "ऊपर बाएँ + दबाएँ और Banaras Buzz खोजें",
                        "आज का पंचांग → Add Widget",
                    ])
                }
                .padding(16)
            }
            .background(BZ.cream.ignoresSafeArea())
            .navigationTitle("पंचांग अलर्ट")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("ठीक है") { dismiss() }.foregroundColor(BZ.saffron) } }
        }
        .onChange(of: rahu) { on in apply({ PanchangAlerts.rahu = on }, turningOn: on) }
        .onChange(of: shubh) { on in apply({ PanchangAlerts.shubh = on }, turningOn: on) }
        .onChange(of: early) { on in PanchangAlerts.early = on; PanchangAlerts.reschedule(store: store) }
    }

    private func apply(_ change: @escaping () -> Void, turningOn: Bool) {
        if !turningOn {
            change()
            PanchangAlerts.reschedule(store: store)
            return
        }
        PanchangAlerts.requestPermission { granted in
            denied = !granted
            change()
            PanchangAlerts.reschedule(store: store)
            if granted { store.say("अलर्ट चालू") }
        }
    }
}

private struct AlertToggle: View {
    let emoji: String
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    var body: some View {
        Toggle(isOn: $isOn) {
            HStack(spacing: 10) {
                Text(emoji).font(.system(size: 20))
                VStack(alignment: .leading, spacing: 1) {
                    Text(title).font(.system(size: 15, weight: .semibold)).foregroundColor(BZ.ink)
                    Text(subtitle).font(.system(size: 12.5)).foregroundColor(BZ.muted)
                }
            }
        }
        .tint(BZ.saffron)
        .padding(.horizontal, 12).padding(.vertical, 10)
        .background(BZ.tile).clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

private struct HowTo: View {
    let title: String
    let steps: [String]
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.system(size: 15, weight: .bold)).foregroundColor(BZ.ink)
            ForEach(Array(steps.enumerated()), id: \.offset) { i, s in
                Text("\(i + 1). \(s)").font(.system(size: 13.5)).foregroundColor(BZ.inkSoft)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12).background(Color.white).clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
