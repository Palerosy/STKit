import SwiftUI
import STKit

/// The main Excel editor view — drop-in SwiftUI component.
///
/// Usage:
/// ```swift
/// .fullScreenCover(isPresented: $showEditor) {
///     STExcelEditorView(url: xlsxURL) { savedURL in
///         print("Saved: \(savedURL)")
///     } onDismiss: {
///         showEditor = false
///     }
/// }
/// ```
public struct STExcelEditorView: View {

    private let url: URL?
    private let title: String?
    private let configuration: STExcelConfiguration
    private let onSave: ((URL) -> Void)?
    private let onDismiss: (() -> Void)?

    @State private var document: STExcelDocument?
    @State private var documentTitle = ""
    @State private var isSaving = false
    @State private var isExporting = false
    @State private var showShareSheet = false
    @State private var exportURL: URL?
    @State private var showSettings = false
    @State private var showFileInfo = false
    @State private var showCloseConfirmation = false
    @State private var showLicenseAlert = false
    @State private var showPremiumPaywall = false
    @State private var paywallPlacement = "main"
    @State private var loadFailed = false
    @State private var showRenameSheet = false
    @State private var renameSheetIndex = 0
    @State private var renameSheetText = ""
    @State private var sheetRefreshId = 0

    @StateObject private var editorViewModel = STExcelEditorViewModel()
    @StateObject private var ribbonViewModel = STExcelRibbonViewModel()

    /// Create an editor for an existing xlsx file
    public init(
        url: URL,
        title: String? = nil,
        configuration: STExcelConfiguration = .default,
        onSave: ((URL) -> Void)? = nil,
        onDismiss: (() -> Void)? = nil
    ) {
        self.url = url
        self.title = title
        self.configuration = configuration
        self.onSave = onSave
        self.onDismiss = onDismiss
    }

    /// Create an editor for a new blank spreadsheet
    public init(
        title: String = "Untitled",
        configuration: STExcelConfiguration = .default,
        onSave: ((URL) -> Void)? = nil,
        onDismiss: (() -> Void)? = nil
    ) {
        self.url = nil
        self.title = title
        self.configuration = configuration
        self.onSave = onSave
        self.onDismiss = onDismiss
    }

