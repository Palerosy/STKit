import SwiftUI
import WebKit

#if os(iOS)
/// UIViewRepresentable wrapping WKWebView for DOCX content editing.
/// Uses contentEditable HTML with JS bridge for formatting commands.
struct STWebEditorView: UIViewRepresentable {

    @ObservedObject var viewModel: STWebEditorViewModel

    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel)
    }

    func makeUIView(context: Context) -> WKWebView {
        let webView = createWebView(coordinator: context.coordinator)
        webView.scrollView.delegate = context.coordinator
        webView.isOpaque = false
        webView.backgroundColor = .white
        webView.scrollView.backgroundColor = .white
        webView.scrollView.alwaysBounceVertical = true
        webView.scrollView.keyboardDismissMode = .onDrag
        webView.scrollView.showsHorizontalScrollIndicator = false
        webView.scrollView.minimumZoomScale = 0.5
        webView.scrollView.maximumZoomScale = 3.0

        viewModel.webView = webView
        context.coordinator.webView = webView
        loadEditorHTML(into: webView)
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {}

    static func dismantleUIView(_ webView: WKWebView, coordinator: Coordinator) {
        cleanupMessageHandlers(webView)
    }
}

#elseif os(macOS)
/// NSViewRepresentable wrapping WKWebView for DOCX content editing.
/// Uses contentEditable HTML with JS bridge for formatting commands.
struct STWebEditorView: NSViewRepresentable {

    @ObservedObject var viewModel: STWebEditorViewModel

    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel)
    }

    func makeNSView(context: Context) -> WKWebView {
        let webView = createWebView(coordinator: context.coordinator)
        webView.wantsLayer = true
        webView.layer?.backgroundColor = NSColor.white.cgColor

        viewModel.webView = webView
        context.coordinator.webView = webView
        loadEditorHTML(into: webView)
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {}

    static func dismantleNSView(_ webView: WKWebView, coordinator: Coordinator) {
        cleanupMessageHandlers(webView)
    }
}
#endif

// MARK: - Shared implementation

extension STWebEditorView {

    /// Create and configure a WKWebView with message handlers
    func createWebView(coordinator: Coordinator) -> WKWebView {
        let config = WKWebViewConfiguration()
        let controller = WKUserContentController()

        controller.add(coordinator, name: "formattingState")
        controller.add(coordinator, name: "contentChanged")
        controller.add(coordinator, name: "editorReady")
        controller.add(coordinator, name: "chartTapped")
        controller.add(coordinator, name: "commentTapped")
        controller.add(coordinator, name: "pageChanged")
        controller.add(coordinator, name: "shapeDrag")
        controller.add(coordinator, name: "jsLog")

        config.userContentController = controller
        config.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = coordinator
        return webView
    }

    /// Load the editor HTML template from the resource bundle
    func loadEditorHTML(into webView: WKWebView) {
        let bundle = STDOCXBundleHelper.resourceBundle

        if let htmlURL = bundle.url(forResource: "editor", withExtension: "html") {
            webView.loadFileURL(htmlURL, allowingReadAccessTo: htmlURL.deletingLastPathComponent())
            return
        }

        if let htmlURL = Bundle.main.url(forResource: "editor", withExtension: "html") {
            webView.loadFileURL(htmlURL, allowingReadAccessTo: htmlURL.deletingLastPathComponent())
            return
        }

        print("[STWebEditor] editor.html not found in bundle, using inline fallback")
        let html = buildInlineEditorHTML()
        webView.loadHTMLString(html, baseURL: nil)
    }

    /// Build a self-contained editor HTML (fallback when resources aren't bundled)
    private func buildInlineEditorHTML() -> String {
        let jsContent: String
        let bundle = STDOCXBundleHelper.resourceBundle
        if let jsURL = bundle.url(forResource: "editor", withExtension: "js"),
           let js = try? String(contentsOf: jsURL, encoding: .utf8) {
            jsContent = js
        } else if let jsURL = Bundle.main.url(forResource: "editor", withExtension: "js"),
                  let js = try? String(contentsOf: jsURL, encoding: .utf8) {
            jsContent = js
        } else {
            jsContent = "// editor.js not found"
        }

        return """
        <!DOCTYPE html>
        <html>
        <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <style>
        * { box-sizing: border-box; }
        html, body { margin: 0; padding: 0; height: 100%; -webkit-text-size-adjust: none; }
        body { font-family: 'Calibri', -apple-system, sans-serif; font-size: 11pt; line-height: 1.15; color: #000; background: #fff; }
        #editor { min-height: 100%; padding: 40px 32px; outline: none; word-wrap: break-word; }
        #editor:empty::before { content: attr(data-placeholder); color: #999; pointer-events: none; }
        #editor p { margin: 0 0 2pt 0; }
        #editor table { border-collapse: collapse; width: auto; max-width: 100%; margin: 6pt 0; }
        #editor td, #editor th { padding: 3px 6px; min-width: 20px; vertical-align: top; }
        #editor td p, #editor th p { margin: 0; padding: 0; }
        #editor ul, #editor ol { margin: 4pt 0; padding-left: 24pt; }
        #editor img { max-width: 100%; height: auto; }
        #editor a { color: #0563C1; text-decoration: underline; }
        </style>
        </head>
        <body>
        <div id="editor" contenteditable="true" data-placeholder="Start typing..."></div>
        <script>\(jsContent)</script>
        </body>
        </html>
        """
    }

