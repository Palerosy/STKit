import SwiftUI
import STKit

/// Bottom editing bar shown when a FreeText annotation is selected.
/// Provides font name, font size, text color, and Done controls.
struct STFreeTextEditingBar: View {

    @ObservedObject var annotationManager: STAnnotationManager

    @State private var showFontPicker = false
    @State private var showColorPicker = false
    @State private var showSizePicker = false

    var body: some View {
        HStack(spacing: 0) {
            // Font name button
            Button {
                showFontPicker = true
            } label: {
                Text(displayFontName)
                    .font(.system(size: 14, weight: .medium))
                    .lineLimit(1)
                    .foregroundColor(.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.stTertiaryFill)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .popover(isPresented: $showFontPicker) {
                STFontPickerView(
                    selectedFontName: $annotationManager.activeStyle.fontName,
                    onDismiss: { showFontPicker = false }
                )
            }

            separator

            // Font size button
            Button {
                showSizePicker = true
            } label: {
                Text(String(format: "%.0fpt", annotationManager.activeStyle.fontSize))
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundColor(.primary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(Color.stTertiaryFill)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .popover(isPresented: $showSizePicker) {
                STFontSizePickerView(
                    fontSize: $annotationManager.activeStyle.fontSize,
                    onDismiss: { showSizePicker = false }
                )
            }

            separator

            // Color circle
            Button {
                showColorPicker = true
            } label: {
                Circle()
                    .fill(Color(platformColor: annotationManager.activeStyle.color))
                    .frame(width: 24, height: 24)
                    .overlay(
                        Circle()
                            .strokeBorder(Color.primary.opacity(0.2), lineWidth: 1)
                    )
            }
            .popover(isPresented: $showColorPicker) {
                STTextColorPickerView(
                    annotationManager: annotationManager,
                    onDismiss: { showColorPicker = false }
                )
            }

            Spacer()

            // Done button
            Button {
                annotationManager.clearAnnotationSelection()
            } label: {
                Text(STStrings.done)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.accentColor)
            }
            .padding(.trailing, 4)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.bar)
        .onChange(of: annotationManager.activeStyle) { _ in
            if annotationManager.selectedAnnotation?.type == "FreeText" {
                annotationManager.applyStyleToSelectedAnnotation()
            }
        }
    }

    private var displayFontName: String {
        let name = annotationManager.activeStyle.fontName
        // Show a friendly short name
        if name.hasPrefix("Helvetica") { return "Helvetica" }
        if name.hasPrefix("Avenir") { return "Avenir" }
        if name.hasPrefix("Futura") { return "Futura" }
        if name.hasPrefix("Georgia") { return "Georgia" }
        if name.hasPrefix("TimesNewRoman") || name.hasPrefix("Times") { return "Times New Roman" }
        if name.hasPrefix("MarkerFelt") || name.hasPrefix("Marker") { return "Marker Felt" }
        if name.hasPrefix("Noteworthy") { return "Noteworthy" }
        if name.hasPrefix("Courier") { return "Courier" }
        return name
    }

    private var separator: some View {
        Rectangle()
            .fill(.quaternary)
            .frame(width: 1, height: 24)
            .padding(.horizontal, 8)
    }
}

// MARK: - Font Picker

/// Popover view for selecting a font family.
struct STFontPickerView: View {

    @Binding var selectedFontName: String
    let onDismiss: () -> Void

    static let availableFonts: [(displayName: String, fontName: String)] = [
        ("Avenir", "Avenir-Book"),
        ("Courier", "Courier"),
        ("Futura", "Futura-Medium"),
        ("Georgia", "Georgia"),
        ("Helvetica", "Helvetica"),
        ("Marker Felt", "MarkerFelt-Thin"),
        ("Noteworthy", "Noteworthy-Light"),
        ("Times New Roman", "TimesNewRomanPSMT"),
    ]

    var body: some View {
        NavigationView {
            List {
                ForEach(Self.availableFonts, id: \.fontName) { font in
                    Button {
                        selectedFontName = font.fontName
                        onDismiss()
                    } label: {
                        HStack {
                            Text(font.displayName)
                                .font(.custom(font.fontName, size: 17))
                                .foregroundColor(.primary)

                            Spacer()

                            if isSelected(font.fontName) {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.accentColor)
                                    .fontWeight(.semibold)
                            }
                        }
                    }
                }
            }
            .navigationTitle(STStrings.font)
            .stNavigationBarTitleDisplayMode()
            .toolbar {
                ToolbarItem(placement: .stTrailing) {
                    Button(STStrings.done) { onDismiss() }
                }
            }
        }
        .frame(minWidth: 280, idealHeight: 400)
        .stPresentationDetents([.medium])
        .stPresentationDragIndicator(.visible)
    }

    private func isSelected(_ fontName: String) -> Bool {
        selectedFontName == fontName ||
        selectedFontName.hasPrefix(fontName.components(separatedBy: "-").first ?? fontName)
    }
}

// MARK: - Font Size Picker

/// Popover with a slider and preset sizes for font size selection.
struct STFontSizePickerView: View {

