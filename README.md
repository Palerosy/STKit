<p align="center">
  <h1 align="center">STKit</h1>
  <p align="center"><strong>SwiftUI-native Document SDK for iOS</strong></p>
  <p align="center">A unified, modular framework for viewing, editing, and converting documents on iOS.</p>
</p>

<p align="center">
  <a href="https://swift.org"><img src="https://img.shields.io/badge/Swift-5.9-orange.svg" alt="Swift"></a>
  <a href="https://developer.apple.com/ios/"><img src="https://img.shields.io/badge/Platform-iOS%2016%2B-blue.svg" alt="Platform"></a>
  <a href="#license"><img src="https://img.shields.io/badge/License-Commercial-green.svg" alt="License"></a>
  <a href="https://github.com/Palerosy/STKit/releases"><img src="https://img.shields.io/badge/Version-0.1.0-brightgreen.svg" alt="Version"></a>
</p>

---

STKit provides drop-in SwiftUI components for working with multiple document formats. Built with a modular architecture, you only import what you need.

## Modules

| Module | Formats | Description | Status |
|--------|---------|-------------|--------|
| **STDOCX** | `.docx` `.doc` `.rtf` `.txt` | Rich text document editor & viewer | Available |
| **STExcel** | `.xlsx` `.csv` | Spreadsheet grid viewer & editor | Available |
| **STTXT** | `.txt` | Plain text editor & viewer | Available |
| **STPDF** | `.pdf` | PDF viewer & annotation editor | Coming Soon |

---

## Requirements

- iOS 16.0+
- Xcode 15.0+
- Swift 5.9+

---

## Installation

### Swift Package Manager

Add STKit to your project via Xcode:

1. Go to **File > Add Package Dependencies...**
2. Enter the repository URL:
   ```
   https://github.com/Palerosy/STKit.git
   ```
3. Select the modules you need
4. Click **Add Package**

Or add it to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/Palerosy/STKit.git", from: "0.1.0"),
],
targets: [
    .target(
        name: "YourApp",
        dependencies: [
            .product(name: "STKit", package: "STKit"),
            .product(name: "STDOCX", package: "STKit"),
            .product(name: "STExcel", package: "STKit"),
            .product(name: "STTXT", package: "STKit"),
        ]
    ),
]
```

---

## Quick Start

### 1. Initialize with License Key

```swift
import STKit

