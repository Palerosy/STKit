import SwiftUI
import STKit

/// Color picker sheet for the DOCX editor
public struct STDOCXColorPicker: View {
    @ObservedObject var editorState: STDOCXEditorState
    @Environment(\.dismiss) private var dismiss

    private let colors: [(String, UIColor)] = [
        ("Black", .label),
        ("Red", .systemRed),
        ("Blue", .systemBlue),
        ("Green", .systemGreen),
        ("Orange", .systemOrange),
        ("Purple", .systemPurple),
        ("Teal", .systemTeal),
        ("Pink", .systemPink),
        ("Brown", .brown),
        ("Gray", .systemGray),
        ("Indigo", .systemIndigo),
        ("Yellow", .systemYellow),
    ]

    public init(editorState: STDOCXEditorState) {
        self.editorState = editorState
    }

    public var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                Text(STDOCXStrings.textColor)
                    .font(.system(size: 17, weight: .semibold))
                    .padding(.top, 16)

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 6), spacing: 16) {
                    ForEach(colors, id: \.0) { _, color in
                        Button {
                            editorState.setTextColor(color)
                            dismiss()
                        } label: {
                            Circle()
                                .fill(Color(color))
                                .frame(width: 44, height: 44)
                                .overlay(
                                    Circle()
                                        .strokeBorder(Color(.separator), lineWidth: 1)
                                )
                                .overlay {
                                    if editorState.currentTextColor == color {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(.white)
                                    }
                                }
                        }
                    }
                }
                .padding(.horizontal, 24)

                Spacer()
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(STStrings.done) { dismiss() }
                }
            }
        }
    }
}