    public var body: some View {
        NavigationView {
            ZStack {
                if let doc = document {
                    VStack(spacing: 0) {
                        // Ribbon toolbar
                        if configuration.showRibbon && configuration.isEditable {
                            STExcelRibbonView(
                                ribbonViewModel: ribbonViewModel,
                                editorViewModel: editorViewModel
                            )
                        }

                        // Grid
                        STExcelGridView(
                            sheet: doc.activeSheet,
                            configuration: configuration,
                            isEditable: configuration.isEditable,
                            editorViewModel: editorViewModel,
                            ribbonViewModel: ribbonViewModel
                        )

                        // Sheet tabs
                        if configuration.showSheetTabs {
                            sheetTabs(doc)
                                .id(sheetRefreshId)
                        }
                    }

                    // License watermark
                    if !STExcelKit.isLicensed {
                        STLicenseWatermark(moduleName: "STExcel")
                    }
                } else if loadFailed {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 40))
                            .foregroundStyle(.secondary)
                        Text(STExcelStrings.failedToOpen)
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    ProgressView()
                }
            }
            .navigationTitle(documentTitle)
            .stNavigationBarTitleDisplayMode()
            .toolbar {
                ToolbarItem(placement: .stLeading) {
                    Button {
                        if editorViewModel.hasUnsavedChanges {
                            showCloseConfirmation = true
                        } else {
                            onDismiss?()
                        }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                }

                ToolbarItemGroup(placement: .stTrailing) {
                    if configuration.showMoreMenu {
                        if isExporting || isSaving {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Menu {
                                // Save
                                if configuration.showSaveButton {
                                    Button {
                                        licensedAction { saveDocument() }
                                    } label: {
                                        Label(STStrings.save, systemImage: "checkmark.circle")
                                    }
                                }

                                // Save As
                                Button {
                                    licensedAction { saveAsDocument() }
                                } label: {
                                    Label(STExcelStrings.saveAs, systemImage: "doc.badge.plus")
                                }

                                Divider()

                                // Export as XLSX
                                if configuration.showExport {
                                    Button {
                                        licensedAction { exportAsXLSX() }
                                    } label: {
                                        Label("XLSX", systemImage: "tablecells")
                                    }

                                    // Export as CSV
                                    Button {
                                        licensedAction { exportAsCSV() }
                                    } label: {
                                        Label("CSV", systemImage: "doc.text")
                                    }
                                }

                                // Print
                                Button {
                                    licensedAction { printDocument() }
                                } label: {
                                    Label(STStrings.print, systemImage: "printer")
                                }

                                Divider()

                                // Settings
                                Button {
                                    showSettings = true
                                } label: {
                                    Label(STStrings.settings, systemImage: "gear")
                                }

                                // File Info
                                Button {
                                    showFileInfo = true
                                } label: {
                                    Label(STExcelStrings.fileInfo, systemImage: "info.circle")
                                }
                            } label: {
                                Image(systemName: "ellipsis.circle")
                                    .font(.system(size: 18, weight: .medium))
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let shareURL = exportURL {
                    STShareSheet(activityItems: [shareURL])
                }
            }
            .sheet(isPresented: $showSettings) {
                STExcelSettingsView(
                    viewModel: editorViewModel,
                    onDismiss: { showSettings = false }
                )
                .stPresentationDetents([.height(380)])
            }
            .sheet(isPresented: $showFileInfo) {
                STExcelFileInfoView(
                    fileURL: url,
                    documentTitle: documentTitle,
                    sheetCount: document?.sheets.count ?? 0,
                    onDismiss: { showFileInfo = false }
                )
                .stPresentationDetents([.height(480)])
            }
            .alert(
                STExcelStrings.saveChangesTitle(documentTitle),
                isPresented: $showCloseConfirmation
            ) {
                Button(STExcelStrings.dontSave, role: .destructive) {
                    onDismiss?()
                }
                Button(STStrings.save) {
                    licensedAction({ saveAndClose() }, delay: 0.5)
                }
                Button(STStrings.cancel, role: .cancel) {}
            }
            .alert(STExcelStrings.licenseRequired, isPresented: $showLicenseAlert) {
                Button(STStrings.done, role: .cancel) {}
            } message: {
                Text(STExcelStrings.licenseRequiredMessage)
            }
            #if os(iOS)
            .fullScreenCover(isPresented: $showPremiumPaywall) {
                if let paywallView = STKitConfiguration.shared.premiumPaywallView {
                    paywallView(paywallPlacement)
                }
            }
            #endif
        }
        .onAppear {
            loadDocument()
        }
    }

    // MARK: - Sheet Tabs

    private func sheetTabs(_ doc: STExcelDocument) -> some View {
        HStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    ForEach(Array(doc.sheets.enumerated()), id: \.element.id) { index, sheet in
                        sheetTabButton(doc: doc, index: index, sheet: sheet)

                        if index < doc.sheets.count - 1 {
                            Rectangle()
                                .fill(Color.stSeparator)
                                .frame(width: 0.5, height: 20)
                        }
                    }
                }
                .padding(.leading, 8)
            }

            // Add sheet button
            if configuration.isEditable {
                Rectangle()
                    .fill(Color.stSeparator)
                    .frame(width: 0.5, height: 20)

                Button {
                    doc.addSheet()
                    doc.activeSheetIndex = doc.sheets.count - 1
                    editorViewModel.document = doc
                    syncSheetDimensions()
                    sheetRefreshId += 1
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(width: 44, height: 40)
                }
            }
        }
        .frame(height: 40)
        .background(Color.stSecondarySystemBackground)
        .overlay(alignment: .top) {
            Divider()
        }
        .alert(STExcelStrings.renameSheet, isPresented: $showRenameSheet) {
            TextField(STExcelStrings.sheetName, text: $renameSheetText)
            Button(STStrings.done) {
                let trimmed = renameSheetText.trimmingCharacters(in: .whitespaces)
                if !trimmed.isEmpty {
                    doc.renameSheet(at: renameSheetIndex, to: trimmed)
                    editorViewModel.document = doc
                    syncSheetDimensions()
                    sheetRefreshId += 1
                }
            }
            Button(STStrings.cancel, role: .cancel) {}
        }
    }

