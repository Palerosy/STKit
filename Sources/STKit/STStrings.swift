import Foundation

/// Type-safe localized strings for STKit core
public enum STStrings {
    // MARK: - Common
    public static var done: String { loc("stkit.done") }
    public static var cancel: String { loc("stkit.cancel") }
    public static var save: String { loc("stkit.save") }
    public static var share: String { loc("stkit.share") }
    public static var export: String { loc("stkit.export") }
    public static var delete: String { loc("stkit.delete") }
    public static var close: String { loc("stkit.close") }
    public static var untitled: String { loc("stkit.untitled") }
    public static var search: String { loc("stkit.search") }
    public static var undo: String { loc("stkit.undo") }
    public static var redo: String { loc("stkit.redo") }
    public static var add: String { loc("stkit.add") }

    // MARK: - License
    public static var unlicensed: String { loc("stkit.unlicensed") }

    // MARK: - Word Count
    public static var wordCount: String { loc("stkit.wordCount") }
    public static var words: String { loc("stkit.words") }
    public static var characters: String { loc("stkit.characters") }
    public static var charactersWithSpaces: String { loc("stkit.charactersWithSpaces") }
    public static var paragraphs: String { loc("stkit.paragraphs") }
    public static var lines: String { loc("stkit.lines") }

    // MARK: - Document
    public static var newDocument: String { loc("stkit.newDocument") }
    public static var unsavedChanges: String { loc("stkit.unsavedChanges") }
    public static var unsavedChangesMessage: String { loc("stkit.unsavedChangesMessage") }
    public static var discard: String { loc("stkit.discard") }
    public static var saveAndClose: String { loc("stkit.saveAndClose") }

    // MARK: - Navigation & Controls (Viewer)
    public static var pages: String { loc("stkit.pages") }
    public static var bookmark: String { loc("stkit.bookmark") }
    public static var settings: String { loc("stkit.settings") }
    public static var outline: String { loc("stkit.outline") }
    public static var editPages: String { loc("stkit.editPages") }
    public static var print: String { loc("stkit.print") }
    public static var saveAsText: String { loc("stkit.saveAsText") }

    // MARK: - Search & Replace
    public static var searchInDocument: String { loc("stkit.searchInDocument") }
    public static var searching: String { loc("stkit.searching") }
    public static var noResultsFound: String { loc("stkit.noResultsFound") }
    public static var replace: String { loc("stkit.replace") }
    public static var replaceWith: String { loc("stkit.replaceWith") }
    public static var replaceAll: String { loc("stkit.replaceAll") }
    public static var showReplace: String { loc("stkit.showReplace") }
    public static var hideReplace: String { loc("stkit.hideReplace") }
    public static func page(_ number: Int) -> String {
        String(format: loc("stkit.page"), number)
    }

    // MARK: - Outline
    public static var noOutlineAvailable: String { loc("stkit.noOutlineAvailable") }

    // MARK: - Settings
    public static var display: String { loc("stkit.display") }
    public static var scrollDirection: String { loc("stkit.scrollDirection") }
    public static var pageMode: String { loc("stkit.pageMode") }
    public static var view: String { loc("stkit.view") }
    public static var pageShadows: String { loc("stkit.pageShadows") }
    public static var backgroundColor: String { loc("stkit.backgroundColor") }

    // MARK: - Property Inspector
    public static var color: String { loc("stkit.color") }
    public static var width: String { loc("stkit.width") }
    public static var fontSize: String { loc("stkit.fontSize") }
    public static var opacity: String { loc("stkit.opacity") }
    public static var font: String { loc("stkit.font") }

    // MARK: - Annotation Tools
    public static var toolPen: String { loc("stkit.tool.pen") }
    public static var toolHighlighter: String { loc("stkit.tool.highlighter") }
    public static var toolText: String { loc("stkit.tool.text") }
    public static var toolHighlight: String { loc("stkit.tool.highlight") }
    public static var toolUnderline: String { loc("stkit.tool.underline") }
    public static var toolStrikethrough: String { loc("stkit.tool.strikethrough") }
    public static var toolRectangle: String { loc("stkit.tool.rectangle") }
    public static var toolCircle: String { loc("stkit.tool.circle") }
    public static var toolLine: String { loc("stkit.tool.line") }
    public static var toolArrow: String { loc("stkit.tool.arrow") }
    public static var toolSignature: String { loc("stkit.tool.signature") }
    public static var toolStamp: String { loc("stkit.tool.stamp") }
    public static var toolNote: String { loc("stkit.tool.note") }
    public static var toolEraser: String { loc("stkit.tool.eraser") }
    public static var toolPhoto: String { loc("stkit.tool.photo") }
    public static var toolTextEdit: String { loc("stkit.tool.textEdit") }
    public static var tapOnTextToEdit: String { loc("stkit.tapOnTextToEdit") }
    public static var selectionWord: String { loc("stkit.selection.word") }
    public static var selectionLine: String { loc("stkit.selection.line") }

