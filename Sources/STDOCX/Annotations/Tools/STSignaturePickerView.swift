import SwiftUI
import STKit

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
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // Draw New button
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

                    // Saved signatures section
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
            .navigationTitle(STStrings.toolSignature)
            .stNavigationBarTitleDisplayMode()
            .toolbar {
                ToolbarItem(placement: .stLeading) {
                    Button(STStrings.cancel) { onCancel() }
                }
            }
        }
    }

    @ViewBuilder
    private func signatureRow(_ sig: (id: String, image: PlatformImage)) -> some View {
        Button {
            onSignatureSelected(sig.image)
        } label: {
            ZStack(alignment: .topTrailing) {
                Image(platformImage: sig.image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity)
                    .frame(height: 70)
                    .padding(12)
                    .background(Color.gray.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                Button {
                    withAnimation {
                        STSignatureStorage.shared.delete(id: sig.id)
                        savedSignatures.removeAll { $0.id == sig.id }
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 22))
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, Color.gray.opacity(0.4))
                        .padding(6)
                }
            }
        }
    }
}
