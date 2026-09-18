// Ported from the Android app's ui/screens/SourceWebPage.kt.
import SwiftUI
import WebKit

private func safeSourceUrl(_ raw: String) -> URL? {
    guard let url = URL(string: raw.trimmingCharacters(in: .whitespacesAndNewlines)) else { return nil }
    guard let scheme = url.scheme?.lowercased(), scheme == "http" || scheme == "https" else { return nil }
    return url
}

struct SourceWebPage: View {
    let sourcePage: SourcePage
    let lang: Lang
    let onBack: () -> Void

    @State private var pageError = false
    @State private var canGoBack = false
    private let coordinator = WebViewCoordinator()

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                Text(lang == .hi ? "← वापस" : "← Back")
                    .font(BBFonts.body(13, weight: .medium))
                    .foregroundColor(BBColors.vermillion)
                    .onTapGesture {
                        if canGoBack { coordinator.webView?.goBack() } else { onBack() }
                    }
                Text(sourcePage.title)
                    .font(BBFonts.headline(14, weight: .semibold))
                    .foregroundColor(BBColors.textPrimary)
                    .lineLimit(2)
                Spacer()
            }
            .padding(14)
            .background(BBColors.card)

            if pageError {
                Text(lang == .hi ? "स्रोत पेज लोड नहीं हो सका।" : "Couldn't load the source page.")
                    .font(BBFonts.body(13))
                    .foregroundColor(BBColors.textMuted)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
            }

            WebViewRepresentable(
                url: sourcePage.url, coordinator: coordinator,
                onError: { pageError = true }, onNavigate: { pageError = false; canGoBack = coordinator.webView?.canGoBack ?? false }
            )
        }
        .background(BBColors.paper)
    }
}

private final class WebViewCoordinator: NSObject, WKNavigationDelegate {
    weak var webView: WKWebView?
    var onError: (() -> Void)?
    var onNavigate: (() -> Void)?
    var allowedUrl: String = ""

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url, let scheme = url.scheme?.lowercased() else {
            decisionHandler(.cancel); return
        }
        if scheme == "http" || scheme == "https" {
            decisionHandler(.allow)
        } else {
            decisionHandler(.cancel)
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        onNavigate?()
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        onError?()
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        onError?()
    }
}

private struct WebViewRepresentable: UIViewRepresentable {
    let url: String
    let coordinator: WebViewCoordinator
    let onError: () -> Void
    let onNavigate: () -> Void

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        coordinator.onError = onError
        coordinator.onNavigate = onNavigate
        webView.navigationDelegate = coordinator
        coordinator.webView = webView
        if let target = safeSourceUrl(url) {
            webView.load(URLRequest(url: target))
        }
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
}
