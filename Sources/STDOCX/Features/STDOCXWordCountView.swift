import SwiftUI
import STKit

/// Word count sheet for DOCX editor — extracts text from WKWebView
struct STDOCXWordCountView: View {
    @ObservedObject var webEditorViewModel: STWebEditorViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var stats: STDocumentStats?
    @State private var isLoading = true

    var body: some View {
        #if os(macOS)
        macOSBody
        #else
        iOSBody
        #endif
    }

    #if os(macOS)
    private var macOSBody: some View {
        let sw = NSScreen.main?.frame.width ?? 1440
        return VStack(spacing: 0) {
            HStack {
                Text(STStrings.wordCount)
                    .font(.headline)
                Spacer()
                Button(STStrings.done) { dismiss() }
                    .buttonStyle(.plain)
                    .foregroundColor(.accentColor)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            Divider()

            if isLoading {
                VStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .frame(height: 200)
            } else if let stats {
                VStack(spacing: 0) {
                    statRow(STStrings.words, "\(stats.words)")
                        .padding(.vertical, 10)
                    Divider()
                    statRow(STStrings.characters, "\(stats.characters)")
                        .padding(.vertical, 10)
                    Divider()
                    statRow(STStrings.charactersWithSpaces, "\(stats.charactersWithSpaces)")
                        .padding(.vertical, 10)
                    Divider()
                    statRow(STStrings.paragraphs, "\(stats.paragraphs)")
                        .padding(.vertical, 10)
                    Divider()
                    statRow(STStrings.lines, "\(stats.lines)")
                        .padding(.vertical, 10)
                }
                .padding(.horizontal, 16)
            }
        }
        .frame(width: sw * 0.3)
        .task {
            let text = await webEditorViewModel.getTextContent()
            stats = STDocumentStats(from: text)
            isLoading = false
        }
    }
    #endif

    private var iOSBody: some View {
        NavigationView {
            Group {
                if isLoading {
                    VStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                } else if let stats {
                    List {
                        statRow(STStrings.words, "\(stats.words)")
                        statRow(STStrings.characters, "\(stats.characters)")
                        statRow(STStrings.charactersWithSpaces, "\(stats.charactersWithSpaces)")
                        statRow(STStrings.paragraphs, "\(stats.paragraphs)")
                        statRow(STStrings.lines, "\(stats.lines)")
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
        .task {
            let text = await webEditorViewModel.getTextContent()
            stats = STDocumentStats(from: text)
            isLoading = false
        }
    }

    @ViewBuilder
    private func statRow(_ label: String, _ value: String) -> some View {
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
