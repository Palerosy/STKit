import STKit
import SwiftUI
import PDFKit

/// Floating context menu bar shown above a selected annotation.
/// Shows Copy, Delete, Inspector, Note, Order actions — similar to PSPDFKit's selection menu.
struct STSelectionMenuBar: View {

    let onCopy: () -> Void
    let onPaste: (() -> Void)?
    let onDelete: () -> Void
    let onInspector: (() -> Void)?
    let onNote: () -> Void
    let onBringToFront: () -> Void
    let onBringForward: () -> Void
    let onSendBackward: () -> Void
    let onSendToBack: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            menuButton(STStrings.selectionCopy, systemImage: "doc.on.doc") {
                onCopy()
            }
            if let onPaste = onPaste {
                menuDivider
                menuButton(STStrings.selectionPaste, systemImage: "doc.on.clipboard") {
                    onPaste()
                }
            }
            menuDivider
            menuButton(STStrings.selectionDelete, systemImage: "trash", isDestructive: true) {
                onDelete()
            }
            if let onInspector = onInspector {
                menuDivider
                menuButton(STStrings.selectionInspector, systemImage: "slider.horizontal.3") {
                    onInspector()
                }
            }
            menuDivider
            menuButton(STStrings.selectionNote, systemImage: "note.text") {
                onNote()
            }
            menuDivider
            orderMenu
            menuDivider
            menuButton(nil, systemImage: "xmark") {
                onDismiss()
            }
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
        .shadow(color: .black.opacity(0.05), radius: 1, x: 0, y: 1)
    }

    // MARK: - Order Submenu

    private var orderMenu: some View {
        Menu {
            Button {
                onBringToFront()
            } label: {
                Label(STStrings.orderFront, systemImage: "square.3.layers.3d.top.filled")
            }
            Button {
                onBringForward()
            } label: {
                Label(STStrings.orderForward, systemImage: "square.2.layers.3d.top.filled")
            }
            Button {
                onSendBackward()
            } label: {
                Label(STStrings.orderBackward, systemImage: "square.2.layers.3d.bottom.filled")
            }
            Button {
                onSendToBack()
            } label: {
                Label(STStrings.orderBack, systemImage: "square.3.layers.3d.bottom.filled")
            }
        } label: {
            HStack(spacing: 3) {
                Text(STStrings.orderTitle)
                    .font(.system(size: 13, weight: .medium))
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 8, weight: .semibold))
            }
            .foregroundColor(.primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
        }
        #if os(macOS)
        .menuStyle(.borderlessButton)
        #endif
    }

    // MARK: - Helpers

    @ViewBuilder
    private func menuButton(_ title: String?, systemImage: String, isDestructive: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let title = title {
                    Text(title)
                        .font(.system(size: 13, weight: .medium))
                } else {
                    Image(systemName: systemImage)
                        .font(.system(size: 13, weight: .medium))
                }
            }
            .foregroundColor(isDestructive ? .red : .primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var menuDivider: some View {
        Rectangle()
            .fill(.quaternary)
            .frame(width: 0.5, height: 24)
    }
}
