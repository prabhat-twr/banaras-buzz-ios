// Ported from the Android app's util/MapUtils.kt — opens the device's default maps app
// centered on a text search for `query` (a place name plus "Varanasi" for disambiguation).
// Tries the Apple Maps URL scheme first (universally available on iOS); falls back to Google
// Maps' web search if that somehow can't be opened.
import UIKit

func openMap(query: String) {
    let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
    guard let appleMapsUrl = URL(string: "https://maps.apple.com/?q=\(encoded)") else { return }
    UIApplication.shared.open(appleMapsUrl, options: [:]) { success in
        if !success, let googleUrl = URL(string: "https://www.google.com/maps/search/?api=1&query=\(encoded)") {
            UIApplication.shared.open(googleUrl)
        }
    }
}