    private func sheetTabButton(doc: STExcelDocument, index: Int, sheet: STExcelSheet) -> some View {
        let isActive = index == doc.activeSheetIndex
        return Button {
            doc.activeSheetIndex = index
            editorViewModel.document = doc
            syncSheetDimensions()
            sheetRefreshId += 1
        } label: {
            Text(sheet.name)
                .font(.system(size: 13, weight: isActive ? .semibold : .regular))
                .foregroundColor(isActive ? .stExcelAccent : .secondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    isActive
                        ? Color.stExcelAccent.opacity(0.1)
                        : Color.clear
                )
                .overlay(alignment: .bottom) {
                    if isActive {
                        Rectangle()
                            .fill(Color.stExcelAccent)
                            .frame(height: 2)
                    }
                }
        }
        .contextMenu {
            if configuration.isEditable {
                Button {
                    renameSheetIndex = index
                    renameSheetText = sheet.name
                    showRenameSheet = true
                } label: {
                    Label(STExcelStrings.renameSheet, systemImage: "pencil")
                }

                Button {
                    doc.duplicateSheet(at: index)
                    doc.activeSheetIndex = index + 1
                    editorViewModel.document = doc
                    syncSheetDimensions()
                    sheetRefreshId += 1
                } label: {
                    Label(STExcelStrings.duplicateSheet, systemImage: "doc.on.doc")
                }

                if index > 0 {
                    Button {
                        doc.moveSheet(from: index, to: index - 1)
                        editorViewModel.document = doc
                        syncSheetDimensions()
                        sheetRefreshId += 1
                    } label: {
                        Label(STExcelStrings.moveSheetLeft, systemImage: "arrow.left")
                    }
                }

                if index < doc.sheets.count - 1 {
                    Button {
                        doc.moveSheet(from: index, to: index + 2)
                        editorViewModel.document = doc
                        syncSheetDimensions()
                        sheetRefreshId += 1
                    } label: {
                        Label(STExcelStrings.moveSheetRight, systemImage: "arrow.right")
                    }
                }

                if doc.sheets.count > 1 {
                    Divider()
                    Button(role: .destructive) {
                        doc.removeSheet(at: index)
                        editorViewModel.document = doc
                        syncSheetDimensions()
                        sheetRefreshId += 1
                    } label: {
                        Label(STExcelStrings.deleteSheet, systemImage: "trash")
                    }
                }
            }
        }
    }

    // MARK: - Load

    private func loadDocument() {
        if let url {
            documentTitle = title ?? url.deletingPathExtension().lastPathComponent
            if let doc = STExcelDocument(url: url, title: documentTitle) {
                document = doc
            } else {
                loadFailed = true
                return
            }
        } else {
            documentTitle = title ?? "Untitled"
            document = STExcelDocument(title: documentTitle)
        }
        editorViewModel.document = document
        syncSheetDimensions()

        if let tabs = configuration.ribbonTabs {
            ribbonViewModel.availableTabs = tabs
        }
    }