    @Binding var fontSize: CGFloat
    let onDismiss: () -> Void

    private let presetSizes: [CGFloat] = [8, 10, 12, 14, 16, 18, 20, 24, 28, 32, 36, 48, 64, 72]

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                // Current size display
                Text(String(format: "%.0f pt", fontSize))
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .padding(.top, 8)

                // Slider
                Slider(value: $fontSize, in: 8...72, step: 1)
                    .tint(.accentColor)
                    .padding(.horizontal, 16)

                // Preset grid
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                    ForEach(presetSizes, id: \.self) { size in
                        Button {
                            fontSize = size
                        } label: {
                            Text(String(format: "%.0f", size))
                                .font(.system(size: 14, weight: fontSize == size ? .bold : .regular))
                                .foregroundColor(fontSize == size ? .white : .primary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(fontSize == size ? Color.accentColor : Color.stTertiaryFill)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
                .padding(.horizontal, 16)

                Spacer()
            }
            .navigationTitle(STStrings.fontSize)
            .stNavigationBarTitleDisplayMode()
            .toolbar {
                ToolbarItem(placement: .stTrailing) {
                    Button(STStrings.done) { onDismiss() }
                }
            }
        }
        .frame(minWidth: 280, idealHeight: 380)
        .stPresentationDetents([.medium])
        .stPresentationDragIndicator(.visible)
    }
}

// MARK: - Text Color Picker

/// Popover for selecting text color with presets and opacity.
struct STTextColorPickerView: View {

    @ObservedObject var annotationManager: STAnnotationManager
    let onDismiss: () -> Void

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                // Color presets
                VStack(alignment: .leading, spacing: 8) {
                    Text(STStrings.color)
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.secondary)

                    LazyVGrid(columns: Array(repeating: GridItem(.fixed(36), spacing: 8), count: 6), spacing: 8) {
                        ForEach(Array(STAnnotationStyle.presetColors.enumerated()), id: \.offset) { _, color in
                            Circle()
                                .fill(Color(platformColor: color))
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Circle()
                                        .strokeBorder(
                                            annotationManager.activeStyle.color == color ? Color.primary : Color.clear,
                                            lineWidth: 2.5
                                        )
                                )
                                .overlay(
                                    // White border for visibility on white
                                    Circle()
                                        .strokeBorder(Color.primary.opacity(0.1), lineWidth: 0.5)
                                )
                                .onTapGesture {
                                    annotationManager.activeStyle.color = color
                                }
                        }
                    }
                }

                // Opacity
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(STStrings.opacity)
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(String(format: "%.0f%%", annotationManager.activeStyle.opacity * 100))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Slider(
                        value: $annotationManager.activeStyle.opacity,
                        in: 0.1...1.0,
                        step: 0.1
                    )
                    .tint(.accentColor)
                }

                Spacer()
            }
            .padding(16)
            .navigationTitle(STStrings.color)
            .stNavigationBarTitleDisplayMode()
            .toolbar {
                ToolbarItem(placement: .stTrailing) {
                    Button(STStrings.done) { onDismiss() }
                }
            }
        }
        .frame(minWidth: 280, idealHeight: 320)
        .stPresentationDetents([.medium])
        .stPresentationDragIndicator(.visible)
    }
}
