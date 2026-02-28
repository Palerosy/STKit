import SwiftUI
import STKit

/// Word count sheet for plain text
public struct STTXTWordCountView: View {
    let text: String
    @Environment(\.dismiss) private var dismiss

    private var stats: [(String, String)] {
        let docStats = STDocumentStats(from: text)
        return [
            (STStrings.words, "\(docStats.words)"),
            (STStrings.characters, "\(docStats.characters)"),
            (STStrings.charactersWithSpaces, "\(docStats.charactersWithSpaces)"),
            (STStrings.paragraphs, "\(docStats.paragraphs)"),
            (STStrings.lines, "\(docStats.lines)"),
        ]
    }

    public init(text: String) {
        self.text = text
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
            .stNavigationBarTitleDisplayMode()
            .toolbar {
                ToolbarItem(placement: .stTrailing) {
                    Button(STStrings.done) { dismiss() }
                }
            }
        }
    }
}