    /// Sync active sheet's row heights, column widths, images, shapes & frozen panes to the editor view model
    private func syncSheetDimensions() {
        guard let sheet = document?.activeSheet else { return }
        editorViewModel.rowHeights = sheet.rowHeights
        editorViewModel.columnWidths = sheet.columnWidths
        editorViewModel.images = sheet.images
        editorViewModel.shapes = sheet.shapes
        editorViewModel.frozenRows = sheet.frozenRows
        editorViewModel.frozenCols = sheet.frozenCols
        editorViewModel.charts = sheet.charts
        editorViewModel.tables = sheet.tables
        editorViewModel.conditionalRules = sheet.conditionalRules
        editorViewModel.isSheetProtected = sheet.isProtected
        editorViewModel.hiddenRows = sheet.hiddenRows
        editorViewModel.groupedRows = sheet.groupedRows
        editorViewModel.collapsedGroups = sheet.collapsedGroups
        // Sync data validations: sheet format → ViewModel format
        var vmRules: [String: STExcelEditorViewModel.ValidationRule] = [:]
        for (key, val) in sheet.dataValidations {
            vmRules[key] = STExcelEditorViewModel.ValidationRule(
                type: val.type, min: val.minValue, max: val.maxValue, list: val.listValues)
        }
        editorViewModel.validationRules = vmRules
        // Defined names (workbook level)
        if let doc = document {
            editorViewModel.definedNames = doc.definedNames
        }
    }

    // MARK: - Premium Gate

