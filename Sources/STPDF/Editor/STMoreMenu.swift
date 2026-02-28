import STKit
import SwiftUI
import PDFKit

/// More options menu (...) button with contextual actions
struct STMoreMenu: View {

    @ObservedObject var viewModel: STPDFEditorViewModel
    @ObservedObject var bookmarkManager: STBookmarkManager
    let configuration: STPDFConfiguration

    var body: some View {
        Menu {
            // View section
            if configuration.showOutline {
                Button {
                    viewModel.activeSheet = .outline
                } label: {
                    Label(STStrings.outline, systemImage: "list.bullet.indent")
                }
            }

            if configuration.showEditPages && configuration.allowDocumentEditing {
                Button {
                    viewModel.viewMode = .documentEditor
                } label: {
                    Label(STStrings.editPages, systemImage: "doc.badge.gearshape")
                }
            }

            Divider()

            // File section
            if configuration.showShare {
                Button {
                    shareDocument()
                } label: {
                    Label(STStrings.share, systemImage: "square.and.arrow.up")
                }
            }

            if configuration.showPrint {
                Button {
                    printDocument()
                } label: {
                    Label(STStrings.print, systemImage: "printer")
                }
            }

            if configuration.showSaveAsText {
                Button {
                    saveAsText()
                } label: {
                    Label(STStrings.saveAsText, systemImage: "doc.text")
                }
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .font(.system(size: 20))
        }
    }

    // MARK: - Actions

    private func shareDocument() {
        guard let url = viewModel.document.url else { return }
        viewModel.document.save()

        #if os(iOS)
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)

        if let windowScene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
           let rootVC = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController {
            var topVC = rootVC
            while let presented = topVC.presentedViewController {
                topVC = presented
            }
            activityVC.popoverPresentationController?.sourceView = topVC.view
            topVC.present(activityVC, animated: true)
        }
        #elseif os(macOS)
        let sharingPicker = NSSharingServicePicker(items: [url])
        if let window = NSApplication.shared.keyWindow,
           let contentView = window.contentView {
            sharingPicker.show(relativeTo: .zero, of: contentView, preferredEdge: .minY)
        }
        #endif
    }

    private func printDocument() {
        if let onPrint = configuration.onPrint ?? STKitConfiguration.shared.onPrint, !onPrint() { return }

        guard let url = viewModel.document.url else { return }
        #if os(iOS)
        let printController = UIPrintInteractionController.shared
        printController.printingItem = url
        printController.present(animated: true)
        #elseif os(macOS)
        if let pdfDoc = PDFDocument(url: url) {
            let printInfo = NSPrintInfo.shared
            printInfo.isHorizontallyCentered = true
            printInfo.isVerticallyCentered = true
            let printOp = pdfDoc.printOperation(for: printInfo, scalingMode: .pageScaleToFit, autoRotate: true)
            printOp?.run()
        }
        #endif
    }

    private func saveAsText() {
        guard let textURL = STTextExtractor.saveAsTextFile(
            from: viewModel.document.pdfDocument,
            title: viewModel.document.title
        ) else { return }

        #if os(iOS)
        let activityVC = UIActivityViewController(activityItems: [textURL], applicationActivities: nil)

        if let windowScene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
           let rootVC = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController {
            var topVC = rootVC
            while let presented = topVC.presentedViewController {
                topVC = presented
            }
            activityVC.popoverPresentationController?.sourceView = topVC.view
            topVC.present(activityVC, animated: true)
        }
        #elseif os(macOS)
        let sharingPicker = NSSharingServicePicker(items: [textURL])
        if let window = NSApplication.shared.keyWindow,
           let contentView = window.contentView {
            sharingPicker.show(relativeTo: .zero, of: contentView, preferredEdge: .minY)
        }
        #endif
    }
}
