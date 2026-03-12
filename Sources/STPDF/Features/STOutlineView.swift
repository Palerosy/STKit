import STKit
import SwiftUI
import PDFKit

/// Document outline / table of contents view
struct STOutlineView: View {

    let document: PDFDocument
    let onPageSelected: (Int) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        #if os(macOS)
        macOSBody
        #else
        iOSBody
        #endif
    }

    @ViewBuilder
    private var outlineContent: some View {
        if !outlineEntries.isEmpty {
            List {
                ForEach(outlineEntries) { entry in
                    Button {
                        if entry.pageIndex >= 0 {
                            onPageSelected(entry.pageIndex)
                            dismiss()
                        }
                    } label: {
                        HStack {
                            Text(entry.title)
                                .foregroundColor(.primary)
                                .padding(.leading, CGFloat(entry.depth) * 16)
                            Spacer()
                            if entry.pageIndex >= 0 {
                                Text(STStrings.page(entry.pageIndex + 1))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .listStyle(.plain)
        } else {
            VStack(spacing: 12) {
                Image(systemName: "list.bullet.indent")
                    .font(.system(size: 40))
                    .foregroundColor(.secondary)
                Text(STStrings.noOutlineAvailable)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, minHeight: 120)
        }
    }

    #if os(macOS)
    private var macOSBody: some View {
        let sw = NSScreen.main?.frame.width ?? 1440
        let sh = NSScreen.main?.frame.height ?? 900
        return VStack(spacing: 0) {
            HStack {
                Text(STStrings.outline)
                    .font(.headline)
                Spacer()
                Button(STStrings.done) { dismiss() }
                    .buttonStyle(.plain)
                    .foregroundColor(.accentColor)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            Divider()

            outlineContent
                .frame(maxHeight: sh * 0.45)
        }
        .frame(width: sw * 0.35)
    }
    #endif

    private var iOSBody: some View {
        STNavigationView {
            outlineContent
                .navigationTitle(STStrings.outline)
                .stNavigationBarTitleDisplayMode()
                .toolbar {
                    ToolbarItem(placement: .stTrailing) {
                        Button(STStrings.done) { dismiss() }
                    }
                }
        }
    }

    /// Pre-computed outline entries (no PDFOutline references held during rendering)
    private var outlineEntries: [OutlineEntry] {
        guard let root = document.outlineRoot, root.numberOfChildren > 0 else { return [] }
        var result: [OutlineEntry] = []
        flatten(root, depth: 0, into: &result)
        return result
    }

    private struct OutlineEntry: Identifiable {
        let id = UUID()
        let title: String
        let pageIndex: Int  // -1 if no destination
        let depth: Int
    }

    private func flatten(_ parent: PDFOutline, depth: Int, into result: inout [OutlineEntry]) {
        for i in 0..<parent.numberOfChildren {
            guard let child = parent.child(at: i) else { continue }
            let title = child.label ?? STStrings.untitled
            var pageIndex = -1
            if let dest = child.destination, let page = dest.page {
                let idx = document.index(for: page)
                if idx != NSNotFound { pageIndex = idx }
            }
            result.append(OutlineEntry(title: title, pageIndex: pageIndex, depth: depth))
            if child.numberOfChildren > 0 {
                flatten(child, depth: depth + 1, into: &result)
            }
        }
    }
}