    static func cleanupMessageHandlers(_ webView: WKWebView) {
        let controller = webView.configuration.userContentController
        controller.removeScriptMessageHandler(forName: "formattingState")
        controller.removeScriptMessageHandler(forName: "contentChanged")
        controller.removeScriptMessageHandler(forName: "editorReady")
        controller.removeScriptMessageHandler(forName: "chartTapped")
        controller.removeScriptMessageHandler(forName: "commentTapped")
        controller.removeScriptMessageHandler(forName: "pageChanged")
        controller.removeScriptMessageHandler(forName: "shapeDrag")
        controller.removeScriptMessageHandler(forName: "jsLog")
    }
}

// MARK: - Coordinator

extension STWebEditorView {

    final class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        let viewModel: STWebEditorViewModel
        weak var webView: WKWebView?
        var cachedPageOffsets: [CGFloat] = []

        init(viewModel: STWebEditorViewModel) {
            self.viewModel = viewModel
        }

        // MARK: - WKScriptMessageHandler

        nonisolated func userContentController(
            _ userContentController: WKUserContentController,
            didReceive message: WKScriptMessage
        ) {
            Task { @MainActor [weak self] in
                guard let self else { return }

                switch message.name {
                case "formattingState":
                    if let body = message.body as? [String: Any] {
                        self.viewModel.updateFormattingState(from: body)
                    }

                case "contentChanged":
                    self.viewModel.isContentDirty = true

                case "editorReady":
                    self.viewModel.isReady = true
                    // Don't load content if document is still loading (e.g. DOC via WebKit).
                    // The .task in EditorView will call loadContent() after loading completes.
                    if !self.viewModel.document.isLoading {
                        self.viewModel.loadContent()
                    }

                case "chartTapped":
                    if let body = message.body as? [String: Any],
                       let chartId = body["chartId"] as? String {
                        self.viewModel.handleChartTapped(chartId: chartId)
                    }

                case "commentTapped":
                    if let body = message.body as? [String: Any],
                       let commentId = body["commentId"] as? String,
                       let text = body["text"] as? String {
                        let contextText = body["contextText"] as? String ?? ""
                        self.viewModel.tappedComment = (id: commentId, text: text, contextText: contextText)
                    }

                case "pageChanged":
                    if let body = message.body as? [String: Any] {
                        self.viewModel.updatePageInfo(from: body)
                        self.cachedPageOffsets = self.viewModel.pageOffsets
                    }

                case "shapeDrag":
                    if let body = message.body as? [String: Any],
                       let dragging = body["dragging"] as? Bool {
                        #if os(iOS)
                        self.webView?.scrollView.isScrollEnabled = !dragging
                        #endif
                    }

                case "jsLog":
                    if let msg = message.body as? String {
                        print("[STWebEditor-JS] \(msg)")
                    }

                default:
                    break
                }
            }
        }

        // MARK: - WKNavigationDelegate

        nonisolated func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {}

        nonisolated func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            print("[STWebEditor] Navigation failed: \(error.localizedDescription)")
        }
    }
}

#if os(iOS)
extension STWebEditorView.Coordinator: UIScrollViewDelegate {
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        updateCurrentPageFromScroll(scrollView)
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            updateCurrentPageFromScroll(scrollView)
        }
    }

    private func updateCurrentPageFromScroll(_ scrollView: UIScrollView) {
        let offsets = cachedPageOffsets
        guard offsets.count > 1 else { return }

        let scrollY = scrollView.contentOffset.y
        let viewportMid = scrollY + scrollView.bounds.height / 2
        var bestPage = 0
        for (i, offset) in offsets.enumerated() {
            if offset <= viewportMid {
                bestPage = i
            }
        }

        Task { @MainActor [weak self] in
            guard let self else { return }
            if self.viewModel.currentPage != bestPage {
                self.viewModel.currentPage = bestPage
            }
        }
    }
}
#endif
