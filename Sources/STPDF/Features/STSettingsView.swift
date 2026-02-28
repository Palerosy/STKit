import STKit
import SwiftUI

/// Viewer settings panel
struct STSettingsView: View {

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        #if os(macOS)
        VStack(spacing: 0) {
            HStack {
                Text(STStrings.settings)
                    .font(.headline)
                Spacer()
                Button(STStrings.done) { dismiss() }
                    .buttonStyle(.plain)
                    .foregroundColor(.accentColor)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            Divider()

            List {
                Section(STStrings.display) {
                    Label(STStrings.scrollDirection, systemImage: "arrow.up.arrow.down")
                    Label(STStrings.pageMode, systemImage: "doc.on.doc")
                }

                Section(STStrings.view) {
                    Label(STStrings.pageShadows, systemImage: "shadow")
                    Label(STStrings.backgroundColor, systemImage: "paintpalette")
                }
            }
        }
        .frame(width: 400)
        #else
        STNavigationView {
            List {
                Section(STStrings.display) {
                    Label(STStrings.scrollDirection, systemImage: "arrow.up.arrow.down")
                    Label(STStrings.pageMode, systemImage: "doc.on.doc")
                }

                Section(STStrings.view) {
                    Label(STStrings.pageShadows, systemImage: "shadow")
                    Label(STStrings.backgroundColor, systemImage: "paintpalette")
                }
            }
            .navigationTitle(STStrings.settings)
            .stNavigationBarTitleDisplayMode()
            .toolbar {
                ToolbarItem(placement: .stTrailing) {
                    Button(STStrings.done) { dismiss() }
                }
            }
        }
        #endif
    }
}
