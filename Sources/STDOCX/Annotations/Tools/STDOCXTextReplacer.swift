import Foundation
import PDFKit
import Compression

/// Direct PDF content stream text replacement.
/// Parses the PDF binary, finds text operators in the content stream,
/// and replaces/removes text without annotation overlays.
enum STDOCXTextReplacer {

    /// Unicode scalar → glyph ID bytes (reverse ToUnicode mapping)
    typealias FontMap = [UInt32: Data]

    // MARK: - Public API

    /// Replace text directly in the PDF content stream.
    /// - Returns: The original PDFPage (for undo restore), or nil if CSP failed
    static func replaceText(
        in document: PDFDocument,
        pageIndex: Int,
        oldText: String,
        newText: String,
        occurrenceIndex: Int = 0,
        targetBounds: CGRect? = nil
    ) -> PDFPage? {
        guard pageIndex >= 0, pageIndex < document.pageCount else { return nil }
        guard let cgDoc = document.documentRef else { return nil }
        guard let cgPage = cgDoc.page(at: pageIndex + 1) else { return nil }
        guard let pageDict = cgPage.dictionary else { return nil }

        // 1. Extract decompressed content streams via CGPDF (reliable decompression)
        let contentStreams = extractContentStreams(from: pageDict)
        guard !contentStreams.isEmpty else { return nil }

        // 2. Extract font names actually used in the content streams
        let fontNames = extractFontNamesFromStreams(contentStreams)

        // 3. Build font encoding maps (ToUnicode CMap) for discovered fonts
        let fontMaps = extractFontMaps(from: pageDict, fontNames: fontNames)

        // 4. Try replacement on each content stream to verify text can be found
        var modifiedStream: Data?
        var matchedStreamContent: Data?   // The CGPDF stream where the match was found
        for stream in contentStreams {
            if let modified = replaceTextInOperators(
                stream, oldText: oldText, newText: newText, fontMaps: fontMaps,
                occurrenceIndex: occurrenceIndex, targetBounds: targetBounds
            ) {
                modifiedStream = modified
                matchedStreamContent = stream
                break
            }
        }
        guard modifiedStream != nil else { return nil }

        // 5. Get raw PDF data and do the actual stream patching
        guard let pdfData = document.dataRepresentation() else { return nil }

        guard let newPDFData = patchPDFStream(
            pdfData: pdfData,
            oldText: oldText,
            newText: newText,
            fontMaps: fontMaps,
            targetStreamContent: matchedStreamContent,
            occurrenceIndex: occurrenceIndex,
            targetBounds: targetBounds
        ) else { return nil }

        // 6. Load modified PDF
        guard let loadedDoc = PDFDocument(data: newPDFData) else { return nil }
        guard let newPage = loadedDoc.page(at: pageIndex) else { return nil }

        let originalPage = document.page(at: pageIndex)
        document.removePage(at: pageIndex)
        document.insert(newPage, at: pageIndex)

        return originalPage
    }

    // MARK: - Content Stream Extraction (via CGPDF)

    private static func extractContentStreams(from dict: CGPDFDictionaryRef) -> [Data] {
        var result: [Data] = []

        var streamRef: CGPDFStreamRef?
        if CGPDFDictionaryGetStream(dict, "Contents", &streamRef), let stream = streamRef {
            var format: CGPDFDataFormat = .raw
            if let data = CGPDFStreamCopyData(stream, &format) as Data? {
                result.append(data)
            }
            return result
        }

        var arrayRef: CGPDFArrayRef?
        if CGPDFDictionaryGetArray(dict, "Contents", &arrayRef), let array = arrayRef {
            for i in 0..<CGPDFArrayGetCount(array) {
                var s: CGPDFStreamRef?
                if CGPDFArrayGetStream(array, i, &s), let stream = s {
                    var format: CGPDFDataFormat = .raw
                    if let data = CGPDFStreamCopyData(stream, &format) as Data? {
                        result.append(data)
                    }
                }
            }
        }

        return result
    }

    // MARK: - Font Name Extraction