@main
struct MyApp: App {
    init() {
        STKit.initialize(licenseKey: "YOUR_LICENSE_KEY")
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

> **No license key?** STKit works without a license in trial mode — a watermark overlay will appear on all views. Contact **info@loopmobile.io** to get your license key.

### 2. Open Any Document

```swift
import STDOCX
import STExcel
import STTXT

// DOCX Editor — full rich text editing
STDOCXEditorView(url: docxURL) { savedURL in
    print("Saved: \(savedURL)")
} onDismiss: {
    showEditor = false
}

// Excel Editor — spreadsheet with grid
STExcelEditorView(url: xlsxURL) { savedURL in
    print("Saved: \(savedURL)")
} onDismiss: {
    showEditor = false
}

// Plain Text Editor
STTXTEditorView(url: txtURL) { savedURL in
    print("Saved: \(savedURL)")
} onDismiss: {
    showEditor = false
}
```

That's it — drop-in document editing in 3 lines of SwiftUI.

---

## STDOCX — Word Documents

### Editor

`STDOCXEditorView` provides a complete rich text editing experience for DOCX files.

```swift
import STDOCX

// Open an existing DOCX file
STDOCXEditorView(
    url: docxURL,
    title: "My Document",
    configuration: .default,
    onSave: { savedURL in
        print("Saved: \(savedURL)")
    },
    onDismiss: {
        showEditor = false
    }
)

// Create a new blank document
STDOCXEditorView(
    title: "Untitled",
    onSave: { savedURL in
        print("New document saved: \(savedURL)")
    },
    onDismiss: {
        showEditor = false
    }
)
```

#### Features

- **Rich Text Formatting**: Bold, italic, underline, strikethrough
- **Font Selection**: 16 built-in fonts with live preview
- **Font Size**: Adjustable from 8pt to 128pt
- **Text Color**: 12 preset colors with visual picker
- **Text Alignment**: Left, center, right, justified
- **Undo / Redo**: Full undo/redo support
- **Word Count**: Words, characters, paragraphs, lines
- **Export**: Save as DOCX, PDF, or TXT
- **Unsaved Changes Alert**: Prompts user before discarding changes

### Viewer

```swift
// Read-only viewer (no formatting toolbar, no save button)
STDOCXViewerView(url: docxURL, title: "Preview") {
    showViewer = false
}
```

### Configuration

```swift
var config = STDOCXConfiguration()
config.isEditable = true                    // false = read-only mode
config.defaultFontName = "Georgia"          // Default font for new documents
config.defaultFontSize = 16                 // Default font size
config.showFormattingToolbar = true          // Show/hide formatting bar
config.showWordCount = true                 // Word count in menu
config.showExport = true                    // Export options in menu
config.appearance.accentColor = .blue       // Active button tint
config.appearance.backgroundColor = .white  // Editor background

STDOCXEditorView(url: docxURL, configuration: config)
```

### Document Model

```swift
let document = STDOCXDocument(url: docxURL)
let stats = document?.stats

print("Words: \(stats?.words ?? 0)")
print("Characters: \(stats?.characters ?? 0)")

document?.save(to: outputURL)
document?.exportAsPDF(to: pdfURL)
document?.exportAsText(to: txtURL)
```

### Converter

```swift
// Read any supported file as NSAttributedString
let attrString = STDOCXConverter.readFile(at: fileURL)

// Convert between NSAttributedString and DOCX
let document = STDOCXConverter.toDocument(attrString)
let displayString = STDOCXConverter.toAttributedString(document)
```

### Supported Formats

| Format | Read | Write | Export |
|--------|------|-------|--------|
| .docx  | Yes  | Yes   | Yes    |
| .doc   | Yes  | No    | -      |
| .txt   | Yes  | No    | Yes    |
| .rtf   | Yes  | No    | -      |
| .pdf   | -    | -     | Yes    |

---

## STExcel — Spreadsheets

### Editor

`STExcelEditorView` provides a spreadsheet grid with cell editing, sheet tabs, and export.

```swift
import STExcel

// Open an existing xlsx file
STExcelEditorView(url: xlsxURL, title: "Sales Data") { savedURL in
    print("Saved: \(savedURL)")
} onDismiss: {
    showEditor = false
}

// Create a new blank spreadsheet
STExcelEditorView(title: "New Sheet") { savedURL in
    print("Saved: \(savedURL)")
} onDismiss: {
    showEditor = false
}
```

#### Features

- **Spreadsheet Grid**: Scrollable rows and columns with headers (A, B, C... / 1, 2, 3...)
- **Cell Editing**: Tap to select, edit cell values inline
- **Cell Value Bar**: Shows selected cell reference and value
- **Sheet Tabs**: Switch between multiple sheets in a workbook
- **XLSX Read/Write**: Full .xlsx file support (ZIP + XML)
- **Export**: Save as XLSX or CSV
- **Numeric Detection**: Right-aligns numeric values automatically

### Viewer

```swift
// Read-only spreadsheet viewer
STExcelViewerView(url: xlsxURL) {
    showViewer = false
}
```

### Configuration

```swift
var config = STExcelConfiguration()
config.isEditable = true
config.columnWidth = 120                   // Default column width
config.rowHeight = 44                      // Default row height
config.showSheetTabs = true                // Show sheet tab bar
config.selectionColor = .blue              // Selected cell highlight
config.gridLineColor = Color(.separator)   // Grid line color

STExcelEditorView(url: xlsxURL, configuration: config)
```

### Document Model

```swift
let document = STExcelDocument(url: xlsxURL)

// Access sheets
print("Sheets: \(document?.sheets.count ?? 0)")
print("Active: \(document?.activeSheet.name ?? "")")

// Read cell values
let value = document?.activeSheet.cell(row: 0, column: 0).value

// Edit cells
document?.activeSheet.setCell(row: 0, column: 0, value: "Hello")

// Save / Export
document?.save(to: outputURL)          // .xlsx
document?.exportAsCSV(to: csvURL)      // .csv
```

### Supported Formats

| Format | Read | Write | Export |
|--------|------|-------|--------|
| .xlsx  | Yes  | Yes   | Yes    |
| .csv   | -    | -     | Yes    |

---

## STTXT — Plain Text

### Editor

`STTXTEditorView` provides a clean plain text editing experience with a monospaced font.

```swift
import STTXT

// Open an existing text file
STTXTEditorView(url: txtURL) { savedURL in
    print("Saved: \(savedURL)")
} onDismiss: {
    showEditor = false
}

// Create a new text document
STTXTEditorView(title: "Notes") { savedURL in
    print("Saved: \(savedURL)")
} onDismiss: {
    showEditor = false
}
```

#### Features

- **Plain Text Editing**: Clean, distraction-free text editor
- **Monospaced Font**: Menlo font by default (configurable)
- **Word Count**: Words, characters, paragraphs, lines
- **Unsaved Changes Alert**: Prompts before discarding changes
- **Save**: Export as .txt file

### Viewer

```swift
// Read-only text viewer
STTXTViewerView(url: txtURL) {
    showViewer = false
}
```

### Configuration

```swift
var config = STTXTConfiguration()
config.isEditable = true
config.fontName = "Menlo"                   // Monospaced font
config.fontSize = 14                        // Font size
config.textColor = .primary                 // Text color
config.backgroundColor = Color(.systemBackground)

STTXTEditorView(url: txtURL, configuration: config)
```

---

## STKit Core

The core module provides shared functionality used by all format modules.

### License Management

```swift
import STKit

// Initialize with license key
STKit.initialize(licenseKey: "YOUR_LICENSE_KEY")

// Check license status
if STKit.isLicensed {
    print("Plan: \(STKit.licensePlan?.rawValue ?? "none")")
    print("Expiry: \(STKit.licenseExpiry?.description ?? "none")")
    print("Features: \(STKit.licensedFeatures)")
}

// Check specific module license
if STKit.isFeatureLicensed("docx") {
    // DOCX module unlocked
}

if STKit.isFeatureLicensed("excel") {
    // Excel module unlocked
}
```

### License Plans

| Plan | Features | Description |
|------|----------|-------------|
| **Free / Trial** | All modules (with watermark) | Full functionality, watermark overlay on views |
| **Pro** | Selected modules | Specific format modules, no watermark |
| **Enterprise** | All modules | Full access to all current and future modules |

### Document Protocol

All document types conform to `STDocument`:

```swift
public protocol STDocument {
    var sourceURL: URL? { get }
    var title: String { get }
    var plainText: String { get }
    var wordCount: Int { get }
    var characterCount: Int { get }
}
```

---

## Localization

STKit includes built-in localization for:

- English (en)
- Turkish (tr)

More languages coming soon. All UI strings are automatically localized based on the user's device language.

---

## Architecture

```
STKit/
├── Sources/
│   ├── STKit/                  -> Core module
│   │   ├── License/            -> Ed25519 license validation & watermark
│   │   ├── Core/               -> Shared protocols, models & components
│   │   └── Resources/          -> Localization files
│   │
│   ├── STDOCX/                 -> DOCX module (14 files)
│   │   ├── Core/               -> Document model & converter
│   │   ├── Editor/             -> Rich text editor (UITextView-based)
│   │   ├── Viewer/             -> Read-only viewer
│   │   ├── Toolbar/            -> Formatting toolbar
│   │   ├── Features/           -> Font/color picker, word count, export
│   │   └── Configuration/      -> Editor settings
│   │
│   ├── STExcel/                -> Excel module (10 files)
│   │   ├── Core/               -> XLSX reader/writer (ZIP + XML)
│   │   ├── Editor/             -> Spreadsheet editor
│   │   ├── Viewer/             -> Grid viewer with headers
│   │   ├── Features/           -> Export (XLSX, CSV)
│   │   └── Configuration/      -> Grid settings
│   │
│   ├── STTXT/                  -> TXT module (7 files)
│   │   ├── Core/               -> Plain text document model
│   │   ├── Editor/             -> Text editor (UITextView-based)
│   │   ├── Viewer/             -> Read-only viewer
│   │   ├── Features/           -> Word count
│   │   └── Configuration/      -> Editor settings
│   │
│   └── STPDF/                  -> PDF module (coming soon)
│
├── Tests/
│   ├── STKitTests/
│   ├── STDOCXTests/
│   ├── STExcelTests/
│   └── STTXTTests/
│
└── Packages/
    └── SwiftDocX/              -> Vendored DOCX dependency
```

---

## License

STKit is a **commercial SDK**. A valid license key is required to remove the watermark overlay from views.

### Getting a License Key

Contact us to purchase a license:

**Email:** info@loopmobile.io

### License Key Format

License keys are Base64-encoded, signed with Ed25519, and tied to your app's bundle ID. Each key contains:

- **Bundle ID**: Your app's bundle identifier (or `*` for wildcard)
- **Plan**: `free`, `pro`, or `enterprise`
- **Expiry**: License expiration date
- **Features**: Array of licensed modules (e.g., `["docx", "excel", "txt"]`)

### Trial Mode

STKit works without a license key in trial mode:
- All features are fully functional
- A semi-transparent watermark appears on views
- Perfect for evaluation and development

---

## FAQ

### Can I use STKit without a license key?
Yes. STKit runs in trial mode without a license key. All features work, but a watermark overlay appears on views.

### Does STKit require an internet connection?
No. License validation is performed entirely offline using cryptographic signature verification. No network calls are made.

### Can I use specific modules only?
Yes. Import only the modules you need:
```swift
import STDOCX   // Only DOCX support
import STExcel  // Only Excel support
import STTXT    // Only TXT support
```
The core `STKit` module is automatically included as a dependency.

### What iOS versions are supported?
iOS 16.0 and later.

### How do I migrate from STPDFKit?
STPDFKit and STKit are separate packages. You can use both in the same project without conflicts. When the STPDF module is released, migration will be seamless with the same API patterns.

---

## Support

- **Email:** info@loopmobile.io
- **Issues:** [GitHub Issues](https://github.com/Palerosy/STKit/issues)

---

<p align="center">Made with Swift by <a href="mailto:info@loopmobile.io">Loop Mobile</a></p>