    // MARK: - Toolbar Labels
    public static var hand: String { loc("stkit.hand") }
    public static var select: String { loc("stkit.select") }
    public static var style: String { loc("stkit.style") }
    public static var zoomIn: String { loc("stkit.zoomIn") }
    public static var zoomOut: String { loc("stkit.zoomOut") }
    public static var addText: String { loc("stkit.addText") }
    public static var removeText: String { loc("stkit.removeText") }

    // MARK: - Annotation Groups
    public static var groupDraw: String { loc("stkit.group.draw") }
    public static var groupShapes: String { loc("stkit.group.shapes") }
    public static var groupText: String { loc("stkit.group.text") }
    public static var groupMarkup: String { loc("stkit.group.markup") }
    public static var groupExtras: String { loc("stkit.group.extras") }

    // MARK: - Text Input
    public static var enterText: String { loc("stkit.enterText") }

    // MARK: - Markup
    public static func applyTool(_ toolName: String) -> String {
        String(format: loc("stkit.applyTool"), toolName)
    }

    // MARK: - Signature
    public static var signatureClear: String { loc("stkit.signature.clear") }
    public static var signatureDrawNew: String { loc("stkit.signature.drawNew") }
    public static var signatureSaved: String { loc("stkit.signature.saved") }

    // MARK: - Stamp Types
    public static var stampApproved: String { loc("stkit.stamp.approved") }
    public static var stampRejected: String { loc("stkit.stamp.rejected") }
    public static var stampDraft: String { loc("stkit.stamp.draft") }
    public static var stampConfidential: String { loc("stkit.stamp.confidential") }
    public static var stampForComment: String { loc("stkit.stamp.forComment") }
    public static var stampAsIs: String { loc("stkit.stamp.asIs") }
    public static var stampFinal: String { loc("stkit.stamp.final") }

    // MARK: - Placement
    public static var tapToPlace: String { loc("stkit.tapToPlace") }

    // MARK: - Selection Menu
    public static var selectionCopy: String { loc("stkit.selection.copy") }
    public static var selectionPaste: String { loc("stkit.selection.paste") }
    public static var selectionDelete: String { loc("stkit.selection.delete") }
    public static var selectionInspector: String { loc("stkit.selection.inspector") }
    public static var selectionNote: String { loc("stkit.selection.note") }

    // MARK: - Tool Hints
    public static var hintDraw: String { loc("stkit.hint.draw") }
    public static var hintShape: String { loc("stkit.hint.shape") }
    public static var hintTapToAddText: String { loc("stkit.hint.tapToAddText") }
    public static var hintErase: String { loc("stkit.hint.erase") }

    // MARK: - Order (Layer)
    public static var orderTitle: String { loc("stkit.order") }
    public static var orderFront: String { loc("stkit.order.front") }
    public static var orderForward: String { loc("stkit.order.forward") }
    public static var orderBackward: String { loc("stkit.order.backward") }
    public static var orderBack: String { loc("stkit.order.back") }

    // MARK: - Page Editor
    public static var pageNewPage: String { loc("stkit.page.newPage") }
    public static var pageRemove: String { loc("stkit.page.remove") }
    public static var pageDuplicate: String { loc("stkit.page.duplicate") }
    public static var pageRotate: String { loc("stkit.page.rotate") }
    public static var pageSelectAll: String { loc("stkit.page.selectAll") }
    public static var pageDeselectAll: String { loc("stkit.page.deselectAll") }
    public static var pageCut: String { loc("stkit.page.cut") }
    public static var pageCopy: String { loc("stkit.page.copy") }
    public static var pagePaste: String { loc("stkit.page.paste") }
    public static var pageNumberOfPages: String { loc("stkit.page.numberOfPages") }
    public static var pageFormat: String { loc("stkit.page.format") }
    public static var pageColor: String { loc("stkit.page.color") }
    public static var pageAddAfter: String { loc("stkit.page.addAfter") }
    public static var pageBeginning: String { loc("stkit.page.beginning") }
    public static var pageColorWhite: String { loc("stkit.page.color.white") }
    public static var pageColorCream: String { loc("stkit.page.color.cream") }
    public static var pageColorGray: String { loc("stkit.page.color.gray") }

