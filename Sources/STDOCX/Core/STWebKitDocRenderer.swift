import Foundation
import WebKit
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif
import STKit

/// Result from WebKit rendering — contains paginated PDF, extracted text, and HTML
struct STWebKitRenderResult {
    let pdfData: Data
    let extractedText: String
    let extractedHTML: String
}

/// Renders legacy DOC files (and other WebKit-supported formats) to paginated PDF
/// using WKWebView + print renderer, and extracts text via JavaScript.
@MainActor
final class STWebKitDocRenderer: NSObject {

    /// Render a document file to paginated PDF and extract its text content
    static func render(fileURL: URL, timeoutSeconds: TimeInterval = 15) async throws -> STWebKitRenderResult {
        let renderer = STWebKitDocRenderer()
        return try await withCheckedThrowingContinuation { continuation in
            renderer.continuation = continuation
            renderer.startRender(fileURL: fileURL, timeoutSeconds: timeoutSeconds)
        }
    }

    // MARK: - Private

    private var webView: WKWebView?
    private var continuation: CheckedContinuation<STWebKitRenderResult, Error>?
    private var timeoutWorkItem: DispatchWorkItem?
    private var hasCompleted = false
    private var retainedSelf: STWebKitDocRenderer?
    #if os(macOS)
    private var offscreenWindow: NSWindow?
    #endif
    private var tempFileURL: URL?

    private func startRender(fileURL: URL, timeoutSeconds: TimeInterval) {
        retainedSelf = self

        let config = WKWebViewConfiguration()
        let webView = WKWebView(frame: CGRect(x: 0, y: 0, width: 612, height: 792), configuration: config)
        webView.navigationDelegate = self
        self.webView = webView

        // WKWebView must be in a window hierarchy to render content
        #if os(iOS)
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = scene.windows.first {
            webView.alpha = 0
            window.addSubview(webView)
        }
        #elseif os(macOS)
        // Create a dedicated offscreen window (avoids SwiftUI NSHostingController conflict)
        let offscreen = NSWindow(
            contentRect: CGRect(x: -20000, y: -20000, width: 612, height: 792),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        offscreen.contentView?.addSubview(webView)
        offscreen.orderBack(nil)
        self.offscreenWindow = offscreen
        #endif

        // Set timeout
        let timeout = DispatchWorkItem { [weak self] in
            guard let self, !self.hasCompleted else { return }
            self.finish(with: .failure(RendererError.timeout))
        }
        self.timeoutWorkItem = timeout
        DispatchQueue.main.asyncAfter(deadline: .now() + timeoutSeconds, execute: timeout)

        // Copy file to temp directory so WKWebView's sandboxed WebContent process can access it
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("STDocRenderer", isDirectory: true)
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        let tempURL = tempDir.appendingPathComponent(fileURL.lastPathComponent)
        try? FileManager.default.removeItem(at: tempURL) // remove old copy if exists
        if (try? FileManager.default.copyItem(at: fileURL, to: tempURL)) != nil {
            self.tempFileURL = tempURL
            webView.loadFileURL(tempURL, allowingReadAccessTo: tempDir)
        } else {
            // Fallback: try loading directly
            webView.loadFileURL(fileURL, allowingReadAccessTo: fileURL.deletingLastPathComponent())
        }
    }

    /// Create paginated PDF from WKWebView content
    private func createPaginatedPDF(from webView: WKWebView) async -> Data? {
        #if os(iOS)
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792) // US Letter
        let printableRect = pageRect.insetBy(dx: 36, dy: 36)        // 0.5" margins

        let printFormatter = webView.viewPrintFormatter()

        let printRenderer = UIPrintPageRenderer()
        printRenderer.addPrintFormatter(printFormatter, startingAtPageAt: 0)
        printRenderer.setValue(pageRect, forKey: "paperRect")
        printRenderer.setValue(printableRect, forKey: "printableRect")

        let pdfData = NSMutableData()
        UIGraphicsBeginPDFContextToData(pdfData, pageRect, nil)

        let pageCount = printRenderer.numberOfPages
        for i in 0..<pageCount {
            UIGraphicsBeginPDFPage()
            printRenderer.drawPage(at: i, in: UIGraphicsGetPDFContextBounds())
        }

        // At least one page for empty documents
        if pageCount == 0 {
            UIGraphicsBeginPDFPage()
        }

        UIGraphicsEndPDFContext()

        return pdfData as Data
        #elseif os(macOS)
        // macOS: Use WKWebView's async PDF creation to capture full rendered content
        let config = WKPDFConfiguration()
        return try? await webView.pdf(configuration: config)
        #endif
    }

