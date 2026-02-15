import SwiftUI
import STKit

/// Word count sheet for the DOCX editor/viewer
public struct STDOCXWordCountView: View {
    let attributedText: NSAttributedString
    @Environment(\.dismiss) private var dismiss

    private var stats: [(String, String)] {
        let docStats = STDocumentStats(from: attributedText.string)
        return [
            (STStrings.words, "\(docStats.words)"),
            (STStrings.characters, "\(docStats.characters)"),
            (STStrings.charactersWithSpaces, "\(docStats.charactersWithSpaces)"),
            (STStrings.paragraphs, "\(docStats.paragraphs)"),
            (STStrings.lines, "\(docStats.lines)"),
        ]
    }

    public init(attributedText: NSAttributedString) {
        self.attributedText = attributedText
    }

    public var body: some View {
        NavigationView {
            List {
                ForEach(stats, id: \.0) { label, value in
                    HStack {
                        Text(label)
                            .font(.system(size: 15))
                        Spacer()
                        Text(value)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle(STStrings.wordCount)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(STStrings.done) { dismiss() }
                }
            }
        }
    }
}
