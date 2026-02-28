import STKit
import SwiftUI

/// Signature picker — shows saved signatures and a "Draw New" option.
/// If no saved signatures exist, goes directly to the capture view.
struct STSignaturePickerView: View {

    let strokeColor: PlatformColor
    let strokeWidth: CGFloat
    let onSignatureSelected: (_ image: PlatformImage) -> Void
    let onCancel: () -> Void

    @State private var savedSignatures: [(id: String, image: PlatformImage)] = []
    @State private var isDrawing = false
    @State private var hasLoaded = false

    var body: some View {
        Group {
            if !hasLoaded {
                Color.clear
            } else if isDrawing || savedSignatures.isEmpty {
                captureView
            } else {
                pickerContent
            }
        }
        .onAppear {
            guard !hasLoaded else { return }
            savedSignatures = STSignatureStorage.shared.loadAll()
            hasLoaded = true
        }
    }

    // MARK: - Capture View

    private var captureView: some View {
        STSignatureCaptureView(
            strokeColor: strokeColor,
            strokeWidth: strokeWidth,
            onSave: { image in
                STSignatureStorage.shared.save(image)
                onSignatureSelected(image)
            },
            onCancel: {
                if savedSignatures.isEmpty {
                    onCancel()
                } else {
                    isDrawing = false
                }
            }
        )
    }

    // MARK: - Picker Content

    private var pickerContent: some View {
        #if os(macOS)
        return VStack(spacing: 0) {
            // Header
            HStack {
                Button(STStrings.cancel) { onCancel() }
                    .buttonStyle(.plain)
                    .foregroundColor(.accentColor)
                Spacer()
                Text(STStrings.toolSignature)
                    .font(.headline)
                Spacer()
                Color.clear.frame(width: 50)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            Divider()

            // Content
            VStack(spacing: 12) {
                // Draw New
                Button {
                    isDrawing = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "pencil.line")
                            .font(.system(size: 16))
                        Text(STStrings.signatureDrawNew)
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(.accentColor)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.accentColor.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(Color.accentColor.opacity(0.25),
                                          style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                    )
                }
                .buttonStyle(.plain)

                // Saved signatures
                if !savedSignatures.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(STStrings.signatureSaved)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)

                        ForEach(savedSignatures, id: \.id) { sig in
                            signatureRow(sig)
                        }
                    }
                }
            }
            .padding(16)
        }
        .frame(width: (NSScreen.main?.frame.width ?? 1440) * 0.35)
        #else
        let scrollContent = ScrollView {
            VStack(spacing: 16) {
                Button {
                    isDrawing = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "pencil.line")
                            .font(.system(size: 20))
                        Text(STStrings.signatureDrawNew)
                            .font(.body.weight(.medium))
                    }
                    .foregroundColor(.accentColor)
                    .frame(maxWidth: .infinity)
                    .frame(height: 80)
                    .background(Color.accentColor.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(Color.accentColor.opacity(0.3),
                                          style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                    )
                }

                if !savedSignatures.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(STStrings.signatureSaved)
                            .font(.footnote.weight(.medium))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 4)

                        ForEach(savedSignatures, id: \.id) { sig in
                            signatureRow(sig)
                        }
                    }
                }
            }
            .padding(16)
        }
        return STNavigationView {
            scrollContent
                .navigationTitle(STStrings.toolSignature)
                .stNavigationBarTitleDisplayMode()
                .toolbar {
                    ToolbarItem(placement: .stLeading) {
                        Button(STStrings.cancel) { onCancel() }
                    }
                }
        }
        #endif
    }

    @ViewBuilder
    private func signatureRow(_ sig: (id: String, image: PlatformImage)) -> some View {
        #if os(macOS)
        let imgHeight: CGFloat = 50
        let pad: CGFloat = 8
        let corner: CGFloat = 6
        let xSize: CGFloat = 18
        #else
        let imgHeight: CGFloat = 70
        let pad: CGFloat = 12
        let corner: CGFloat = 12
        let xSize: CGFloat = 22
        #endif
        Button {
            onSignatureSelected(sig.image)
        } label: {
            ZStack(alignment: .topTrailing) {
                Image(platformImage: sig.image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity)
                    .frame(height: imgHeight)
                    .padding(pad)
                    .background(Color.gray.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: corner))

                Button {
                    withAnimation {
                        STSignatureStorage.shared.delete(id: sig.id)
                        savedSignatures.removeAll { $0.id == sig.id }
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: xSize))
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, Color.gray.opacity(0.4))
                        .padding(4)
                }
            }
        }
        .buttonStyle(.plain)
    }
}
