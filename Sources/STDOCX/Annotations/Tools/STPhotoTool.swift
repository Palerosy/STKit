import STKit
import SwiftUI
import PDFKit

#if os(iOS)
import PhotosUI

/// PHPicker wrapper that directly opens the photo library.
struct STPHPickerView: UIViewControllerRepresentable {

    let onImageSelected: (PlatformImage) -> Void
    let onCancel: () -> Void

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.selectionLimit = 1
        config.filter = .images
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onImageSelected: onImageSelected, onCancel: onCancel)
    }

    final class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let onImageSelected: (PlatformImage) -> Void
        let onCancel: () -> Void

        init(onImageSelected: @escaping (PlatformImage) -> Void, onCancel: @escaping () -> Void) {
            self.onImageSelected = onImageSelected
            self.onCancel = onCancel
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            guard let provider = results.first?.itemProvider,
                  provider.canLoadObject(ofClass: PlatformImage.self) else {
                onCancel()
                return
            }
            provider.loadObject(ofClass: PlatformImage.self) { [weak self] object, _ in
                DispatchQueue.main.async {
                    if let image = object as? PlatformImage {
                        self?.onImageSelected(image)
                    } else {
                        self?.onCancel()
                    }
                }
            }
        }
    }
}
#elseif os(macOS)
/// macOS image picker using NSOpenPanel
struct STPHPickerView: View {

    let onImageSelected: (PlatformImage) -> Void
    let onCancel: () -> Void

    var body: some View {
        Color.clear
            .frame(width: 0, height: 0)
            .onAppear {
                let panel = NSOpenPanel()
                panel.allowedContentTypes = [.image]
                panel.allowsMultipleSelection = false
                panel.canChooseDirectories = false
                panel.canChooseFiles = true
                panel.begin { response in
                    if response == .OK, let url = panel.url,
                       let image = NSImage(contentsOf: url) {
                        onImageSelected(image)
                    } else {
                        onCancel()
                    }
                }
            }
    }
}
#endif

/// Overlay for placing a photo at a tapped location on the PDF.
struct STPhotoPlacementOverlay: View {

    let onPlace: (_ screenPoint: CGPoint) -> Void
    let onCancel: () -> Void

    var body: some View {
        GeometryReader { _ in
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture { location in
                    onPlace(location)
                }
        }
        .overlay(alignment: .top) {
            HStack {
                Image(systemName: "hand.tap")
                Text(STStrings.tapToPlace)
            }
            .font(.callout.weight(.medium))
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.accentColor.opacity(0.85))
            .clipShape(Capsule())
            .padding(.top, 12)
        }
    }
}
