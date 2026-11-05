import SwiftUI
import UserNotifications

@main
struct BanarasBuzzApp: App {
    init() {
        // Show panchang alerts while the app is open, and open the Panchang screen on tap.
        UNUserNotificationCenter.current().delegate = NotificationRouter.shared
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}