    private func finish(with result: Result<STWebKitRenderResult, Error>) {
        guard !hasCompleted else { return }
        hasCompleted = true
        timeoutWorkItem?.cancel()
        webView?.removeFromSuperview()
        webView?.navigationDelegate = nil
        webView = nil
        #if os(macOS)
        offscreenWindow?.close()
        offscreenWindow = nil
        #endif
        // Clean up temp file
        if let tempURL = tempFileURL {
            try? FileManager.default.removeItem(at: tempURL)
            tempFileURL = nil
        }

        switch result {
        case .success(let data):
            continuation?.resume(returning: data)
        case .failure(let error):
            continuation?.resume(throwing: error)
        }
        continuation = nil
        retainedSelf = nil
    }

    // MARK: - Image Capture via Snapshots

    /// Capture embedded images (img, object, embed) as WKWebView snapshots and replace with base64
    private func captureEmbeddedImages(in webView: WKWebView) async {
        let originalFrame = webView.frame

        // Set visible for full-fidelity snapshots, but move offscreen
        #if os(iOS)
        webView.frame = CGRect(x: -10000, y: -10000, width: originalFrame.width, height: originalFrame.height)
        webView.alpha = 1.0
        #elseif os(macOS)
        webView.frame = CGRect(x: -10000, y: -10000, width: originalFrame.width, height: originalFrame.height)
        webView.alphaValue = 1.0
        #endif

        // Find all image-like elements and tag them
        let findJS = """
        (function() {
            var results = [];
            var els = document.querySelectorAll('img, object, embed');
            for (var i = 0; i < els.length; i++) {
                var el = els[i];
                var rect = el.getBoundingClientRect();
                if (rect.width > 5 && rect.height > 5) {
                    el.setAttribute('data-st-cap', 'c' + i);
                    results.push({i: i, w: rect.width, h: rect.height});
                }
            }
            return JSON.stringify(results);
        })()
        """

        guard let json = try? await webView.evaluateJavaScript(findJS) as? String,
              let jsonData = json.data(using: .utf8),
              let elements = try? JSONSerialization.jsonObject(with: jsonData) as? [[String: Any]],
              !elements.isEmpty else {
            #if os(iOS)
            webView.alpha = 0
            #elseif os(macOS)
            webView.alphaValue = 0
            #endif
            webView.frame = originalFrame
            return
        }

        print("[STWebKitDocRenderer] Found \(elements.count) image elements to capture")

        for el in elements {
            guard let idx = el["i"] as? Int,
                  let w = (el["w"] as? NSNumber)?.doubleValue,
                  let h = (el["h"] as? NSNumber)?.doubleValue,
                  w > 5, h > 5 else { continue }

            let scrollJS = """
            (function() {
                var el = document.querySelector('[data-st-cap="c\(idx)"]');
                if (el) {
                    el.scrollIntoView({block: 'center'});
                    var rect = el.getBoundingClientRect();
                    return JSON.stringify({x: rect.x, y: rect.y, w: rect.width, h: rect.height});
                }
                return null;
            })()
            """

            guard let rectJson = try? await webView.evaluateJavaScript(scrollJS) as? String,
                  let rectData = rectJson.data(using: .utf8),
                  let rect = try? JSONSerialization.jsonObject(with: rectData) as? [String: Any],
                  let rx = (rect["x"] as? NSNumber)?.doubleValue,
                  let ry = (rect["y"] as? NSNumber)?.doubleValue,
                  let rw = (rect["w"] as? NSNumber)?.doubleValue,
                  let rh = (rect["h"] as? NSNumber)?.doubleValue,
                  rw > 5, rh > 5 else { continue }

            try? await Task.sleep(nanoseconds: 400_000_000)

            let config = WKSnapshotConfiguration()
            config.rect = CGRect(x: rx, y: ry, width: rw, height: rh)

            do {
                let snapshot = try await webView.takeSnapshot(configuration: config)
                guard let pngData = snapshot.pngData() else { continue }
                let base64 = pngData.base64EncodedString()

                let isLikelyBlank = pngData.count < 500
                print("[STWebKitDocRenderer] Element \(idx): \(Int(rw))x\(Int(rh)), base64=\(base64.count) chars, png=\(pngData.count) bytes\(isLikelyBlank ? " (LIKELY BLANK)" : "")")

                let replaceJS = """
                (function() {
                    var el = document.querySelector('[data-st-cap="c\(idx)"]');
                    if (el) {
                        var img = document.createElement('img');
                        img.src = 'data:image/png;base64,\(base64)';
                        img.style.maxWidth = '100%';
                        img.style.height = 'auto';
                        el.parentNode.replaceChild(img, el);
                        return true;
                    }
                    return false;
                })()
                """
                _ = try? await webView.evaluateJavaScript(replaceJS)
            } catch {
                print("[STWebKitDocRenderer] Snapshot failed for element \(idx): \(error)")
            }
        }

        #if os(iOS)
        webView.alpha = 0
        #elseif os(macOS)
        webView.alphaValue = 0
        #endif
        webView.frame = originalFrame
    }

