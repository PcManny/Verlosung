import SwiftUI
import WebKit

private let hintergrund = Color(red: 17/255, green: 17/255, blue: 17/255)

func baueWebView() -> WKWebView {
    let web = WKWebView(frame: .zero, configuration: WKWebViewConfiguration())
    #if os(iOS)
    web.isOpaque = false
    web.backgroundColor = UIColor(red: 17/255, green: 17/255, blue: 17/255, alpha: 1)
    web.scrollView.backgroundColor = web.backgroundColor
    #endif
    // Die Seite liegt fest in der App und läuft ohne Internet.
    if let url = Bundle.main.url(forResource: "index", withExtension: "html") {
        web.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
    }
    return web
}

#if os(iOS)
struct WebView: UIViewRepresentable {
    func makeUIView(context: Context) -> WKWebView { baueWebView() }
    func updateUIView(_ uiView: WKWebView, context: Context) {}
}
#else
struct WebView: NSViewRepresentable {
    func makeNSView(context: Context) -> WKWebView { baueWebView() }
    func updateNSView(_ nsView: WKWebView, context: Context) {}
}
#endif

struct ContentView: View {
    var body: some View {
        ZStack {
            hintergrund.ignoresSafeArea()
            WebView()
        }
    }
}