    private func licensedAction(_ action: @escaping () -> Void, delay: Double = 0.35) {
        if STKitConfiguration.shared.isPurchased {
            action()
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                if STKitConfiguration.shared.premiumPaywallView != nil {
                    paywallPlacement = configuration.paywallPlacement
                    showPremiumPaywall = true
                } else if let handler = STKitConfiguration.shared.onPremiumFeatureTapped {
                    handler()
                } else {
                    showLicenseAlert = true
                }
            }
        }
    }

    // MARK: - Save

    /// Sync editor view model state back to the document before saving
    private func syncViewModelToDocument() {
        guard let document else { return }
        let sheet = document.activeSheet
        sheet.columnWidths = editorViewModel.columnWidths
        sheet.rowHeights = editorViewModel.rowHeights
        sheet.images = editorViewModel.images
        sheet.shapes = editorViewModel.shapes
        sheet.frozenRows = editorViewModel.frozenRows
        sheet.frozenCols = editorViewModel.frozenCols
        sheet.charts = editorViewModel.charts
        sheet.tables = editorViewModel.tables
        sheet.conditionalRules = editorViewModel.conditionalRules
        sheet.isProtected = editorViewModel.isSheetProtected
        sheet.hiddenRows = editorViewModel.hiddenRows
        sheet.groupedRows = editorViewModel.groupedRows
        sheet.collapsedGroups = editorViewModel.collapsedGroups
        // Sync data validations: ViewModel format → sheet format
        var sheetValidations: [String: STExcelDataValidation] = [:]
        for (key, rule) in editorViewModel.validationRules {
            sheetValidations[key] = STExcelDataValidation(
                type: rule.type, minValue: rule.min, maxValue: rule.max, listValues: rule.list)
        }
        sheet.dataValidations = sheetValidations
        // Defined names (workbook level)
        document.definedNames = editorViewModel.definedNames
    }

    private func saveDocument() {
        guard let document else { return }
        if editorViewModel.isEditing { editorViewModel.commitEdit() }
        syncViewModelToDocument()
        isSaving = true

        DispatchQueue.global(qos: .userInitiated).async {
            let saveURL: URL
            if let originalURL = url {
                saveURL = originalURL
            } else {
                let saveName = documentTitle.isEmpty ? "Spreadsheet" : documentTitle
                saveURL = FileManager.default.temporaryDirectory
                    .appendingPathComponent("\(saveName).xlsx")
            }

            let success = document.save(to: saveURL)

            DispatchQueue.main.async {
                isSaving = false
                if success {
                    editorViewModel.hasUnsavedChanges = false
                    onSave?(saveURL)
                }
            }
        }
    }

    // MARK: - Save & Close

    private func saveAndClose() {
        guard let document else { return }
        if editorViewModel.isEditing { editorViewModel.commitEdit() }
        syncViewModelToDocument()
        isSaving = true
        DispatchQueue.global(qos: .userInitiated).async {
            let saveURL: URL
            if let originalURL = url {
                saveURL = originalURL
            } else {
                let saveName = documentTitle.isEmpty ? "Spreadsheet" : documentTitle
                saveURL = FileManager.default.temporaryDirectory
                    .appendingPathComponent("\(saveName).xlsx")
            }

            let success = document.save(to: saveURL)

            DispatchQueue.main.async {
                isSaving = false
                if success {
                    editorViewModel.hasUnsavedChanges = false
                    onSave?(saveURL)
                }
                onDismiss?()
            }
        }
    }

    // MARK: - Save As

    private func saveAsDocument() {
        guard let document else { return }
        if editorViewModel.isEditing { editorViewModel.commitEdit() }
        syncViewModelToDocument()
        isExporting = true
        DispatchQueue.global(qos: .userInitiated).async {
            let saveName = documentTitle.isEmpty ? "Spreadsheet" : documentTitle
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("\(saveName).xlsx")
            let success = document.save(to: tempURL)
            DispatchQueue.main.async {
                isExporting = false
                if success {
                    exportURL = tempURL
                    showShareSheet = true
                }
            }
        }
    }

    // MARK: - Export

    private func exportAsXLSX() {
        guard let document else { return }
        if editorViewModel.isEditing { editorViewModel.commitEdit() }
        syncViewModelToDocument()
        isExporting = true
        DispatchQueue.global(qos: .userInitiated).async {
            let saveName = documentTitle.isEmpty ? "Spreadsheet" : documentTitle
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("\(saveName).xlsx")
            let success = document.save(to: tempURL)
            DispatchQueue.main.async {
                isExporting = false
                if success {
                    exportURL = tempURL
                    showShareSheet = true
                }
            }
        }
    }

    private func exportAsCSV() {
        guard let document else { return }
        if editorViewModel.isEditing { editorViewModel.commitEdit() }
        isExporting = true
        DispatchQueue.global(qos: .userInitiated).async {
            let saveName = documentTitle.isEmpty ? "Spreadsheet" : documentTitle
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("\(saveName).csv")
            let success = document.exportAsCSV(to: tempURL)
            DispatchQueue.main.async {
                isExporting = false
                if success {
                    exportURL = tempURL
                    showShareSheet = true
                }
            }
        }
    }

    // MARK: - Print

    private func printDocument() {
        #if os(iOS)
        guard let document else { return }
        // Commit any active editing first
        if editorViewModel.isEditing {
            editorViewModel.commitEdit()
        }
        let sheet = document.activeSheet
        let charts = editorViewModel.charts
        let images = editorViewModel.images
        let shapes = editorViewModel.shapes
        let colWidths = editorViewModel.columnWidths
        let rowHeights = editorViewModel.rowHeights
        isExporting = true
        DispatchQueue.global(qos: .userInitiated).async {
            let pdfURL = Self.renderSheetToPDF(
                sheet: sheet, title: documentTitle,
                charts: charts, images: images, shapes: shapes,
                colWidths: colWidths, rowHeights: rowHeights,
                defaultColWidth: configuration.columnWidth,
                defaultRowHeight: configuration.rowHeight
            )
            DispatchQueue.main.async {
                isExporting = false
                guard let pdfURL else { return }
                let printController = UIPrintInteractionController.shared
                printController.printingItem = pdfURL
                let printInfo = UIPrintInfo(dictionary: nil)
                printInfo.outputType = .general
                printInfo.jobName = documentTitle.isEmpty ? "Spreadsheet" : documentTitle
                printController.printInfo = printInfo
                printController.present(animated: true)
            }
        }
        #endif
    }

    #if os(iOS)
    /// Render the active sheet to a PDF for printing — includes cells, formatting, charts, images, shapes
    private static func renderSheetToPDF(
        sheet: STExcelSheet, title: String,
        charts: [STExcelEmbeddedChart], images: [STExcelEmbeddedImage], shapes: [STExcelEmbeddedShape],
        colWidths: [Int: CGFloat], rowHeights: [Int: CGFloat],
        defaultColWidth: CGFloat, defaultRowHeight: CGFloat
    ) -> URL? {
        let pageWidth: CGFloat = 612   // US Letter
        let pageHeight: CGFloat = 792
        let margin: CGFloat = 36
        let cellPadding: CGFloat = 4
        let headerHeight: CGFloat = 20

        let colCount = sheet.columnCount
        let rowCount = sheet.rowCount

        // Build cumulative column X positions and row Y positions
        var colX = [CGFloat](repeating: 0, count: colCount + 1)
        for c in 0..<colCount {
            colX[c + 1] = colX[c] + (colWidths[c] ?? defaultColWidth)
        }
        var rowY = [CGFloat](repeating: 0, count: rowCount + 1)
        for r in 0..<rowCount {
            rowY[r + 1] = rowY[r] + (rowHeights[r] ?? defaultRowHeight)
        }
        let totalWidth = colX[colCount]
        let totalHeight = rowY[rowCount]

        // Scale to fit page width
        let usableWidth = pageWidth - margin * 2
        let scale = min(usableWidth / totalWidth, 1.0)
        let scaledRowHeight = { (r: Int) -> CGFloat in (rowHeights[r] ?? defaultRowHeight) * scale }
        let scaledColWidth = { (c: Int) -> CGFloat in (colWidths[c] ?? defaultColWidth) * scale }

        // Calculate rows per page
        let usableHeight = pageHeight - margin * 2 - headerHeight
        var pages: [(startRow: Int, endRow: Int)] = []
        var currentRow = 0
        while currentRow < rowCount {
            var pageH: CGFloat = 0
            var endRow = currentRow
            while endRow < rowCount && pageH + scaledRowHeight(endRow) <= usableHeight {
                pageH += scaledRowHeight(endRow)
                endRow += 1
            }
            if endRow == currentRow { endRow += 1 } // at least one row per page
            pages.append((currentRow, endRow))
            currentRow = endRow
        }

        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(title).pdf")
        UIGraphicsBeginPDFContextToFile(url.path, .zero, nil)

        let headerFont = UIFont.boldSystemFont(ofSize: 8 * scale)

        for page in pages {
            UIGraphicsBeginPDFPage()

            // Column headers
            var cx: CGFloat = margin
            for c in 0..<colCount {
                let w = scaledColWidth(c)
                let headerRect = CGRect(x: cx, y: margin, width: w, height: headerHeight)
                UIColor(white: 0.95, alpha: 1).setFill()
                UIBezierPath(rect: headerRect).fill()
                let letter = STExcelSheet.columnLetter(c)
                let hp = NSMutableParagraphStyle()
                hp.alignment = .center; hp.lineBreakMode = .byTruncatingTail
                (letter as NSString).draw(in: headerRect.insetBy(dx: 2, dy: 3),
                    withAttributes: [.font: headerFont, .foregroundColor: UIColor.darkGray, .paragraphStyle: hp])
                UIColor.lightGray.setStroke()
                UIBezierPath(rect: headerRect).stroke()
                cx += w
            }

            // Data rows
            var ry: CGFloat = margin + headerHeight
            for r in page.startRow..<page.endRow {
                let rh = scaledRowHeight(r)
                var rx: CGFloat = margin
                for c in 0..<colCount {
                    let cw = scaledColWidth(c)
                    let cellRect = CGRect(x: rx, y: ry, width: cw, height: rh)
                    let cell = sheet.cell(row: r, column: c)
                    let style = cell.style

                    // Fill color
                    if let hex = style.fillColor, let fill = uiColorFromHex(hex) {
                        fill.setFill()
                        UIBezierPath(rect: cellRect).fill()
                    }

                    // Text (prefer cached value from xlsx, evaluate only if empty)
                    let rawText: String
                    if !cell.value.isEmpty {
                        rawText = cell.value
                    } else if let formula = cell.formula {
                        rawText = STExcelFormulaEngine.evaluate(formula, in: sheet)
                    } else {
                        rawText = cell.value
                    }
                    let text = STExcelGridView.formatForPrint(rawText, style: style)

                    let fontSize = max(6, CGFloat(style.fontSize > 0 ? style.fontSize : 11) * scale)
                    let drawFont: UIFont
                    if style.isBold && style.isItalic {
                        drawFont = UIFont(descriptor: UIFont.systemFont(ofSize: fontSize).fontDescriptor.withSymbolicTraits([.traitBold, .traitItalic])!, size: fontSize)
                    } else if style.isBold {
                        drawFont = UIFont.boldSystemFont(ofSize: fontSize)
                    } else if style.isItalic {
                        drawFont = UIFont.italicSystemFont(ofSize: fontSize)
                    } else {
                        drawFont = UIFont.systemFont(ofSize: fontSize)
                    }

                    let textColor: UIColor = style.textColor.flatMap { uiColorFromHex($0) } ?? .black

                    let para = NSMutableParagraphStyle()
                    para.lineBreakMode = .byTruncatingTail
                    switch style.horizontalAlignment {
                    case .center: para.alignment = .center
                    case .right: para.alignment = .right
                    default: para.alignment = .left
                    }

                    if style.isUnderline {
                        (text as NSString).draw(in: cellRect.insetBy(dx: cellPadding * scale, dy: 2 * scale),
                            withAttributes: [.font: drawFont, .foregroundColor: textColor,
                                            .paragraphStyle: para, .underlineStyle: NSUnderlineStyle.single.rawValue])
                    } else if style.isStrikethrough {
                        (text as NSString).draw(in: cellRect.insetBy(dx: cellPadding * scale, dy: 2 * scale),
                            withAttributes: [.font: drawFont, .foregroundColor: textColor,
                                            .paragraphStyle: para, .strikethroughStyle: NSUnderlineStyle.single.rawValue])
                    } else {
                        (text as NSString).draw(in: cellRect.insetBy(dx: cellPadding * scale, dy: 2 * scale),
                            withAttributes: [.font: drawFont, .foregroundColor: textColor, .paragraphStyle: para])
                    }

                    // Grid line
                    UIColor(white: 0.85, alpha: 1).setStroke()
                    UIBezierPath(rect: cellRect).stroke()
                    rx += cw
                }
                ry += rh
            }

            // Overlays: images, charts, shapes — draw if they fall within this page's row range
            let pageTopY = rowY[page.startRow]
            let pageBottomY = rowY[page.endRow]

            // Images
            for img in images {
                if img.y + img.height < pageTopY || img.y > pageBottomY { continue }
                let dx = img.x * scale + margin
                let dy = (img.y - pageTopY) * scale + margin + headerHeight
                let dw = img.width * scale
                let dh = img.height * scale
                if let uiImage = UIImage(data: img.imageData) {
                    uiImage.draw(in: CGRect(x: dx, y: dy, width: dw, height: dh))
                }
            }

            // Charts — render as a placeholder box with title
            for chart in charts {
                if chart.y + chart.height < pageTopY || chart.y > pageBottomY { continue }
                let dx = chart.x * scale + margin
                let dy = (chart.y - pageTopY) * scale + margin + headerHeight
                let dw = chart.width * scale
                let dh = chart.height * scale
                let chartRect = CGRect(x: dx, y: dy, width: dw, height: dh)
                UIColor.white.setFill()
                UIBezierPath(rect: chartRect).fill()
                UIColor.gray.setStroke()
                UIBezierPath(rect: chartRect).stroke()
                let chartPara = NSMutableParagraphStyle()
                chartPara.alignment = .center
                let chartTitle = chart.title.isEmpty ? "Chart" : chart.title
                (chartTitle as NSString).draw(in: chartRect.insetBy(dx: 4, dy: dh / 2 - 8),
                    withAttributes: [.font: UIFont.systemFont(ofSize: 10 * scale),
                                    .foregroundColor: UIColor.darkGray, .paragraphStyle: chartPara])
            }

            // Shapes — render basic shape with fill
            for shape in shapes {
                if shape.y + shape.height < pageTopY || shape.y > pageBottomY { continue }
                let dx = shape.x * scale + margin
                let dy = (shape.y - pageTopY) * scale + margin + headerHeight
                let dw = shape.width * scale
                let dh = shape.height * scale
                let shapeRect = CGRect(x: dx, y: dy, width: dw, height: dh)
                let fillColor = UIColor(shape.fillColor)
                let strokeColor = UIColor(shape.strokeColor)
                fillColor.setFill()
                strokeColor.setStroke()
                switch shape.shapeType {
                case .circle, .oval:
                    let path = UIBezierPath(ovalIn: shapeRect)
                    path.fill(); path.stroke()
                case .line, .dashedLine:
                    let path = UIBezierPath()
                    path.move(to: CGPoint(x: shapeRect.minX, y: shapeRect.midY))
                    path.addLine(to: CGPoint(x: shapeRect.maxX, y: shapeRect.midY))
                    path.lineWidth = CGFloat(shape.strokeWidth)
                    if shape.shapeType == .dashedLine {
                        path.setLineDash([6, 4], count: 2, phase: 0)
                    }
                    path.stroke()
                case .triangle, .rightTriangle:
                    let path = UIBezierPath()
                    path.move(to: CGPoint(x: shapeRect.midX, y: shapeRect.minY))
                    path.addLine(to: CGPoint(x: shapeRect.maxX, y: shapeRect.maxY))
                    path.addLine(to: CGPoint(x: shapeRect.minX, y: shapeRect.maxY))
                    path.close()
                    path.fill(); path.stroke()
                case .diamond:
                    let path = UIBezierPath()
                    path.move(to: CGPoint(x: shapeRect.midX, y: shapeRect.minY))
                    path.addLine(to: CGPoint(x: shapeRect.maxX, y: shapeRect.midY))
                    path.addLine(to: CGPoint(x: shapeRect.midX, y: shapeRect.maxY))
                    path.addLine(to: CGPoint(x: shapeRect.minX, y: shapeRect.midY))
                    path.close()
                    path.fill(); path.stroke()
                case .arrowRight, .arrowLeft, .arrowUp, .arrowDown:
                    let path = UIBezierPath()
                    path.move(to: CGPoint(x: shapeRect.minX, y: shapeRect.midY))
                    path.addLine(to: CGPoint(x: shapeRect.maxX, y: shapeRect.midY))
                    path.lineWidth = CGFloat(shape.strokeWidth)
                    path.stroke()
                    let ah = UIBezierPath()
                    ah.move(to: CGPoint(x: shapeRect.maxX, y: shapeRect.midY))
                    ah.addLine(to: CGPoint(x: shapeRect.maxX - 8, y: shapeRect.midY - 4))
                    ah.addLine(to: CGPoint(x: shapeRect.maxX - 8, y: shapeRect.midY + 4))
                    ah.close()
                    strokeColor.setFill(); ah.fill()
                case .roundedRectangle:
                    let path = UIBezierPath(roundedRect: shapeRect, cornerRadius: 8)
                    path.fill(); path.stroke()
                default:
                    let path = UIBezierPath(rect: shapeRect)
                    path.fill(); path.stroke()
                }
                // Shape text
                if !shape.text.isEmpty {
                    let sp = NSMutableParagraphStyle()
                    sp.alignment = .center; sp.lineBreakMode = .byTruncatingTail
                    (shape.text as NSString).draw(in: shapeRect.insetBy(dx: 4, dy: dh / 2 - 8),
                        withAttributes: [.font: UIFont.systemFont(ofSize: 10 * scale),
                                        .foregroundColor: UIColor(shape.strokeColor), .paragraphStyle: sp])
                }
            }
        }

        UIGraphicsEndPDFContext()
        return url
    }

    private static func uiColorFromHex(_ hex: String) -> UIColor? {
        let clean = hex.trimmingCharacters(in: .init(charactersIn: "#"))
        guard clean.count == 6, let val = UInt64(clean, radix: 16) else { return nil }
        let r = CGFloat((val >> 16) & 0xFF) / 255
        let g = CGFloat((val >> 8) & 0xFF) / 255
        let b = CGFloat(val & 0xFF) / 255
        return UIColor(red: r, green: g, blue: b, alpha: 1)
    }
    #endif
}