    /// Parse content streams for /FontName size Tf operators to discover font names.
    private static func extractFontNamesFromStreams(_ streams: [Data]) -> [String] {
        var names = Set<String>()
        guard let pattern = try? NSRegularExpression(pattern: #"/(\w+)\s+[\d.]+\s+Tf"#) else { return [] }

        for stream in streams {
            guard let str = String(data: stream, encoding: .isoLatin1) else { continue }
            let nsStr = str as NSString
            let matches = pattern.matches(in: str, range: NSRange(location: 0, length: nsStr.length))
            for match in matches {
                names.insert(nsStr.substring(with: match.range(at: 1)))
            }
        }
        return Array(names)
    }

    // MARK: - Font Map Extraction

    /// Extract ToUnicode CMaps for the given font names from page resources.
    /// Also enumerates ALL fonts in the resource dictionary (to capture
    /// font names that CGPDF may have remapped, e.g. Ty2 → TT2).
    private static func extractFontMaps(
        from pageDict: CGPDFDictionaryRef,
        fontNames: [String]
    ) -> [String: FontMap] {
        var result: [String: FontMap] = [:]

        var resourcesRef: CGPDFDictionaryRef?
        guard CGPDFDictionaryGetDictionary(pageDict, "Resources", &resourcesRef),
              let resources = resourcesRef else { return result }

        var fontDictRef: CGPDFDictionaryRef?
        guard CGPDFDictionaryGetDictionary(resources, "Font", &fontDictRef),
              let fontDict = fontDictRef else { return result }

        // First: look up fonts by stream-extracted names (CGPDF names)
        for fontName in fontNames {
            var fontRef: CGPDFDictionaryRef?
            if CGPDFDictionaryGetDictionary(fontDict, fontName, &fontRef),
               let font = fontRef {
                if let map = parseToUnicodeCMap(from: font) {
                    result[fontName] = map
                }
            }
        }

        // Second: enumerate ALL fonts in the resource dictionary
        // This captures the actual PDF font names (e.g. Ty2, Ty4)
        // which may differ from the CGPDF-remapped names (TT2, TT4)
        CGPDFDictionaryApplyBlock(fontDict, { key, value, _ in
            let fontName = String(cString: key)
            if result[fontName] == nil { // skip if already found
                var fontRef: CGPDFDictionaryRef?
                if CGPDFDictionaryGetDictionary(fontDict, fontName, &fontRef),
                   let font = fontRef {
                    if let map = parseToUnicodeCMap(from: font) {
                        result[fontName] = map
                    }
                }
            }
            return true
        }, nil)

        return result
    }

    // MARK: - Raw PDF Stream Patching (Same-Size)

    /// Scan ALL streams in the raw PDF data. For each content stream,
    /// decompress it, try text replacement, and patch in-place if successful.
    ///
    /// Uses **same-size patching**: the recompressed stream is padded to the
    /// exact original compressed size. This means no byte offsets shift,
    /// so the existing xref table/stream stays valid — no xref repair needed.
    /// The zlib decompressor is self-terminating and ignores trailing padding.
    private static func patchPDFStream(
        pdfData: Data,
        oldText: String,
        newText: String,
        fontMaps: [String: FontMap],
        targetStreamContent: Data? = nil,
        occurrenceIndex: Int = 0,
        targetBounds: CGRect? = nil
    ) -> Data? {
        // Two-pass approach:
        // Pass 1: With stream targeting — only patch the exact CGPDF-matched stream
        // Pass 2: Without targeting — fall back if content streams are in object streams
        if targetStreamContent != nil {
            if let result = patchPDFStreamPass(
                pdfData: pdfData, oldText: oldText, newText: newText,
                fontMaps: fontMaps, targetStreamContent: targetStreamContent,
                occurrenceIndex: occurrenceIndex, targetBounds: targetBounds
            ) {
                return result
            }
        }

        return patchPDFStreamPass(
            pdfData: pdfData, oldText: oldText, newText: newText,
            fontMaps: fontMaps, targetStreamContent: nil,
            occurrenceIndex: occurrenceIndex, targetBounds: targetBounds
        )
    }

    /// Single pass of stream scanning with optional targeting.
    private static func patchPDFStreamPass(
        pdfData: Data,
        oldText: String,
        newText: String,
        fontMaps: [String: FontMap],
        targetStreamContent: Data?,
        occurrenceIndex: Int = 0,
        targetBounds: CGRect? = nil
    ) -> Data? {
        var data = pdfData
        let streamToken = Data("stream".utf8)
        let endstreamToken = Data("endstream".utf8)

        var streamCount = 0
        var offset = 0
        while offset < data.count - streamToken.count {
            guard let streamPos = findBytes(streamToken, in: data, from: offset) else { break }

            // Skip "endstream"
            if streamPos >= 3 {
                let prefix = Data(data[(streamPos - 3)..<streamPos])
                if prefix == Data("end".utf8) {
                    offset = streamPos + streamToken.count
                    continue
                }
            }

            var dataStart = streamPos + streamToken.count
            if dataStart < data.count && data[dataStart] == 0x0D { dataStart += 1 }
            if dataStart < data.count && data[dataStart] == 0x0A { dataStart += 1 }

            guard let endstreamPos = findBytes(endstreamToken, in: data, from: dataStart) else { break }

            var dataEnd = endstreamPos
            if dataEnd > dataStart && data[dataEnd - 1] == 0x0A { dataEnd -= 1 }
            if dataEnd > dataStart && data[dataEnd - 1] == 0x0D { dataEnd -= 1 }

            let streamBytes = Data(data[dataStart..<dataEnd])
            let originalStreamSize = dataEnd - dataStart
            streamCount += 1

            // Decompress (or use raw if not compressed)
            let decompressed = zlibDecompress(streamBytes) ?? streamBytes
            let wasCompressed = (decompressed != streamBytes)

            // If targeting, skip raw streams that don't match the CGPDF stream.
            if let target = targetStreamContent {
                let sizeDiff = abs(decompressed.count - target.count)
                if sizeDiff > 50 {
                    offset = endstreamPos + endstreamToken.count
                    continue
                }
                let rawNorm = decompressed.prefix(200).filter { $0 != 0x0D }
                let targetNorm = target.prefix(200).filter { $0 != 0x0D }
                let prefixLen = min(100, min(rawNorm.count, targetNorm.count))
                let prefixMatch = prefixLen > 0 && rawNorm.prefix(prefixLen) == targetNorm.prefix(prefixLen)
                if !prefixMatch {
                    offset = endstreamPos + endstreamToken.count
                    continue
                }
            }

            // Only try replacement on content streams
            guard let streamStr = String(data: decompressed, encoding: .isoLatin1),
                  looksLikeContentStream(streamStr) else {
                offset = endstreamPos + endstreamToken.count
                continue
            }

            // Try text replacement on this decompressed stream
            if let modified = replaceTextInOperators(
                decompressed, oldText: oldText, newText: newText, fontMaps: fontMaps,
                occurrenceIndex: occurrenceIndex, targetBounds: targetBounds
            ) {
                // Recompress if originally compressed
                let patchData: Data
                if wasCompressed {
                    guard let recompressed = zlibCompress(modified) else { return nil }
                    patchData = recompressed
                } else {
                    patchData = modified
                }

                guard patchData.count <= originalStreamSize else { return nil }

                // Pad to original stream size → no byte offset shift → xref stays valid
                var paddedPatch = patchData
                let paddingNeeded = originalStreamSize - paddedPatch.count
                if paddingNeeded > 0 {
                    paddedPatch.append(Data(count: paddingNeeded))
                }

                // Replace in-place (same size → existing xref untouched)
                data.replaceSubrange(dataStart..<dataEnd, with: paddedPatch)
                return data
            }

            offset = endstreamPos + endstreamToken.count
        }

        return nil
    }

    // MARK: - Text Replacement in Operators

    private static func replaceTextInOperators(
        _ data: Data,
        oldText: String,
        newText: String,
        fontMaps: [String: FontMap],
        occurrenceIndex: Int = 0,
        targetBounds: CGRect? = nil
    ) -> Data? {
        guard var stream = String(data: data, encoding: .isoLatin1) else { return nil }

        // Trim whitespace — PDFSelection.string often includes trailing spaces
        let trimmedOld = oldText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedOld.isEmpty else { return nil }

        let escape = { (s: String) -> String in
            s.replacingOccurrences(of: "\\", with: "\\\\")
             .replacingOccurrences(of: "(", with: "\\(")
             .replacingOccurrences(of: ")", with: "\\)")
        }

        let escapedOld = escape(trimmedOld)
        let escapedNew = escape(newText)
        var found = false

        // Pattern 1: (text) Tj — exact standalone string
        let tjOld = "(\(escapedOld)) Tj"
        if stream.contains(tjOld) {
            found = replaceNthOccurrence(of: tjOld, with: "(\(escapedNew)) Tj", in: &stream, n: occurrenceIndex)
        }

        // Pattern 2: (text) '
        if !found {
            let quoteOld = "(\(escapedOld)) '"
            if stream.contains(quoteOld) {
                found = replaceNthOccurrence(of: quoteOld, with: "(\(escapedNew)) '", in: &stream, n: occurrenceIndex)
            }
        }

        // Pattern 3: Simple parenthesized text (exact match)
        if !found {
            let parenOld = "(\(escapedOld))"
            if stream.contains(parenOld) {
                found = replaceNthOccurrence(of: parenOld, with: "(\(escapedNew))", in: &stream, n: occurrenceIndex)
            }
        }

        // Pattern 4: TJ arrays with parenthesized strings (exact concat match)
        if !found {
            found = replaceTJArrayText(&stream, oldText: trimmedOld, newText: newText, escape: escape, occurrenceIndex: occurrenceIndex)
        }

        // Pattern 5: Hex-encoded strings (ASCII 1-byte)
        if !found {
            found = replaceHexText(&stream, oldText: trimmedOld, newText: newText, occurrenceIndex: occurrenceIndex)
        }

        // Pattern 6: UTF-16BE hex strings (CIDFont / Identity-H)
        if !found {
            found = replaceHexTextUTF16BE(&stream, oldText: trimmedOld, newText: newText, occurrenceIndex: occurrenceIndex)
        }

        // Pattern 7: TJ arrays with hex strings
        if !found {
            found = replaceHexTJArray(&stream, oldText: trimmedOld, newText: newText, fontMaps: fontMaps, occurrenceIndex: occurrenceIndex)
        }

        // Pattern 8: Font-aware encoding via ToUnicode CMap
        if !found && !fontMaps.isEmpty {
            found = replaceUsingFontMaps(&stream, oldText: trimmedOld, newText: newText, fontMaps: fontMaps, occurrenceIndex: occurrenceIndex)
        }

        // Pattern 9: Font-aware TJ arrays
        if !found && !fontMaps.isEmpty {
            found = replaceFontEncodedTJArray(&stream, oldText: trimmedOld, newText: newText, fontMaps: fontMaps, occurrenceIndex: occurrenceIndex)
        }

        // Pattern 12: Character-by-character (x) Tj across BT/ET blocks (PowerPoint PDFs)
        if !found {
            found = replaceCharByCharTj(&stream, oldText: trimmedOld, newText: newText, fontMaps: fontMaps, occurrenceIndex: occurrenceIndex, targetBounds: targetBounds)
        }

        // Pattern 10: Substring within a larger parenthesized string
        if !found {
            found = replaceSubstringInParenText(&stream, oldText: trimmedOld, newText: newText, escape: escape, occurrenceIndex: occurrenceIndex)
        }

        // Pattern 11: Substring within TJ array concatenation
        if !found {
            found = replaceSubstringInTJArray(&stream, oldText: trimmedOld, newText: newText, escape: escape, occurrenceIndex: occurrenceIndex)
        }

        // Pattern 13: Position-based removal (ultimate fallback for line deletion).
        // Only for deletion (newText empty) when targetBounds is provided.
        // Blanks ALL text operators whose Tm position falls within targetBounds.
        if !found, newText.isEmpty, let bounds = targetBounds {
            found = removeTextByPosition(&stream, targetBounds: bounds)
        }

        guard found else { return nil }
        return stream.data(using: .isoLatin1)
    }

    /// Replace only the Nth occurrence (0-indexed) of `target` in `string`.
    private static func replaceNthOccurrence(
        of target: String,
        with replacement: String,
        in string: inout String,
        n: Int
    ) -> Bool {
        var count = 0
        var searchStart = string.startIndex
        while let range = string.range(of: target, range: searchStart..<string.endIndex) {
            if count == n {
                string.replaceSubrange(range, with: replacement)
                return true
            }
            count += 1
            searchStart = range.upperBound
        }
        return false
    }

    // MARK: - Pattern Matchers

    /// TJ arrays with parenthesized strings: [(text1) kern (text2)] TJ
    private static func replaceTJArrayText(
        _ stream: inout String,
        oldText: String,
        newText: String,
        escape: (String) -> String,
        occurrenceIndex: Int = 0
    ) -> Bool {
        guard let regex = try? NSRegularExpression(
            pattern: #"\[([^\]]*)\]\s*TJ"#, options: []
        ) else { return false }

        let nsStream = stream as NSString
        let matches = regex.matches(in: stream, range: NSRange(location: 0, length: nsStream.length))

        var matchCount = 0
        for match in matches {
            let arrayContent = nsStream.substring(with: match.range(at: 1))
            let textParts = extractParenTextFromTJArray(arrayContent)
            let concatenated = textParts.joined()

            if concatenated == oldText ||
               concatenated.trimmingCharacters(in: .whitespaces) == oldText {
                if matchCount == occurrenceIndex {
                    let escapedNew = escape(newText)
                    let replacement = newText.isEmpty ? "() Tj" : "(\(escapedNew)) Tj"
                    stream = (stream as NSString).replacingCharacters(in: match.range, with: replacement)
                    return true
                }
                matchCount += 1
            }
        }

        return false
    }

    /// ASCII hex: <48656C6C6F> Tj
    private static func replaceHexText(
        _ stream: inout String,
        oldText: String,
        newText: String,
        occurrenceIndex: Int = 0
    ) -> Bool {
        let hexOld = oldText.unicodeScalars.map { String(format: "%02X", $0.value) }.joined()
        let hexNew = newText.unicodeScalars.map { String(format: "%02X", $0.value) }.joined()

        if stream.contains("<\(hexOld)>") {
            return replaceNthOccurrence(of: "<\(hexOld)>", with: "<\(hexNew)>", in: &stream, n: occurrenceIndex)
        }
        let hexOldLower = hexOld.lowercased()
        if stream.contains("<\(hexOldLower)>") {
            return replaceNthOccurrence(of: "<\(hexOldLower)>", with: "<\(hexNew.lowercased())>", in: &stream, n: occurrenceIndex)
        }
        return false
    }

    /// UTF-16BE hex: <005400680065> Tj (PowerPoint / CIDFont / Identity-H)
    private static func replaceHexTextUTF16BE(
        _ stream: inout String,
        oldText: String,
        newText: String,
        occurrenceIndex: Int = 0
    ) -> Bool {
        let hexOld = oldText.unicodeScalars.map { String(format: "%04X", $0.value) }.joined()
        let hexNew = newText.isEmpty ? "" :
            newText.unicodeScalars.map { String(format: "%04X", $0.value) }.joined()

        for pattern in ["<\(hexOld)> Tj", "<\(hexOld)> TJ", "<\(hexOld)>"] {
            if stream.contains(pattern) {
                let replacement = newText.isEmpty ? "<> Tj" : "<\(hexNew)> Tj"
                return replaceNthOccurrence(of: pattern, with: replacement, in: &stream, n: occurrenceIndex)
            }
        }

        let hexOldLower = hexOld.lowercased()
        for pattern in ["<\(hexOldLower)> Tj", "<\(hexOldLower)> TJ", "<\(hexOldLower)>"] {
            if stream.contains(pattern) {
                let replacement = newText.isEmpty ? "<> Tj" : "<\(hexNew.lowercased())> Tj"
                return replaceNthOccurrence(of: pattern, with: replacement, in: &stream, n: occurrenceIndex)
            }
        }

        return false
    }

    /// TJ arrays with hex strings: [<0054> -10 <0068> <0065>] TJ
    private static func replaceHexTJArray(
        _ stream: inout String,
        oldText: String,
        newText: String,
        fontMaps: [String: FontMap],
        occurrenceIndex: Int = 0
    ) -> Bool {
        guard let regex = try? NSRegularExpression(
            pattern: #"\[([^\]]*)\]\s*TJ"#, options: []
        ) else { return false }

        let nsStream = stream as NSString
        let matches = regex.matches(in: stream, range: NSRange(location: 0, length: nsStream.length))

        var matchCount = 0
        for match in matches {
            let arrayContent = nsStream.substring(with: match.range(at: 1))
            let textParts = extractAllTextFromTJArray(arrayContent, fontMaps: fontMaps)
            let concatenated = textParts.joined()

            if concatenated == oldText ||
               concatenated.trimmingCharacters(in: .whitespaces) == oldText {
                if matchCount == occurrenceIndex {
                    let replacement: String
                    if newText.isEmpty {
                        replacement = "() Tj"
                    } else {
                        let hexNew = newText.unicodeScalars
                            .map { String(format: "%04X", $0.value) }.joined()
                        replacement = "<\(hexNew)> Tj"
                    }
                    stream = (stream as NSString).replacingCharacters(in: match.range, with: replacement)
                    return true
                }
                matchCount += 1
            }
        }

        return false
    }

    /// Font-aware: encode text using ToUnicode CMap, search as single hex string
    private static func replaceUsingFontMaps(
        _ stream: inout String,
        oldText: String,
        newText: String,
        fontMaps: [String: FontMap],
        occurrenceIndex: Int = 0
    ) -> Bool {
        for (_, fontMap) in fontMaps {
            guard let encodedOld = encodeTextWithFontMap(oldText, fontMap: fontMap) else { continue }

            let hexOld = encodedOld.map { String(format: "%02X", $0) }.joined()
            guard !hexOld.isEmpty else { continue }

            let searchPatterns = ["<\(hexOld)>", "<\(hexOld.lowercased())>"]

            for pattern in searchPatterns {
                if stream.contains(pattern) {
                    let replacement: String
                    if newText.isEmpty {
                        replacement = "<>"
                    } else if let encodedNew = encodeTextWithFontMap(newText, fontMap: fontMap) {
                        let hexNew = encodedNew.map { String(format: "%02X", $0) }.joined()
                        replacement = "<\(hexNew)>"
                    } else {
                        replacement = "<>"
                    }
                    return replaceNthOccurrence(of: pattern, with: replacement, in: &stream, n: occurrenceIndex)
                }
            }
        }

        return false
    }

    /// Font-aware: search TJ arrays where each hex element is font-encoded
    private static func replaceFontEncodedTJArray(
        _ stream: inout String,
        oldText: String,
        newText: String,
        fontMaps: [String: FontMap],
        occurrenceIndex: Int = 0
    ) -> Bool {
        guard let regex = try? NSRegularExpression(
            pattern: #"\[([^\]]*)\]\s*TJ"#, options: []
        ) else { return false }

        let nsStream = stream as NSString
        let matches = regex.matches(in: stream, range: NSRange(location: 0, length: nsStream.length))

        var matchCount = 0
        for match in matches {
            let arrayContent = nsStream.substring(with: match.range(at: 1))

            // Try decoding with each font map
            for (_, fontMap) in fontMaps {
                let textParts = extractHexTextWithFontMap(arrayContent, fontMap: fontMap)
                let concatenated = textParts.joined()

                if concatenated == oldText ||
                   concatenated.trimmingCharacters(in: .whitespaces) == oldText {
                    if matchCount == occurrenceIndex {
                        let replacement: String
                        if newText.isEmpty {
                            replacement = "() Tj"
                        } else if let encodedNew = encodeTextWithFontMap(newText, fontMap: fontMap) {
                            let hexNew = encodedNew.map { String(format: "%02X", $0) }.joined()
                            replacement = "<\(hexNew)> Tj"
                        } else {
                            replacement = "() Tj"
                        }
                        stream = (stream as NSString).replacingCharacters(in: match.range, with: replacement)
                        return true
                    }
                    matchCount += 1
                    break // Don't count with other font maps
                }
            }
        }

        return false
    }

    /// Pattern 10: Substring within a larger parenthesized string.
    /// E.g., "(Hello World) Tj" — removing "Hello" → "( World) Tj"
    private static func replaceSubstringInParenText(
        _ stream: inout String,
        oldText: String,
        newText: String,
        escape: (String) -> String,
        occurrenceIndex: Int = 0
    ) -> Bool {
        let escapedOld = escape(oldText)

        // Quick check: does the escaped text appear in the stream at all?
        guard stream.contains(escapedOld) else { return false }

        // Parse parenthesized strings and check if any contains the target
        var matchCount = 0
        var i = stream.startIndex
        while i < stream.endIndex {
            guard stream[i] == "(" else {
                i = stream.index(after: i)
                continue
            }

            let parenStart = i
            var depth = 1
            var inner = ""
            var j = stream.index(after: i)

            while j < stream.endIndex && depth > 0 {
                let ch = stream[j]
                if ch == "\\" && stream.index(after: j) < stream.endIndex {
                    inner.append("\\")
                    inner.append(stream[stream.index(after: j)])
                    j = stream.index(j, offsetBy: 2)
                } else if ch == "(" {
                    depth += 1; inner.append(ch); j = stream.index(after: j)
                } else if ch == ")" {
                    depth -= 1
                    if depth > 0 { inner.append(ch) }
                    j = stream.index(after: j)
                } else {
                    inner.append(ch); j = stream.index(after: j)
                }
            }

            if inner.contains(escapedOld) {
                if matchCount == occurrenceIndex {
                    let escapedNew = escape(newText)
                    let newInner = inner.replacingOccurrences(of: escapedOld, with: escapedNew)
                    let replacement = "(\(newInner))"
                    stream.replaceSubrange(parenStart..<j, with: replacement)
                    return true
                }
                matchCount += 1
            }

            i = j
        }

        return false
    }

    /// Pattern 11: Substring match within TJ array text concatenation.
    /// Handles: [(The ) -10 (quick brown)] TJ when removing "quick"
    private static func replaceSubstringInTJArray(
        _ stream: inout String,
        oldText: String,
        newText: String,
        escape: (String) -> String,
        occurrenceIndex: Int = 0
    ) -> Bool {
        guard let regex = try? NSRegularExpression(
            pattern: #"\[([^\]]*)\]\s*TJ"#, options: []
        ) else { return false }

        let nsStream = stream as NSString
        let matches = regex.matches(in: stream, range: NSRange(location: 0, length: nsStream.length))

        var matchCount = 0
        for match in matches {
            let arrayContent = nsStream.substring(with: match.range(at: 1))
            let textParts = extractParenTextFromTJArray(arrayContent)
            let concatenated = textParts.joined()

            if concatenated.contains(oldText) {
                if matchCount == occurrenceIndex {
                    let newFullText = concatenated.replacingOccurrences(of: oldText, with: newText)
                    let escapedNew = escape(newFullText)
                    let replacement = newFullText.isEmpty ? "() Tj" : "(\(escapedNew)) Tj"
                    stream = (stream as NSString).replacingCharacters(in: match.range, with: replacement)
                    return true
                }
                matchCount += 1
            }
        }

        return false
    }

    /// Pattern 12: Character-by-character (x) Tj across BT/ET blocks.
    /// PowerPoint PDFs render each character in its own BT ... (x) Tj ET block.
    private static func replaceCharByCharTj(
        _ stream: inout String,
        oldText: String,
        newText: String,
        fontMaps: [String: FontMap],
        occurrenceIndex: Int = 0,
        targetBounds: CGRect? = nil
    ) -> Bool {
        guard oldText.count >= 2 else { return false }

        let nsStream = stream as NSString
        let streamLen = nsStream.length

        guard let regex = try? NSRegularExpression(
            pattern: #"\((.)\)\s*Tj"#
        ) else { return false }

        let matches = regex.matches(in: stream, range: NSRange(location: 0, length: streamLen))
        guard matches.count >= oldText.count else { return false }

        // Build reverse map from glyph bytes to characters
        var reverseMap: [UInt8: Character] = [:]
        for (_, fontMap) in fontMaps {
            for (unicode, glyphData) in fontMap {
                guard let scalar = Unicode.Scalar(unicode),
                      glyphData.count == 1 else { continue }
                reverseMap[glyphData[0]] = Character(scalar)
            }
        }

        struct CharMatch {
            let decodedChar: Character
            let range: NSRange
        }

        let charMatches: [CharMatch] = matches.compactMap { match in
            let charRange = match.range(at: 1)
            let charStr = nsStream.substring(with: charRange)
            guard let rawChar = charStr.first else { return nil }
            guard let firstScalar = rawChar.unicodeScalars.first,
                  firstScalar.value <= 255 else { return nil }
            let rawByte = UInt8(firstScalar.value)
            let decoded = reverseMap[rawByte] ?? rawChar
            return CharMatch(decodedChar: decoded, range: match.range)
        }

        guard charMatches.count >= oldText.count else { return false }

        let targetChars = Array(oldText)

        // Sliding window to find matching occurrence
        var matchIndex = 0
        for startIdx in 0...(charMatches.count - targetChars.count) {
            var matched = true
            for j in 0..<targetChars.count {
                if charMatches[startIdx + j].decodedChar != targetChars[j] {
                    matched = false
                    break
                }
            }
            if matched {
                if matchIndex == occurrenceIndex {
                    // Replace each matched char operator with empty
                    for j in (0..<targetChars.count).reversed() {
                        let cm = charMatches[startIdx + j]
                        stream = (stream as NSString).replacingCharacters(in: cm.range, with: "() Tj")
                    }
                    return true
                }
                matchIndex += 1
            }
        }

        return false
    }

    // MARK: - Pattern 13: Position-Based Removal

    /// Fallback for line deletion: remove text operators whose computed page-space
    /// position falls within the target bounds.
    ///
    /// Full PDF text state machine simulation:
    /// - **CTM**: `cm` (concatenate matrix), `q`/`Q` (save/restore graphics state)
    /// - **Text positioning**: `BT` (reset), `Tm` (absolute), `Td`/`TD` (relative),
    ///   `T*` (next line), `TL` (leading)
    /// - **Text operators**: `Tj`, `TJ`, `'` (show text)
    ///
    /// Converts text-space Y to page-space Y via CTM before comparing with targetBounds.
    /// Does NOT depend on text encoding — works with any font/encoding/glyph scheme.
    private static func removeTextByPosition(
        _ stream: inout String,
        targetBounds: CGRect
    ) -> Bool {
        let nsStream = stream as NSString
        let streamLen = nsStream.length

        // 2D affine matrix [a b 0; c d 0; e f 1]
        // Point transform: x' = a*x + c*y + e,  y' = b*x + d*y + f
        struct M2D {
            var a: CGFloat = 1, b: CGFloat = 0
            var c: CGFloat = 0, d: CGFloat = 1
            var e: CGFloat = 0, f: CGFloat = 0

            /// Pre-multiply: result = m × self  (PDF cm semantics)
            func pre(_ m: M2D) -> M2D {
                M2D(a: m.a*a + m.b*c, b: m.a*b + m.b*d,
                    c: m.c*a + m.d*c, d: m.c*b + m.d*d,
                    e: m.e*a + m.f*c + e, f: m.e*b + m.f*d + f)
            }
            func xOf(_ x: CGFloat, _ y: CGFloat) -> CGFloat { x*a + y*c + e }
            func yOf(_ x: CGFloat, _ y: CGFloat) -> CGFloat { x*b + y*d + f }
        }

        enum OpKind {
            case q, qEnd                                              // graphics state
            case cm(M2D)                                              // CTM
            case bt                                                   // text begin
            case tm(x: CGFloat, y: CGFloat)                           // absolute pos
            case td(tx: CGFloat, ty: CGFloat, setsLeading: Bool)      // relative pos
            case tStar                                                // next line
            case tl(CGFloat)                                          // leading
            case text(NSRange)                                        // Tj / TJ
            case textLine(NSRange)                                    // ' (T* then Tj)
        }
        struct Op { let loc: Int; let kind: OpKind }

        var ops: [Op] = []

        // ── 1. Graphics state: q / Q ──
        if let r = try? NSRegularExpression(pattern: #"\bq\b"#) {
            for m in r.matches(in: stream, range: NSRange(0..<streamLen)) {
                ops.append(Op(loc: m.range.location, kind: .q))
            }
        }
        if let r = try? NSRegularExpression(pattern: #"\bQ\b"#) {
            for m in r.matches(in: stream, range: NSRange(0..<streamLen)) {
                ops.append(Op(loc: m.range.location, kind: .qEnd))
            }
        }

        // ── 2. cm: a b c d e f cm ──
        if let r = try? NSRegularExpression(
            pattern: #"([\d.-]+)\s+([\d.-]+)\s+([\d.-]+)\s+([\d.-]+)\s+([\d.-]+)\s+([\d.-]+)\s+cm\b"#
        ) {
            for m in r.matches(in: stream, range: NSRange(0..<streamLen)) {
                if let a = Double(nsStream.substring(with: m.range(at: 1))),
                   let b = Double(nsStream.substring(with: m.range(at: 2))),
                   let c = Double(nsStream.substring(with: m.range(at: 3))),
                   let d = Double(nsStream.substring(with: m.range(at: 4))),
                   let e = Double(nsStream.substring(with: m.range(at: 5))),
                   let f = Double(nsStream.substring(with: m.range(at: 6))) {
                    ops.append(Op(loc: m.range.location,
                                  kind: .cm(M2D(a: CGFloat(a), b: CGFloat(b),
                                                c: CGFloat(c), d: CGFloat(d),
                                                e: CGFloat(e), f: CGFloat(f)))))
                }
            }
        }

        // ── 3. BT ──
        if let r = try? NSRegularExpression(pattern: #"\bBT\b"#) {
            for m in r.matches(in: stream, range: NSRange(0..<streamLen)) {
                ops.append(Op(loc: m.range.location, kind: .bt))
            }
        }

        // ── 4. Tm: a b c d x y Tm ──
        if let r = try? NSRegularExpression(
            pattern: #"[\d.-]+\s+[\d.-]+\s+[\d.-]+\s+[\d.-]+\s+([\d.-]+)\s+([\d.-]+)\s+Tm"#
        ) {
            for m in r.matches(in: stream, range: NSRange(0..<streamLen)) {
                if let x = Double(nsStream.substring(with: m.range(at: 1))),
                   let y = Double(nsStream.substring(with: m.range(at: 2))) {
                    ops.append(Op(loc: m.range.location, kind: .tm(x: CGFloat(x), y: CGFloat(y))))
                }
            }
        }

        // ── 5. Td / TD ──
        if let r = try? NSRegularExpression(pattern: #"([\d.-]+)\s+([\d.-]+)\s+T([dD])"#) {
            for m in r.matches(in: stream, range: NSRange(0..<streamLen)) {
                if let tx = Double(nsStream.substring(with: m.range(at: 1))),
                   let ty = Double(nsStream.substring(with: m.range(at: 2))) {
                    let v = nsStream.substring(with: m.range(at: 3))
                    ops.append(Op(loc: m.range.location,
                                  kind: .td(tx: CGFloat(tx), ty: CGFloat(ty), setsLeading: v == "D")))
                }
            }
        }

        // ── 6. T* ──
        if let r = try? NSRegularExpression(pattern: #"\bT\*"#) {
            for m in r.matches(in: stream, range: NSRange(0..<streamLen)) {
                ops.append(Op(loc: m.range.location, kind: .tStar))
            }
        }

        // ── 7. TL ──
        if let r = try? NSRegularExpression(pattern: #"([\d.-]+)\s+TL"#) {
            for m in r.matches(in: stream, range: NSRange(0..<streamLen)) {
                if let l = Double(nsStream.substring(with: m.range(at: 1))) {
                    ops.append(Op(loc: m.range.location, kind: .tl(CGFloat(l))))
                }
            }
        }

        // ── 8. Text operators: (...) Tj, <hex> Tj, [...] TJ ──
        if let r = try? NSRegularExpression(
            pattern: #"(?:\((?:[^()\\]|\\.)*\)|<[0-9A-Fa-f]+>)\s*Tj|\[[^\]]*\]\s*TJ"#
        ) {
            for m in r.matches(in: stream, range: NSRange(0..<streamLen)) {
                ops.append(Op(loc: m.range.location, kind: .text(m.range)))
            }
        }

        // ── 9. ' operator: (string) ' — equivalent to T* then Tj ──
        if let r = try? NSRegularExpression(
            pattern: #"(?:\((?:[^()\\]|\\.)*\)|<[0-9A-Fa-f]+>)\s*'"#
        ) {
            for m in r.matches(in: stream, range: NSRange(0..<streamLen)) {
                ops.append(Op(loc: m.range.location, kind: .textLine(m.range)))
            }
        }

        ops.sort { $0.loc < $1.loc }

        // ── Process: full PDF state machine ──
        var ctm = M2D()
        var ctmStack: [M2D] = []
        var lineX: CGFloat = 0, lineY: CGFloat = 0
        var leading: CGFloat = 0

        let yTol = min(max(targetBounds.height * 0.1, 0.5), 2)
        let xTol: CGFloat = 5
        var rangesToBlank: [NSRange] = []

        for op in ops {
            switch op.kind {
            case .q:
                ctmStack.append(ctm)
            case .qEnd:
                if let saved = ctmStack.popLast() { ctm = saved }
            case .cm(let m):
                ctm = ctm.pre(m)

            case .bt:
                lineX = 0; lineY = 0

            case .tm(let x, let y):
                lineX = x; lineY = y
            case .td(let tx, let ty, let setsLeading):
                lineX += tx; lineY += ty
                if setsLeading { leading = -ty }
            case .tStar:
                lineY -= leading
            case .tl(let l):
                leading = l

            case .text(let range):
                let pageY = ctm.yOf(lineX, lineY)
                let pageX = ctm.xOf(lineX, lineY)
                let inY = pageY >= targetBounds.minY - yTol && pageY <= targetBounds.maxY + yTol
                let inX = pageX >= targetBounds.minX - xTol && pageX <= targetBounds.maxX + xTol
                if inY && inX {
                    rangesToBlank.append(range)
                }
            case .textLine(let range):
                // ' operator does T* first, then shows text
                lineY -= leading
                let pageY = ctm.yOf(lineX, lineY)
                let pageX = ctm.xOf(lineX, lineY)
                let inY = pageY >= targetBounds.minY - yTol && pageY <= targetBounds.maxY + yTol
                let inX = pageX >= targetBounds.minX - xTol && pageX <= targetBounds.maxX + xTol
                if inY && inX {
                    rangesToBlank.append(range)
                }
            }
        }

        guard !rangesToBlank.isEmpty else { return false }

        // Replace from end to start (preserves offsets)
        for range in rangesToBlank.sorted(by: { $0.location > $1.location }) {
            stream = (stream as NSString).replacingCharacters(in: range, with: "() Tj")
        }

        return true
    }

    // MARK: - TJ Array Text Extraction

    private static func extractParenTextFromTJArray(_ content: String) -> [String] {
        var parts: [String] = []
        var i = content.startIndex

        while i < content.endIndex {
            if content[i] == "(" {
                var depth = 1
                var text = ""
                var j = content.index(after: i)
                while j < content.endIndex && depth > 0 {
                    let ch = content[j]
                    if ch == "\\" && content.index(after: j) < content.endIndex {
                        text.append(content[content.index(after: j)])
                        j = content.index(j, offsetBy: 2)
                    } else if ch == "(" {
                        depth += 1; text.append(ch); j = content.index(after: j)
                    } else if ch == ")" {
                        depth -= 1
                        if depth > 0 { text.append(ch) }
                        j = content.index(after: j)
                    } else {
                        text.append(ch); j = content.index(after: j)
                    }
                }
                parts.append(text)
                i = j
            } else {
                i = content.index(after: i)
            }
        }

        return parts
    }

    /// Extract ALL text (paren + hex) from TJ array, decoding hex via font maps or UTF-16BE.
    private static func extractAllTextFromTJArray(
        _ content: String,
        fontMaps: [String: FontMap]
    ) -> [String] {
        var parts: [String] = []
        var i = content.startIndex

        while i < content.endIndex {
            if content[i] == "(" {
                var depth = 1
                var text = ""
                var j = content.index(after: i)
                while j < content.endIndex && depth > 0 {
                    let ch = content[j]
                    if ch == "\\" && content.index(after: j) < content.endIndex {
                        text.append(content[content.index(after: j)])
                        j = content.index(j, offsetBy: 2)
                    } else if ch == "(" {
                        depth += 1; text.append(ch); j = content.index(after: j)
                    } else if ch == ")" {
                        depth -= 1
                        if depth > 0 { text.append(ch) }
                        j = content.index(after: j)
                    } else {
                        text.append(ch); j = content.index(after: j)
                    }
                }
                parts.append(text)
                i = j
            } else if content[i] == "<" {
                var hex = ""
                var j = content.index(after: i)
                while j < content.endIndex && content[j] != ">" {
                    let ch = content[j]
                    if ch.isHexDigit { hex.append(ch) }
                    j = content.index(after: j)
                }
                if j < content.endIndex { j = content.index(after: j) }

                if let text = decodeHexString(hex, fontMaps: fontMaps) {
                    parts.append(text)
                }
                i = j
            } else {
                i = content.index(after: i)
            }
        }

        return parts
    }

    /// Extract hex strings from TJ array using a specific font map for decoding.
    private static func extractHexTextWithFontMap(
        _ content: String,
        fontMap: FontMap
    ) -> [String] {
        var parts: [String] = []
        var i = content.startIndex

        while i < content.endIndex {
            if content[i] == "(" {
                // Skip paren strings for this font-specific extraction
                var depth = 1
                var j = content.index(after: i)
                while j < content.endIndex && depth > 0 {
                    if content[j] == "(" { depth += 1 }
                    else if content[j] == ")" { depth -= 1 }
                    j = content.index(after: j)
                }
                i = j
            } else if content[i] == "<" {
                var hex = ""
                var j = content.index(after: i)
                while j < content.endIndex && content[j] != ">" {
                    if content[j].isHexDigit { hex.append(content[j]) }
                    j = content.index(after: j)
                }
                if j < content.endIndex { j = content.index(after: j) }

                if !hex.isEmpty, let decoded = decodeWithFontMap(hex, fontMap: fontMap) {
                    parts.append(decoded)
                }
                i = j
            } else {
                i = content.index(after: i)
            }
        }

        return parts
    }

    // MARK: - Hex Decoding

    /// Decode hex string: font map → UTF-16BE → Latin1
    private static func decodeHexString(_ hex: String, fontMaps: [String: FontMap]) -> String? {
        guard !hex.isEmpty else { return nil }

        var h = hex
        if h.count % 2 != 0 { h += "0" }

        // Try font map decoding first
        for (_, fontMap) in fontMaps {
            if let decoded = decodeWithFontMap(h, fontMap: fontMap) {
                return decoded
            }
        }

        // Try UTF-16BE (2 bytes per char)
        if h.count >= 4 && h.count % 4 == 0 {
            var chars: [UInt16] = []
            var idx = h.startIndex
            var allValid = true
            while idx < h.endIndex {
                let end = h.index(idx, offsetBy: 4, limitedBy: h.endIndex) ?? h.endIndex
                if let val = UInt16(h[idx..<end], radix: 16) {
                    chars.append(val)
                } else {
                    allValid = false; break
                }
                idx = end
            }
            if allValid && !chars.isEmpty {
                let str = String(utf16CodeUnits: chars, count: chars.count)
                if str.unicodeScalars.allSatisfy({ $0.value >= 0x20 }) {
                    return str
                }
            }
        }

        // Try 1-byte decoding
        var bytes: [UInt8] = []
        var idx = h.startIndex
        while idx < h.endIndex {
            let end = h.index(idx, offsetBy: 2, limitedBy: h.endIndex) ?? h.endIndex
            if let val = UInt8(h[idx..<end], radix: 16) { bytes.append(val) }
            idx = end
        }
        return String(bytes: bytes, encoding: .isoLatin1)
    }

    // MARK: - Font Map Helpers

    private static func encodeTextWithFontMap(_ text: String, fontMap: FontMap) -> Data? {
        var result = Data()
        for scalar in text.unicodeScalars {
            guard let glyphData = fontMap[scalar.value] else { return nil }
            result.append(glyphData)
        }
        return result
    }

    private static func decodeWithFontMap(_ hex: String, fontMap: FontMap) -> String? {
        var reverseMap: [Data: UInt32] = [:]
        for (unicode, glyphData) in fontMap {
            reverseMap[glyphData] = unicode
        }
        guard !reverseMap.isEmpty else { return nil }

        let glyphWidth = fontMap.values.first?.count ?? 2
        let hexCharsPerGlyph = glyphWidth * 2

        guard hex.count >= hexCharsPerGlyph,
              hex.count % hexCharsPerGlyph == 0 else { return nil }

        var result = ""
        var idx = hex.startIndex

        while idx < hex.endIndex {
            guard let end = hex.index(idx, offsetBy: hexCharsPerGlyph, limitedBy: hex.endIndex),
                  let glyphData = hexStringToData(String(hex[idx..<end])) else { return nil }

            guard let unicode = reverseMap[glyphData],
                  let scalar = Unicode.Scalar(unicode) else { return nil }

            result.append(Character(scalar))
            idx = end
        }

        return result.isEmpty ? nil : result
    }

    // MARK: - ToUnicode CMap Parsing

    private static func parseToUnicodeCMap(from font: CGPDFDictionaryRef) -> FontMap? {
        var toUnicodeRef: CGPDFStreamRef?
        guard CGPDFDictionaryGetStream(font, "ToUnicode", &toUnicodeRef),
              let toUnicode = toUnicodeRef else { return nil }

        var format: CGPDFDataFormat = .raw
        guard let data = CGPDFStreamCopyData(toUnicode, &format) as Data?,
              let cmapStr = String(data: data, encoding: .ascii)
                ?? String(data: data, encoding: .isoLatin1) else { return nil }

        var map: FontMap = [:]

        // bfchar: <glyphID> <unicode> → reverse to unicode → glyphID
        let bfcharSections = findCMapSections(cmapStr, start: "beginbfchar", end: "endbfchar")
        let pairPattern = #"<([0-9A-Fa-f]+)>\s*<([0-9A-Fa-f]+)>"#
        if let pairRegex = try? NSRegularExpression(pattern: pairPattern) {
            for section in bfcharSections {
                let nsSection = section as NSString
                let matches = pairRegex.matches(
                    in: section, range: NSRange(location: 0, length: nsSection.length)
                )
                for match in matches {
                    let glyphHex = nsSection.substring(with: match.range(at: 1))
                    let unicodeHex = nsSection.substring(with: match.range(at: 2))

                    if let unicodeVal = UInt32(unicodeHex, radix: 16),
                       let glyphData = hexStringToData(glyphHex) {
                        map[unicodeVal] = glyphData
                    }
                }
            }
        }

        // bfrange: <startGlyph> <endGlyph> <startUnicode>
        let bfrangeSections = findCMapSections(cmapStr, start: "beginbfrange", end: "endbfrange")
        let rangePattern = #"<([0-9A-Fa-f]+)>\s*<([0-9A-Fa-f]+)>\s*<([0-9A-Fa-f]+)>"#
        if let rangeRegex = try? NSRegularExpression(pattern: rangePattern) {
            for section in bfrangeSections {
                let nsSection = section as NSString
                let matches = rangeRegex.matches(
                    in: section, range: NSRange(location: 0, length: nsSection.length)
                )
                for match in matches {
                    let startGlyphHex = nsSection.substring(with: match.range(at: 1))
                    let endGlyphHex = nsSection.substring(with: match.range(at: 2))
                    let startUnicodeHex = nsSection.substring(with: match.range(at: 3))

                    guard let startGlyph = UInt32(startGlyphHex, radix: 16),
                          let endGlyph = UInt32(endGlyphHex, radix: 16),
                          let startUnicode = UInt32(startUnicodeHex, radix: 16) else { continue }

                    let glyphWidth = startGlyphHex.count / 2

                    for g in startGlyph...min(endGlyph, startGlyph + 256) {
                        let unicode = startUnicode + (g - startGlyph)
                        var glyphBytes = withUnsafeBytes(of: g.bigEndian) { Array($0) }
                        glyphBytes = Array(glyphBytes.suffix(glyphWidth))
                        map[unicode] = Data(glyphBytes)
                    }
                }
            }
        }

        return map.isEmpty ? nil : map
    }

    private static func findCMapSections(_ cmap: String, start: String, end: String) -> [String] {
        var sections: [String] = []
        var searchStart = cmap.startIndex

        while let startRange = cmap.range(of: start, range: searchStart..<cmap.endIndex) {
            let afterStart = startRange.upperBound
            if let endRange = cmap.range(of: end, range: afterStart..<cmap.endIndex) {
                sections.append(String(cmap[afterStart..<endRange.lowerBound]))
                searchStart = endRange.upperBound
            } else {
                break
            }
        }

        return sections
    }

    // MARK: - Low-level Helpers

    private static func looksLikeContentStream(_ str: String) -> Bool {
        str.contains(" Tf") || str.contains(" Tj") || str.contains(" TJ") || str.contains("BT")
    }

    private static func findBytes(_ needle: Data, in haystack: Data, from offset: Int) -> Int? {
        guard needle.count > 0, offset + needle.count <= haystack.count else { return nil }
        let needleBytes = Array(needle)
        let haystackBytes = Array(haystack)

        for i in offset...(haystackBytes.count - needleBytes.count) {
            var match = true
            for j in 0..<needleBytes.count {
                if haystackBytes[i + j] != needleBytes[j] {
                    match = false
                    break
                }
            }
            if match { return i }
        }
        return nil
    }

    private static func hexStringToData(_ hex: String) -> Data? {
        var h = hex
        if h.count % 2 != 0 { h += "0" }
        var data = Data()
        var idx = h.startIndex
        while idx < h.endIndex {
            guard let end = h.index(idx, offsetBy: 2, limitedBy: h.endIndex),
                  let byte = UInt8(h[idx..<end], radix: 16) else { return nil }
            data.append(byte)
            idx = end
        }
        return data
    }

    private static func zlibDecompress(_ data: Data) -> Data? {
        guard data.count >= 6 else { return nil }

        // Zlib header: first byte encodes CM (bits 0-3) and CINFO (bits 4-7)
        // CM=8 (deflate): first byte has low nibble 8 → 0x08, 0x18, 0x28, 0x38, 0x48, 0x58, 0x68, 0x78
        let firstByte = data[data.startIndex]
        guard firstByte & 0x0F == 0x08 else { return nil }

        let rawDeflate = Data(data.dropFirst(2))
        let bufferSize = max(data.count * 20, 65536)
        var buffer = [UInt8](repeating: 0, count: bufferSize)

        let decompressedSize = rawDeflate.withUnsafeBytes { srcPtr -> Int in
            guard let src = srcPtr.baseAddress?.assumingMemoryBound(to: UInt8.self) else { return 0 }
            return compression_decode_buffer(
                &buffer, bufferSize, src, rawDeflate.count, nil, COMPRESSION_ZLIB
            )
        }

        guard decompressedSize > 0 else { return nil }
        return Data(buffer[..<decompressedSize])
    }

    /// Compress data using zlib (FlateDecode compatible).
    /// Produces: 2-byte zlib header + raw deflate + 4-byte Adler-32 checksum.
    private static func zlibCompress(_ data: Data) -> Data? {
        guard !data.isEmpty else { return nil }
        let bufferSize = data.count + 512
        var buffer = [UInt8](repeating: 0, count: bufferSize)

        let compressedSize = data.withUnsafeBytes { srcPtr -> Int in
            guard let src = srcPtr.baseAddress?.assumingMemoryBound(to: UInt8.self) else { return 0 }
            return compression_encode_buffer(
                &buffer, bufferSize, src, data.count, nil, COMPRESSION_ZLIB
            )
        }

        guard compressedSize > 0 else { return nil }

        // zlib header (CMF=0x78 default, FLG=0x9C)
        var result = Data([0x78, 0x9C])
        result.append(Data(buffer[..<compressedSize]))

        // Adler-32 checksum of uncompressed data (big-endian)
        let checksum = adler32(data)
        var checksumBE = checksum.bigEndian
        result.append(Data(bytes: &checksumBE, count: 4))

        return result
    }

    private static func adler32(_ data: Data) -> UInt32 {
        var a: UInt32 = 1
        var b: UInt32 = 0
        let mod: UInt32 = 65521
        for byte in data {
            a = (a + UInt32(byte)) % mod
            b = (b + a) % mod
        }
        return (b << 16) | a
    }
}
