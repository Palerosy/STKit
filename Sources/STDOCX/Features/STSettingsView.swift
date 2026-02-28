import SwiftUI
import STKit

/// Editor settings panel — font size and background color
struct STSettingsView: View {

    @ObservedObject var webEditorViewModel: STWebEditorViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var fontSize: Double = 11
    @State private var selectedBackground: EditorBackground = .white

    enum EditorBackground: String, CaseIterable {
        case white, cream, dark

        var color: Color {
            switch self {
            case .white: return .white
            case .cream: return Color(red: 0.98, green: 0.96, blue: 0.90)
            case .dark: return Color(red: 0.15, green: 0.15, blue: 0.15)
            }
        }

        var hex: String {
            switch self {
            case .white: return "#FFFFFF"
            case .cream: return "#FAF5E6"
            case .dark: return "#262626"
            }
        }

        var label: String {
            switch self {
            case .white: return STStrings.pageColorWhite
            case .cream: return STStrings.pageColorCream
            case .dark: return STStrings.pageColorGray
            }
        }
    }

    var body: some View {
        #if os(macOS)
        macOSBody
        #else
        iOSBody
        #endif
    }

    private var settingsContent: some View {
        List {
            // Font Size
            Section(STStrings.fontSize) {
                VStack(spacing: 8) {
                    HStack {
                        Text("\(Int(fontSize))pt")
                            .font(.system(size: 15, weight: .semibold, design: .monospaced))
                            .frame(width: 44, alignment: .trailing)
                        Slider(value: $fontSize, in: 8...24, step: 1) {
                            Text(STStrings.fontSize)
                        }
                        .onChange(of: fontSize) { newSize in
                            webEditorViewModel.setEditorFontSize(Int(newSize))
                        }
                    }
                }
            }

            // Background Color
            Section(STStrings.backgroundColor) {
                ForEach(EditorBackground.allCases, id: \.rawValue) { bg in
                    Button {
                        selectedBackground = bg
                        webEditorViewModel.setEditorBackgroundColor(bg.hex)
                    } label: {
                        HStack {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(bg.color)
                                .frame(width: 32, height: 32)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                            Text(bg.label)
                                .foregroundColor(.primary)
                            Spacer()
                            if selectedBackground == bg {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.accentColor)
                                    .font(.system(size: 14, weight: .semibold))
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    #if os(macOS)
    private var macOSBody: some View {
        let sw = NSScreen.main?.frame.width ?? 1440
        return VStack(spacing: 0) {
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

            settingsContent
                .listStyle(.inset)
        }
        .frame(width: sw * 0.3)
    }
    #endif

    private var iOSBody: some View {
        NavigationView {
            settingsContent
                .navigationTitle(STStrings.settings)
                .stNavigationBarTitleDisplayMode()
                .toolbar {
                    ToolbarItem(placement: .stTrailing) {
                        Button(STStrings.done) { dismiss() }
                    }
                }
        }
    }
}