    // MARK: - Ribbon Tabs
    public static var ribbonHome: String { loc("stkit.ribbon.home") }
    public static var ribbonInsert: String { loc("stkit.ribbon.insert") }
    public static var ribbonDraw: String { loc("stkit.ribbon.draw") }
    public static var ribbonDesign: String { loc("stkit.ribbon.design") }
    public static var ribbonLayout: String { loc("stkit.ribbon.layout") }
    public static var ribbonReview: String { loc("stkit.ribbon.review") }
    public static var ribbonView: String { loc("stkit.ribbon.view") }

    // MARK: - Ribbon Home Tab
    public static var ribbonBold: String { loc("stkit.ribbon.bold") }
    public static var ribbonItalic: String { loc("stkit.ribbon.italic") }
    public static var ribbonUnderline: String { loc("stkit.ribbon.underline") }
    public static var ribbonStrikethrough: String { loc("stkit.ribbon.strikethrough") }
    public static var ribbonFont: String { loc("stkit.ribbon.font") }
    public static var ribbonFontSize: String { loc("stkit.ribbon.fontSize") }
    public static var ribbonTextColor: String { loc("stkit.ribbon.textColor") }
    public static var ribbonHighlightColor: String { loc("stkit.ribbon.highlightColor") }
    public static var ribbonAlignLeft: String { loc("stkit.ribbon.alignLeft") }
    public static var ribbonAlignCenter: String { loc("stkit.ribbon.alignCenter") }
    public static var ribbonAlignRight: String { loc("stkit.ribbon.alignRight") }
    public static var ribbonJustify: String { loc("stkit.ribbon.justify") }
    public static var ribbonLineSpacing: String { loc("stkit.ribbon.lineSpacing") }

    // MARK: - Ribbon Insert Tab
    public static var ribbonImage: String { loc("stkit.ribbon.image") }
    public static var ribbonTable: String { loc("stkit.ribbon.table") }
    public static var ribbonShape: String { loc("stkit.ribbon.shape") }
    public static var ribbonPageNumber: String { loc("stkit.ribbon.pageNumber") }
    public static var ribbonFootnote: String { loc("stkit.ribbon.footnote") }
    public static var ribbonEndnote: String { loc("stkit.ribbon.endnote") }
    public static var ribbonTab: String { loc("stkit.ribbon.tab") }
    public static var ribbonLineBreak: String { loc("stkit.ribbon.lineBreak") }

    // MARK: - Ribbon Layout Tab
    public static var ribbonOrientation: String { loc("stkit.ribbon.orientation") }
    public static var ribbonPageSize: String { loc("stkit.ribbon.pageSize") }
    public static var ribbonMargins: String { loc("stkit.ribbon.margins") }
    public static var ribbonColumns: String { loc("stkit.ribbon.columns") }

    // MARK: - Ribbon Home Tab (additional)
    public static var ribbonPaste: String { loc("stkit.ribbon.paste") }
    public static var ribbonCopyFormat: String { loc("stkit.ribbon.copyFormat") }
    public static var ribbonSubscript: String { loc("stkit.ribbon.subscript") }
    public static var ribbonSuperscript: String { loc("stkit.ribbon.superscript") }
    public static var ribbonBulletList: String { loc("stkit.ribbon.bulletList") }
    public static var ribbonNumberedList: String { loc("stkit.ribbon.numberedList") }
    public static var ribbonIncreaseIndent: String { loc("stkit.ribbon.increaseIndent") }
    public static var ribbonDecreaseIndent: String { loc("stkit.ribbon.decreaseIndent") }
    public static var ribbonSelectAll: String { loc("stkit.ribbon.selectAll") }
    public static var ribbonEdit: String { loc("stkit.ribbon.edit") }

    // MARK: - Ribbon Insert Tab (shapes)
    public static var ribbonRectangle: String { loc("stkit.ribbon.rectangle") }
    public static var ribbonCircle: String { loc("stkit.ribbon.circle") }
    public static var ribbonLine: String { loc("stkit.ribbon.line") }
    public static var ribbonArrow: String { loc("stkit.ribbon.arrow") }

