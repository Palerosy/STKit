import SwiftUI

#if os(iOS)
import UIKit

/// Share sheet wrapper — used across all STKit modules
public struct STShareSheet: UIViewControllerRepresentable {
    public let activityItems: [Any]

    public init(activityItems: [Any]) {
        self.activityItems = activityItems
    }

    public func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    public func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#elseif os(macOS)
import AppKit

/// Share sheet wrapper — used across all STKit modules (macOS)
public struct STShareSheet: NSViewRepresentable {
    public let activityItems: [Any]

    public init(activityItems: [Any]) {
        self.activityItems = activityItems
    }

    public func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            let picker = NSSharingServicePicker(items: activityItems)
            picker.show(relativeTo: view.bounds, of: view, preferredEdge: .minY)
        }
        return view
    }

    public func updateNSView(_ nsView: NSView, context: Context) {}
}
#endif
