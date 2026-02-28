import Foundation

/// Parsed theme color scheme from theme.xml
public struct ThemeColorScheme {
    /// Maps theme color names to RGB hex values
    /// Keys: dk1, lt1, dk2, lt2, accent1-6, hlink, folHlink
    var colors: [String: String] = [:]

    /// Resolve a theme color name to DocXColor, optionally applying tint/shade
    func resolve(themeName: String, themeTint: String? = nil, themeShade: String? = nil) -> DocXColor? {
        // Map Word theme names to our keys
        let key = mapThemeName(themeName)
        guard let hex = colors[key], let baseColor = DocXColor(hex: hex) else { return nil }

        // Apply shade (darker)
        if let shadeHex = themeShade, let shade = UInt8(shadeHex, radix: 16) {
            return applyShade(to: baseColor, factor: shade)
        }
        // Apply tint (lighter)
        if let tintHex = themeTint, let tint = UInt8(tintHex, radix: 16) {
            return applyTint(to: baseColor, factor: tint)
        }

        return baseColor
    }

    private func mapThemeName(_ name: String) -> String {
        // Word uses various naming conventions
        switch name.lowercased() {
        case "dark1", "dk1", "tx1", "text1": return "dk1"
        case "light1", "lt1", "bg1", "background1": return "lt1"
        case "dark2", "dk2", "tx2", "text2": return "dk2"
        case "light2", "lt2", "bg2", "background2": return "lt2"
        case "accent1": return "accent1"
        case "accent2": return "accent2"
        case "accent3": return "accent3"
        case "accent4": return "accent4"
        case "accent5": return "accent5"
        case "accent6": return "accent6"
        case "hlink", "hyperlink": return "hlink"
        case "folhlink", "followedhyperlink": return "folHlink"
        default: return name.lowercased()
        }
    }

    /// Apply shade (multiply each channel by factor/255)
    private func applyShade(to color: DocXColor, factor: UInt8) -> DocXColor {
        let f = Double(factor) / 255.0
        return DocXColor(
            red: UInt8(min(Double(color.red) * f, 255)),
            green: UInt8(min(Double(color.green) * f, 255)),
            blue: UInt8(min(Double(color.blue) * f, 255))
        )
    }

    /// Apply tint (blend toward white by factor/255)
    private func applyTint(to color: DocXColor, factor: UInt8) -> DocXColor {
        let f = Double(factor) / 255.0
        return DocXColor(
            red: UInt8(min(Double(color.red) + (255.0 - Double(color.red)) * (1.0 - f), 255)),
            green: UInt8(min(Double(color.green) + (255.0 - Double(color.green)) * (1.0 - f), 255)),
            blue: UInt8(min(Double(color.blue) + (255.0 - Double(color.blue)) * (1.0 - f), 255))
        )
    }
}

/// Parses theme.xml to extract the color scheme
class ThemeParser {

    func parse(_ data: Data) -> ThemeColorScheme {
        let delegate = ThemeXMLDelegate()
        let parser = XMLParser(data: data)
        parser.delegate = delegate
        parser.shouldProcessNamespaces = true
        parser.parse()
        return delegate.scheme
    }
}

// MARK: - SAX Delegate

private class ThemeXMLDelegate: NSObject, XMLParserDelegate {
    var scheme = ThemeColorScheme()

    private var inClrScheme = false

    // Current color element we're inside (dk1, lt1, accent1, etc.)
    private var currentColorName: String?

    private let colorElementNames: Set<String> = [
        "dk1", "lt1", "dk2", "lt2",
        "accent1", "accent2", "accent3", "accent4", "accent5", "accent6",
        "hlink", "folHlink"
    ]

    func parser(_ parser: XMLParser, didStartElement elementName: String,
                namespaceURI: String?, qualifiedName: String?,
                attributes attributeDict: [String: String] = [:]) {

        let local = stripNS(elementName)

        if local == "clrScheme" {
            inClrScheme = true
            return
        }

        guard inClrScheme else { return }

        if colorElementNames.contains(local) {
            currentColorName = local
            return
        }

        // Actual color value elements inside a color slot
        if currentColorName != nil {
            switch local {
            case "srgbClr":
                // Direct RGB: <a:srgbClr val="4472C4"/>
                if let val = attr(attributeDict, "val") {
                    scheme.colors[currentColorName!] = val
                }
            case "sysClr":
                // System color: <a:sysClr val="windowText" lastClr="000000"/>
                if let lastClr = attr(attributeDict, "lastClr") {
                    scheme.colors[currentColorName!] = lastClr
                } else if let val = attr(attributeDict, "val") {
                    // Fallback: map known system colors
                    scheme.colors[currentColorName!] = mapSystemColor(val)
                }
            default:
                break
            }
        }
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String,
                namespaceURI: String?, qualifiedName: String?) {

        let local = stripNS(elementName)

        if local == "clrScheme" {
            inClrScheme = false
        } else if colorElementNames.contains(local) {
            currentColorName = nil
        }
    }

    private func stripNS(_ name: String) -> String {
        if let i = name.lastIndex(of: ":") { return String(name[name.index(after: i)...]) }
        return name
    }

    private func attr(_ attrs: [String: String], _ localName: String) -> String? {
        if let v = attrs[localName] { return v }
        for (key, value) in attrs {
            if let i = key.lastIndex(of: ":"), String(key[key.index(after: i)...]) == localName {
                return value
            }
        }
        return nil
    }

    private func mapSystemColor(_ name: String) -> String {
        switch name.lowercased() {
        case "windowtext": return "000000"
        case "window": return "FFFFFF"
        default: return "000000"
        }
    }
}