    // MARK: - Ribbon Insert Tab (additional)
    public static var ribbonPageBreak: String { loc("stkit.ribbon.pageBreak") }
    public static var ribbonTextBox: String { loc("stkit.ribbon.textBox") }
    public static var ribbonLink: String { loc("stkit.ribbon.link") }
    public static var ribbonBookmark: String { loc("stkit.ribbon.bookmark") }
    public static var ribbonSymbol: String { loc("stkit.ribbon.symbol") }
    public static var ribbonComment: String { loc("stkit.ribbon.comment") }
    public static var ribbonHeader: String { loc("stkit.ribbon.header") }
    public static var ribbonFooter: String { loc("stkit.ribbon.footer") }

    // MARK: - Ribbon Design Tab (additional)
    public static var ribbonThemes: String { loc("stkit.ribbon.themes") }
    public static var ribbonWatermark: String { loc("stkit.ribbon.watermark") }

    // MARK: - Ribbon Layout Tab (additional)
    public static var ribbonTextDirection: String { loc("stkit.ribbon.textDirection") }
    public static var ribbonSectionBreak: String { loc("stkit.ribbon.sectionBreak") }
    public static var ribbonPageBreaks: String { loc("stkit.ribbon.pageBreaks") }

    // MARK: - Ribbon Review Tab (additional)
    public static var ribbonTrackChanges: String { loc("stkit.ribbon.trackChanges") }
    public static var ribbonAcceptChange: String { loc("stkit.ribbon.acceptChange") }
    public static var ribbonRejectChange: String { loc("stkit.ribbon.rejectChange") }

    // MARK: - Ribbon Table Tab
    public static var ribbonAddRow: String { loc("stkit.ribbon.addRow") }
    public static var ribbonDeleteRow: String { loc("stkit.ribbon.deleteRow") }
    public static var ribbonAddColumn: String { loc("stkit.ribbon.addColumn") }
    public static var ribbonDeleteColumn: String { loc("stkit.ribbon.deleteColumn") }
    public static var ribbonCellColor: String { loc("stkit.ribbon.cellColor") }
    public static var ribbonBorderColor: String { loc("stkit.ribbon.borderColor") }
    public static var ribbonTableStyle: String { loc("stkit.ribbon.tableStyle") }
    public static var ribbonTableColor: String { loc("stkit.ribbon.tableColor") }
    public static var tableStyles: String { loc("stkit.tableStyles") }

    // MARK: - Ribbon Review Tab (comments)
    public static var ribbonComments: String { loc("stkit.ribbon.comments") }

    // MARK: - General
    public static var comingSoon: String { loc("stkit.comingSoon") }
    public static var custom: String { loc("stkit.custom") }

    // MARK: - Ribbon View Tab
    public static var ribbonZoom: String { loc("stkit.ribbon.zoom") }
    public static var ribbonThumbnails: String { loc("stkit.ribbon.thumbnails") }
    public static var ribbonOutline: String { loc("stkit.ribbon.outline") }
    public static var ribbonReadMode: String { loc("stkit.ribbon.readMode") }
    public static var ribbonEditMode: String { loc("stkit.ribbon.editMode") }
    public static var ribbonGoToTop: String { loc("stkit.ribbon.goToTop") }
    public static var ribbonGoToBottom: String { loc("stkit.ribbon.goToBottom") }
    public static var ribbonGoToPage: String { loc("stkit.ribbon.goToPage") }
    public static var ribbonBookmarks: String { loc("stkit.ribbon.bookmarks") }

    // MARK: - Helper
    public static func loc(_ key: String) -> String {
        NSLocalizedString(key, bundle: STKitBundleHelper.resourceBundle, comment: "")
    }
}

internal enum STKitBundleHelper {
    static let resourceBundle: Bundle = {
        let bundleName = "STKit_STKit"

        // 1. Standard SPM resource bundle in main app bundle
        if let url = Bundle.main.url(forResource: bundleName, withExtension: "bundle"),
           let bundle = Bundle(url: url) {
            return bundle
        }

        // 2. Inside framework in Frameworks directory (static xcframework)
        if let frameworksURL = Bundle.main.privateFrameworksURL {
            let url = frameworksURL.appendingPathComponent("STKit.framework/\(bundleName).bundle")
            if let bundle = Bundle(url: url) {
                return bundle
            }
        }

        // 3. Fallback to main bundle
        return Bundle.main
    }()
}