    enum RendererError: LocalizedError {
        case timeout
        case pdfCreationFailed
        case loadFailed(String)

        var errorDescription: String? {
            switch self {
            case .timeout: return "WebKit rendering timed out"
            case .pdfCreationFailed: return "Failed to create PDF from rendered content"
            case .loadFailed(let detail): return "Failed to load document: \(detail)"
            }
        }
    }
}

// MARK: - WKNavigationDelegate

extension STWebKitDocRenderer: WKNavigationDelegate {

    nonisolated func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        Task { @MainActor [weak self] in
            guard let self, !self.hasCompleted else { return }

            try? await Task.sleep(nanoseconds: 500_000_000)

            guard !self.hasCompleted else { return }

            var extractedText = ""
            if let text = try? await webView.evaluateJavaScript("document.body.innerText") as? String {
                extractedText = text
                print("[STWebKitDocRenderer] Extracted \(text.count) chars text")
            }

            guard let pdfData = await self.createPaginatedPDF(from: webView) else {
                self.finish(with: .failure(RendererError.pdfCreationFailed))
                return
            }

            await self.captureEmbeddedImages(in: webView)

            var extractedHTML = ""
            let cleanupJS = """
            (function() {
                var remove = document.querySelectorAll('applet, iframe, script, link');
                for (var i = 0; i < remove.length; i++) { remove[i].remove(); }
                // Remove remaining object/embed that weren't captured as images
                var objs = document.querySelectorAll('object, embed');
                for (var i = 0; i < objs.length; i++) { objs[i].remove(); }
                // Remove file:// and blob: src references (but keep data: base64 images)
                var allSrc = document.querySelectorAll('[src]');
                for (var i = allSrc.length - 1; i >= 0; i--) {
                    var src = allSrc[i].getAttribute('src') || '';
                    if ((src.startsWith('file://') || src.startsWith('blob:')) && !src.startsWith('data:')) {
                        allSrc[i].remove();
                    }
                }
                // Keep style elements for table borders etc.
                return document.body.innerHTML;
            })()
            """
            if let html = try? await webView.evaluateJavaScript(cleanupJS) as? String {
                extractedHTML = html
                print("[STWebKitDocRenderer] Extracted \(html.count) chars HTML")
            }

            let result = STWebKitRenderResult(pdfData: pdfData, extractedText: extractedText, extractedHTML: extractedHTML)
            self.finish(with: .success(result))
        }
    }

    nonisolated func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        Task { @MainActor [weak self] in
            self?.finish(with: .failure(RendererError.loadFailed(error.localizedDescription)))
        }
    }

    nonisolated func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        Task { @MainActor [weak self] in
            self?.finish(with: .failure(RendererError.loadFailed(error.localizedDescription)))
        }
    }
}
