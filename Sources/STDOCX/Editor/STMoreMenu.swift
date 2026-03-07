import SwiftUI
import STKit
import PDFKit

/// More options menu (...) button with contextual actions
struct STMoreMenu: View {

    @ObservedObject var viewModel: STDOCXEditorViewModel
    @ObservedObject var bookmarkManager: STBookmarkManager
    let configuration: STDOCXConfiguration

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

            Divider()

            // File section
            if configuration.showShare {
                Button {
                    licensedAction { shareDocument() }
                } label: {
                    Label(STStrings.share, systemImage: "square.and.arrow.up")
                }
            }

            if configuration.showPrint {
                Button {
                    licensedAction { printDocument() }
                } label: {
                    Label(STStrings.print, systemImage: "printer")
                }
            }

            if configuration.showSaveAsText {
                Button {
                    licensedAction { saveAsText() }
                } label: {
                    Label(STStrings.saveAsText, systemImage: "doc.text")
                }
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .font(.system(size: 20))
        }
        #if os(iOS)
        .fullScreenCover(isPresented: $showPremiumPaywall) {
            if let paywallView = STKitConfiguration.shared.premiumPaywallView {
                paywallView(paywallPlacement)
            }
        }
        #else
        .sheet(isPresented: $showPremiumPaywall) {
            if let paywallView = STKitConfiguration.shared.premiumPaywallView {
                paywallView(paywallPlacement)
            }
        }
        #endif
    }

    // MARK: - Premium Gate

    @State private var showLicenseAlert = false
    @State private var showPremiumPaywall = false
    @State private var paywallPlacement = "main"

    private func licensedAction(_ action: @escaping () -> Void, delay: Double = 0.35) {
        if STKitConfiguration.shared.isPurchased {
            action()
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                if STKitConfiguration.shared.premiumPaywallView != nil {
                    paywallPlacement = configuration.paywallPlacement
                    showPremiumPaywall = true
                } else if let handler = STKitConfiguration.shared.onPremiumFeatureTapped {
                    handler()
                } else {
                    showLicenseAlert = true
                }
            }
        }
    }

    // MARK: - Actions

    private func shareDocument() {
        guard let url = viewModel.document.url else { return }
        Task {
            await viewModel.webEditorViewModel.saveContent()
            viewModel.document.save(to: url)
        }

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
        viewModel.webEditorViewModel.printContent()
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
