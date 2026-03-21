import Foundation

/// Basic formula evaluator for spreadsheet cells
/// Supports: SUM, AVERAGE, COUNT, MIN, MAX, IF, CONCATENATE, arithmetic (+,-,*,/), cell references
enum STExcelFormulaEngine {

    /// Max recursion depth to prevent stack overflow from circular references or deep nesting
    private static let maxDepth = 20
    /// Current recursion depth (main-thread only, safe for SwiftUI rendering)
    private static var currentDepth = 0
    /// Cells currently being evaluated — detects circular references
    private static var evaluatingCells: Set<String> = []

    /// Evaluate a formula string and return the computed value
    /// - Parameters:
    ///   - formula: Formula string starting with "=" (e.g. "=SUM(A1:A5)")
    ///   - sheet: The sheet to resolve cell references
    /// - Returns: Computed string value, or the formula itself if unsupported
    static func evaluate(_ formula: String, in sheet: STExcelSheet) -> String {
        guard formula.hasPrefix("=") else { return formula }

        // Guard against infinite recursion
        currentDepth += 1
        defer { currentDepth -= 1 }
        guard currentDepth <= maxDepth else { return "#REF!" }

        let expr = String(formula.dropFirst()).trimmingCharacters(in: .whitespaces)
        guard !expr.isEmpty else { return "" }

        do {
            let result = try evaluateExpression(expr, in: sheet)
            // Format result
            if let num = result as? Double {
                if num == num.rounded() && abs(num) < 1e15 {
                    return String(Int(num))
                }
                return String(format: "%.2f", num)
            }
            return "\(result)"
        } catch {
            return "#ERROR"
        }
    }

    // MARK: - Expression Evaluator

    private static func evaluateExpression(_ expr: String, in sheet: STExcelSheet) throws -> Any {
        // Guard against stack overflow from circular or deeply nested formulas
        currentDepth += 1
        defer { currentDepth -= 1 }
        guard currentDepth <= maxDepth else { return "#REF!" as Any }

        let trimmed = expr.trimmingCharacters(in: .whitespaces)

        // Check for function calls: FUNCNAME(args)
        if let funcMatch = parseFunctionCall(trimmed) {
            return try evaluateFunction(funcMatch.name, args: funcMatch.args, in: sheet)
        }

        // Check for arithmetic: try to parse as arithmetic expression
        if let result = tryArithmetic(trimmed, in: sheet) {
            return result
        }

        // Check for cell reference
        if let ref = CellReference(string: trimmed) {
            let cell = sheet.cell(row: ref.row, column: ref.col)
            // Prefer cached value from xlsx <v> element
            if !cell.value.isEmpty {
                return Double(cell.value) ?? cell.value as Any
            }
            if let formula = cell.formula {
                // Circular reference detection
                let cellKey = "\(ref.row),\(ref.col)"
                guard !evaluatingCells.contains(cellKey) else { return "#REF!" as Any }
                evaluatingCells.insert(cellKey)
                let val = evaluate(formula, in: sheet)
                evaluatingCells.remove(cellKey)
                return Double(val) ?? val
            }
            return cell.value as Any
        }

        // Check for string literal
        if trimmed.hasPrefix("\"") && trimmed.hasSuffix("\"") {
            return String(trimmed.dropFirst().dropLast())
        }

        // Check for number
        if let num = Double(trimmed) {
            return num
        }

        return trimmed
    }

    // MARK: - Function Parsing

    private struct FunctionCall {
        let name: String
        let args: String
    }

    private static func parseFunctionCall(_ expr: String) -> FunctionCall? {
        // Match FUNCNAME( ... )
        let upper = expr.uppercased()
        let funcNames = ["SUM", "AVERAGE", "COUNT", "MIN", "MAX", "IF", "CONCATENATE",
                         "COUNTA", "ABS", "ROUND", "INT", "MOD", "POWER", "SQRT",
                         "LEN", "LOWER", "UPPER", "TRIM", "LEFT", "RIGHT", "MID",
                         // Financial
                         "PMT", "FV", "PV", "RATE", "NPV", "IRR",
                         // Logical
                         "AND", "OR", "NOT", "IFERROR", "TRUE", "FALSE",
                         // Date & Time
                         "NOW", "TODAY", "DATE", "YEAR", "MONTH", "DAY",
                         "HOUR", "MINUTE", "SECOND",
                         // Reference
                         "VLOOKUP", "HLOOKUP", "INDEX", "MATCH", "CHOOSE",
                         // Text
                         "FIND", "REPLACE", "SUBSTITUTE",
                         // Math
                         "SUMIF", "COUNTIF", "PRODUCT"]
        for name in funcNames {
            if upper.hasPrefix(name + "(") && expr.hasSuffix(")") {
                let argsStart = expr.index(expr.startIndex, offsetBy: name.count + 1)
                let argsEnd = expr.index(expr.endIndex, offsetBy: -1)
                let args = String(expr[argsStart..<argsEnd])
                return FunctionCall(name: name, args: args)
            }
        }
        return nil
    }

    private static func evaluateFunction(_ name: String, args: String, in sheet: STExcelSheet) throws -> Any {
        switch name.uppercased() {
        case "SUM":
            let values = try resolveNumericValues(args, in: sheet)
            return values.reduce(0, +)

        case "AVERAGE":
            let values = try resolveNumericValues(args, in: sheet)
            return values.isEmpty ? 0.0 : values.reduce(0, +) / Double(values.count)

        case "COUNT":
            let values = try resolveNumericValues(args, in: sheet)
            return Double(values.count)

        case "COUNTA":
            let values = try resolveAllValues(args, in: sheet)
            return Double(values.filter { !$0.isEmpty }.count)

        case "MIN":
            let values = try resolveNumericValues(args, in: sheet)
            return values.min() ?? 0.0

        case "MAX":
            let values = try resolveNumericValues(args, in: sheet)
            return values.max() ?? 0.0

        case "ABS":
            let val = try evaluateExpression(args, in: sheet)
            if let num = val as? Double { return abs(num) }
            return "#VALUE!"

        case "SQRT":
            let val = try evaluateExpression(args, in: sheet)
            if let num = val as? Double, num >= 0 { return sqrt(num) }
            return "#NUM!"

        case "INT":
            let val = try evaluateExpression(args, in: sheet)
            if let num = val as? Double { return floor(num) }
            return "#VALUE!"

        case "ROUND":
            let parts = splitArgs(args)
            guard parts.count == 2 else { return "#VALUE!" }
            let val = try evaluateExpression(parts[0], in: sheet)
            let digits = try evaluateExpression(parts[1], in: sheet)
            if let num = val as? Double, let d = digits as? Double {
                let factor = pow(10, d)
                return (num * factor).rounded() / factor
            }
            return "#VALUE!"

        case "MOD":
            let parts = splitArgs(args)
            guard parts.count == 2 else { return "#VALUE!" }
            let a = try evaluateExpression(parts[0], in: sheet)
            let b = try evaluateExpression(parts[1], in: sheet)
            if let na = a as? Double, let nb = b as? Double, nb != 0 {
                return na.truncatingRemainder(dividingBy: nb)
            }
            return "#DIV/0!"

        case "POWER":
            let parts = splitArgs(args)
            guard parts.count == 2 else { return "#VALUE!" }
            let base = try evaluateExpression(parts[0], in: sheet)
            let exp = try evaluateExpression(parts[1], in: sheet)
            if let b = base as? Double, let e = exp as? Double {
                return pow(b, e)
            }
            return "#VALUE!"

        case "IF":
            let parts = splitArgs(args)
            guard parts.count >= 2 else { return "#VALUE!" }
            let condition = try evaluateExpression(parts[0], in: sheet)
            let isTrue: Bool
            if let num = condition as? Double { isTrue = num != 0 }
            else if let str = condition as? String { isTrue = str.uppercased() == "TRUE" }
            else { isTrue = false }

            if isTrue {
                return try evaluateExpression(parts[1], in: sheet)
            } else if parts.count >= 3 {
                return try evaluateExpression(parts[2], in: sheet)
            }
            return ""

        case "CONCATENATE":
            let parts = splitArgs(args)
            var result = ""
            for part in parts {
                let val = try evaluateExpression(part, in: sheet)
                if let str = val as? String { result += str }
                else if let num = val as? Double {
                    result += num == num.rounded() ? String(Int(num)) : String(num)
                }
            }
            return result

        case "LEN":
            let val = try evaluateExpression(args, in: sheet)
            if let str = val as? String { return Double(str.count) }
            return Double(0)

        case "LOWER":
            let val = try evaluateExpression(args, in: sheet)
            if let str = val as? String { return str.lowercased() }
            return "\(val)".lowercased()

        case "UPPER":
            let val = try evaluateExpression(args, in: sheet)
            if let str = val as? String { return str.uppercased() }
            return "\(val)".uppercased()

        case "TRIM":
            let val = try evaluateExpression(args, in: sheet)
            if let str = val as? String { return str.trimmingCharacters(in: .whitespaces) }
            return val

        case "LEFT":
            let parts = splitArgs(args)
            guard parts.count == 2 else { return "#VALUE!" }
            let val = try evaluateExpression(parts[0], in: sheet)
            let n = try evaluateExpression(parts[1], in: sheet)
            if let str = val as? String, let num = n as? Double {
                return String(str.prefix(Int(num)))
            }
            return "#VALUE!"

        case "RIGHT":
            let parts = splitArgs(args)
            guard parts.count == 2 else { return "#VALUE!" }
            let val = try evaluateExpression(parts[0], in: sheet)
            let n = try evaluateExpression(parts[1], in: sheet)
            if let str = val as? String, let num = n as? Double {
                return String(str.suffix(Int(num)))
            }
            return "#VALUE!"

        case "MID":
            let parts = splitArgs(args)
            guard parts.count == 3 else { return "#VALUE!" }
            let val = try evaluateExpression(parts[0], in: sheet)
            let start = try evaluateExpression(parts[1], in: sheet)
            let len = try evaluateExpression(parts[2], in: sheet)
            if let str = val as? String, let s = start as? Double, let l = len as? Double {
                let startIdx = max(0, Int(s) - 1)
                let length = Int(l)
                if startIdx < str.count {
                    let begin = str.index(str.startIndex, offsetBy: startIdx)
                    let end = str.index(begin, offsetBy: min(length, str.count - startIdx))
                    return String(str[begin..<end])
                }
                return ""
            }
            return "#VALUE!"

        // MARK: Financial
        // All financial functions: resolve all args to numbers first, return 0 if empty

        case "PMT":
            // PMT(rate, nper, pv)
            let pmtNums = try resolveNumericArgs(args, in: sheet, expected: 3)
            guard pmtNums.count >= 3 else { return pmtNums.isEmpty ? 0.0 : "#VALUE!" }
            let (rate, nper, pv) = (pmtNums[0], pmtNums[1], pmtNums[2])
            if rate == 0 { return nper == 0 ? 0.0 : -pv / nper }
            return -(pv * (rate * pow(1 + rate, nper)) / (pow(1 + rate, nper) - 1))

        case "FV":
            // FV(rate, nper, pmt)
            let fvNums = try resolveNumericArgs(args, in: sheet, expected: 3)
            guard fvNums.count >= 3 else { return fvNums.isEmpty ? 0.0 : "#VALUE!" }
            let (rate, nper, pmt) = (fvNums[0], fvNums[1], fvNums[2])
            if rate == 0 { return -(pmt * nper) }
            return -pmt * (pow(1 + rate, nper) - 1) / rate

        case "PV":
            // PV(rate, nper, pmt)
            let pvNums = try resolveNumericArgs(args, in: sheet, expected: 3)
            guard pvNums.count >= 3 else { return pvNums.isEmpty ? 0.0 : "#VALUE!" }
            let (rate, nper, pmt) = (pvNums[0], pvNums[1], pvNums[2])
            if rate == 0 { return -(pmt * nper) }
            return -pmt * (1 - pow(1 + rate, -nper)) / rate

        case "RATE":
            // RATE(nper, pmt, pv) — Newton's method
            let rateNums = try resolveNumericArgs(args, in: sheet, expected: 3)
            guard rateNums.count >= 3 else { return rateNums.isEmpty ? 0.0 : "#VALUE!" }
            let (nper, pmt, pv) = (rateNums[0], rateNums[1], rateNums[2])
            guard nper > 0 else { return "#NUM!" }
            var guess = 0.1
            for _ in 0..<100 {
                let g1 = pow(1 + guess, nper)
                let f = pv * g1 + pmt * (g1 - 1) / guess
                let g0 = pow(1 + guess, nper - 1)
                let df = pv * nper * g0 + pmt * (nper * g0 * guess - (g1 - 1)) / (guess * guess)
                if abs(df) < 1e-15 { break }
                let next = guess - f / df
                if abs(next - guess) < 1e-10 { guess = next; break }
                guess = next
            }
            return guess

        case "NPV":
            // NPV(rate, value1, value2, ...) OR NPV(rate, range)
            let parts = splitArgs(args)
            guard !parts.isEmpty else { return 0.0 }
            let r = try evaluateExpression(parts[0].trimmingCharacters(in: .whitespaces), in: sheet)
            guard let rate = r as? Double else { return "#VALUE!" }
            if parts.count < 2 { return 0.0 }
            let cashFlowArgs = parts.dropFirst().map { String($0) }.joined(separator: ",")
            let values = try resolveNumericValues(cashFlowArgs, in: sheet)
            var npv = 0.0
            for (i, cf) in values.enumerated() {
                npv += cf / pow(1 + rate, Double(i + 1))
            }
            return npv

        case "IRR":
            // IRR(values) — Newton's method
            let values = try resolveNumericValues(args, in: sheet)
            guard values.count >= 2 else { return values.isEmpty ? 0.0 : "#NUM!" }
            var guess = 0.1
            for _ in 0..<200 {
                var npv = 0.0
                var dnpv = 0.0
                for (i, cf) in values.enumerated() {
                    let t = Double(i)
                    npv += cf / pow(1 + guess, t)
                    dnpv -= t * cf / pow(1 + guess, t + 1)
                }
                if abs(dnpv) < 1e-15 { break }
                let next = guess - npv / dnpv
                if abs(next - guess) < 1e-10 { guess = next; break }
                guess = next
            }
            return guess

        // MARK: Logical (AND, OR, NOT, IFERROR, TRUE, FALSE)

        case "AND":
            let parts = splitArgs(args)
            for part in parts {
                let val = try evaluateExpression(part, in: sheet)
                if let num = val as? Double, num == 0 { return 0.0 }
                else if let str = val as? String, str.uppercased() == "FALSE" { return 0.0 }
            }
            return 1.0

        case "OR":
            let parts = splitArgs(args)
            for part in parts {
                let val = try evaluateExpression(part, in: sheet)
                if let num = val as? Double, num != 0 { return 1.0 }
                else if let str = val as? String, str.uppercased() == "TRUE" { return 1.0 }
            }
            return 0.0

        case "NOT":
            let val = try evaluateExpression(args, in: sheet)
            if let num = val as? Double { return num == 0 ? 1.0 : 0.0 }
            if let str = val as? String, str.uppercased() == "TRUE" { return 0.0 }
            return 1.0

        case "IFERROR":
            let parts = splitArgs(args)
            guard parts.count >= 2 else { return "#VALUE!" }
            let val = try evaluateExpression(parts[0], in: sheet)
            if let str = val as? String, str.hasPrefix("#") {
                return try evaluateExpression(parts[1], in: sheet)
            }
            return val

        case "TRUE":
            return 1.0

        case "FALSE":
            return 0.0

        // MARK: Date & Time

        case "NOW":
            let df = DateFormatter()
            df.dateFormat = "yyyy-MM-dd HH:mm:ss"
            return df.string(from: Date())

        case "TODAY":
            let df = DateFormatter()
            df.dateFormat = "yyyy-MM-dd"
            return df.string(from: Date())

        case "DATE":
            let parts = splitArgs(args)
            guard parts.count >= 3 else { return "#VALUE!" }
            let y = try evaluateExpression(parts[0], in: sheet)
            let m = try evaluateExpression(parts[1], in: sheet)
            let d = try evaluateExpression(parts[2], in: sheet)
            if let year = y as? Double, let month = m as? Double, let day = d as? Double {
                var comps = DateComponents()
                comps.year = Int(year); comps.month = Int(month); comps.day = Int(day)
                if let date = Calendar.current.date(from: comps) {
                    let df = DateFormatter()
                    df.dateFormat = "yyyy-MM-dd"
                    return df.string(from: date)
                }
            }
            return "#VALUE!"

        case "YEAR":
            let val = try evaluateExpression(args, in: sheet)
            if let str = val as? String, let date = parseSimpleDate(str) {
                return Double(Calendar.current.component(.year, from: date))
            }
            return "#VALUE!"

        case "MONTH":
            let val = try evaluateExpression(args, in: sheet)
            if let str = val as? String, let date = parseSimpleDate(str) {
                return Double(Calendar.current.component(.month, from: date))
            }
            return "#VALUE!"

        case "DAY":
            let val = try evaluateExpression(args, in: sheet)
            if let str = val as? String, let date = parseSimpleDate(str) {
                return Double(Calendar.current.component(.day, from: date))
            }
            return "#VALUE!"

        case "HOUR":
            let val = try evaluateExpression(args, in: sheet)
            if let str = val as? String, let date = parseSimpleDate(str) {
                return Double(Calendar.current.component(.hour, from: date))
            }
            return "#VALUE!"

        case "MINUTE":
            let val = try evaluateExpression(args, in: sheet)
            if let str = val as? String, let date = parseSimpleDate(str) {
                return Double(Calendar.current.component(.minute, from: date))
            }
            return "#VALUE!"

        case "SECOND":
            let val = try evaluateExpression(args, in: sheet)
            if let str = val as? String, let date = parseSimpleDate(str) {
                return Double(Calendar.current.component(.second, from: date))
            }
            return "#VALUE!"

        // MARK: Reference

        case "VLOOKUP":
            // VLOOKUP(lookup_value, table_range, col_index, [range_lookup])
            let parts = splitArgs(args)
            guard parts.count >= 3 else { return "#VALUE!" }
            let lookup = try evaluateExpression(parts[0], in: sheet)
            let lookupStr = "\(lookup is Double ? (lookup as! Double == (lookup as! Double).rounded() ? String(Int(lookup as! Double)) : String(lookup as! Double)) : "\(lookup)")"
            let colIdx = try evaluateExpression(parts[2], in: sheet)
            guard let colIndex = colIdx as? Double, Int(colIndex) >= 1 else { return "#VALUE!" }
            // Parse range
            let rangeParts = parts[1].trimmingCharacters(in: .whitespaces).split(separator: ":")
            guard rangeParts.count == 2,
                  let start = CellReference(string: String(rangeParts[0])),
                  let end = CellReference(string: String(rangeParts[1])) else { return "#REF!" }
            let targetCol = start.col + Int(colIndex) - 1
            guard targetCol <= end.col else { return "#REF!" }
            for r in start.row...end.row {
                let cellVal = sheet.cell(row: r, column: start.col).value
                if cellVal == lookupStr {
                    let result = sheet.cell(row: r, column: targetCol)
                    return Double(result.value) ?? result.value as Any
                }
            }
            return "#N/A"

        case "HLOOKUP":
            let parts = splitArgs(args)
            guard parts.count >= 3 else { return "#VALUE!" }
            let lookup = try evaluateExpression(parts[0], in: sheet)
            let lookupStr = "\(lookup is Double ? (lookup as! Double == (lookup as! Double).rounded() ? String(Int(lookup as! Double)) : String(lookup as! Double)) : "\(lookup)")"
            let rowIdx = try evaluateExpression(parts[2], in: sheet)
            guard let rowIndex = rowIdx as? Double, Int(rowIndex) >= 1 else { return "#VALUE!" }
            let rangeParts = parts[1].trimmingCharacters(in: .whitespaces).split(separator: ":")
            guard rangeParts.count == 2,
                  let start = CellReference(string: String(rangeParts[0])),
                  let end = CellReference(string: String(rangeParts[1])) else { return "#REF!" }
            let targetRow = start.row + Int(rowIndex) - 1
            guard targetRow <= end.row else { return "#REF!" }
            for c in start.col...end.col {
                let cellVal = sheet.cell(row: start.row, column: c).value
                if cellVal == lookupStr {
                    let result = sheet.cell(row: targetRow, column: c)
                    return Double(result.value) ?? result.value as Any
                }
            }
            return "#N/A"

        case "INDEX":
            // INDEX(array, row_num, col_num)
            let parts = splitArgs(args)
            guard parts.count >= 2 else { return "#VALUE!" }
            let rangeParts = parts[0].trimmingCharacters(in: .whitespaces).split(separator: ":")
            guard rangeParts.count == 2,
                  let start = CellReference(string: String(rangeParts[0])),
                  let end = CellReference(string: String(rangeParts[1])) else { return "#REF!" }
            let rn = try evaluateExpression(parts[1], in: sheet)
            guard let rowNum = rn as? Double else { return "#VALUE!" }
            let colNum: Int
            if parts.count >= 3 {
                let cn = try evaluateExpression(parts[2], in: sheet)
                colNum = (cn as? Double).map { Int($0) } ?? 1
            } else { colNum = 1 }
            let targetRow = start.row + Int(rowNum) - 1
            let targetCol = start.col + colNum - 1
            guard targetRow >= start.row, targetRow <= end.row,
                  targetCol >= start.col, targetCol <= end.col else { return "#REF!" }
            let cell = sheet.cell(row: targetRow, column: targetCol)
            return Double(cell.value) ?? cell.value as Any

        case "MATCH":
            // MATCH(lookup_value, lookup_array, [match_type])
            let parts = splitArgs(args)
            guard parts.count >= 2 else { return "#VALUE!" }
            let lookup = try evaluateExpression(parts[0], in: sheet)
            let lookupStr = lookup is Double ? (lookup as! Double == (lookup as! Double).rounded() ? String(Int(lookup as! Double)) : String(lookup as! Double)) : "\(lookup)"
            let rangeParts = parts[1].trimmingCharacters(in: .whitespaces).split(separator: ":")
            guard rangeParts.count == 2,
                  let start = CellReference(string: String(rangeParts[0])),
                  let end = CellReference(string: String(rangeParts[1])) else { return "#REF!" }
            // Exact match (match_type=0) by default for simplicity
            if start.col == end.col {
                for r in start.row...end.row {
                    if sheet.cell(row: r, column: start.col).value == lookupStr {
                        return Double(r - start.row + 1)
                    }
                }
            } else {
                for c in start.col...end.col {
                    if sheet.cell(row: start.row, column: c).value == lookupStr {
                        return Double(c - start.col + 1)
                    }
                }
            }
            return "#N/A"

        case "CHOOSE":
            // CHOOSE(index_num, value1, value2, ...)
            let parts = splitArgs(args)
            guard parts.count >= 2 else { return "#VALUE!" }
            let idx = try evaluateExpression(parts[0], in: sheet)
            guard let index = idx as? Double, Int(index) >= 1, Int(index) < parts.count else { return "#VALUE!" }
            return try evaluateExpression(parts[Int(index)], in: sheet)

        // MARK: Text (FIND, REPLACE, SUBSTITUTE)

        case "FIND":
            let parts = splitArgs(args)
            guard parts.count >= 2 else { return "#VALUE!" }
            let findText = try evaluateExpression(parts[0], in: sheet)
            let withinText = try evaluateExpression(parts[1], in: sheet)
            if let ft = findText as? String, let wt = withinText as? String {
                if let range = wt.range(of: ft) {
                    return Double(wt.distance(from: wt.startIndex, to: range.lowerBound) + 1)
                }
                return "#VALUE!"
            }
            return "#VALUE!"

        case "REPLACE":
            let parts = splitArgs(args)
            guard parts.count >= 4 else { return "#VALUE!" }
            let oldText = try evaluateExpression(parts[0], in: sheet)
            let startNum = try evaluateExpression(parts[1], in: sheet)
            let numChars = try evaluateExpression(parts[2], in: sheet)
            let newText = try evaluateExpression(parts[3], in: sheet)
            if let ot = oldText as? String, let s = startNum as? Double,
               let n = numChars as? Double, let nt = newText as? String {
                var str = ot
                let startIdx = str.index(str.startIndex, offsetBy: max(0, Int(s) - 1))
                let endIdx = str.index(startIdx, offsetBy: min(Int(n), str.count - Int(s) + 1))
                str.replaceSubrange(startIdx..<endIdx, with: nt)
                return str
            }
            return "#VALUE!"

        case "SUBSTITUTE":
            let parts = splitArgs(args)
            guard parts.count >= 3 else { return "#VALUE!" }
            let text = try evaluateExpression(parts[0], in: sheet)
            let oldT = try evaluateExpression(parts[1], in: sheet)
            let newT = try evaluateExpression(parts[2], in: sheet)
            if let t = text as? String, let o = oldT as? String, let n = newT as? String {
                return t.replacingOccurrences(of: o, with: n)
            }
            return "#VALUE!"

        // MARK: Math (SUMIF, COUNTIF, PRODUCT)

        case "SUMIF":
            // SUMIF(range, criteria, [sum_range])
            let parts = splitArgs(args)
            guard parts.count >= 2 else { return "#VALUE!" }
            let rangeParts = parts[0].trimmingCharacters(in: .whitespaces).split(separator: ":")
            guard rangeParts.count == 2,
                  let start = CellReference(string: String(rangeParts[0])),
                  let end = CellReference(string: String(rangeParts[1])) else { return "#VALUE!" }
            let criteria = parts[1].trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "\"", with: "")
            // Optional sum_range
            var sumStart = start, sumEnd = end
            if parts.count >= 3 {
                let sr = parts[2].trimmingCharacters(in: .whitespaces).split(separator: ":")
                if sr.count == 2, let s = CellReference(string: String(sr[0])), let e = CellReference(string: String(sr[1])) {
                    sumStart = s; sumEnd = e
                }
            }
            var total = 0.0
            for r in start.row...end.row {
                for c in start.col...end.col {
                    let val = sheet.cell(row: r, column: c).value
                    if matchesCriteria(val, criteria) {
                        let sumR = sumStart.row + (r - start.row)
                        let sumC = sumStart.col + (c - start.col)
                        if sumR <= sumEnd.row, sumC <= sumEnd.col {
                            total += Double(sheet.cell(row: sumR, column: sumC).value) ?? 0
                        }
                    }
                }
            }
            return total

        case "COUNTIF":
            let parts = splitArgs(args)
            guard parts.count >= 2 else { return "#VALUE!" }
            let rangeParts = parts[0].trimmingCharacters(in: .whitespaces).split(separator: ":")
            guard rangeParts.count == 2,
                  let start = CellReference(string: String(rangeParts[0])),
                  let end = CellReference(string: String(rangeParts[1])) else { return "#VALUE!" }
            let criteria = parts[1].trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "\"", with: "")
            var count = 0.0
            for r in start.row...end.row {
                for c in start.col...end.col {
                    if matchesCriteria(sheet.cell(row: r, column: c).value, criteria) {
                        count += 1
                    }
                }
            }
            return count

        case "PRODUCT":
            let values = try resolveNumericValues(args, in: sheet)
            return values.isEmpty ? 0.0 : values.reduce(1, *)

        default:
            return "#NAME?"
        }
    }

    // MARK: - Helpers for criteria matching

    private static func matchesCriteria(_ value: String, _ criteria: String) -> Bool {
        // Handle comparison operators in criteria: ">5", "<=10", "<>abc"
        if criteria.hasPrefix(">="), let threshold = Double(String(criteria.dropFirst(2))),
           let val = Double(value) { return val >= threshold }
        if criteria.hasPrefix("<="), let threshold = Double(String(criteria.dropFirst(2))),
           let val = Double(value) { return val <= threshold }
        if criteria.hasPrefix("<>") { return value != String(criteria.dropFirst(2)) }
        if criteria.hasPrefix(">"), let threshold = Double(String(criteria.dropFirst(1))),
           let val = Double(value) { return val > threshold }
        if criteria.hasPrefix("<"), let threshold = Double(String(criteria.dropFirst(1))),
           let val = Double(value) { return val < threshold }
        if criteria.hasPrefix("=") { return value == String(criteria.dropFirst(1)) }
        // Direct match
        return value == criteria
    }

    /// Parse simple date formats
    private static func parseSimpleDate(_ str: String) -> Date? {
        let formats = ["yyyy-MM-dd HH:mm:ss", "yyyy-MM-dd", "MM/dd/yyyy", "dd/MM/yyyy", "yyyy/MM/dd"]
        for fmt in formats {
            let df = DateFormatter()
            df.dateFormat = fmt
            if let date = df.date(from: str) { return date }
        }
        return nil
    }

    // MARK: - Resolve Values

    /// Resolve comma-separated args to individual numeric values (not expanding ranges).
    /// Used for functions like PMT(rate, nper, pv) where each arg is a single number.
    private static func resolveNumericArgs(_ args: String, in sheet: STExcelSheet, expected: Int) throws -> [Double] {
        let trimmed = args.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty { return [] }
        let parts = splitArgs(trimmed)
        var result: [Double] = []
        for part in parts {
            let val = try evaluateExpression(part.trimmingCharacters(in: .whitespaces), in: sheet)
            if let num = val as? Double {
                result.append(num)
            } else if let str = val as? String, let num = Double(str) {
                result.append(num)
            }
            // Skip non-numeric args silently
        }
        return result
    }

    private static func resolveNumericValues(_ args: String, in sheet: STExcelSheet) throws -> [Double] {
        var values: [Double] = []

        let parts = splitArgs(args)
        for part in parts {
            let trimmed = part.trimmingCharacters(in: .whitespaces)

            // Range reference: A1:B5
            if trimmed.contains(":") {
                let rangeParts = trimmed.split(separator: ":")
                guard rangeParts.count == 2,
                      let start = CellReference(string: String(rangeParts[0])),
                      let end = CellReference(string: String(rangeParts[1])) else { continue }

                for r in start.row...end.row {
                    for c in start.col...end.col {
                        let cell = sheet.cell(row: r, column: c)
                        // Prefer cached value from xlsx
                        if let num = Double(cell.value) {
                            values.append(num)
                        } else if let formula = cell.formula {
                            let cellKey = "\(r),\(c)"
                            guard !evaluatingCells.contains(cellKey) else { continue }
                            evaluatingCells.insert(cellKey)
                            let val = evaluate(formula, in: sheet)
                            evaluatingCells.remove(cellKey)
                            if let num = Double(val) { values.append(num) }
                        }
                    }
                }
            } else if let ref = CellReference(string: trimmed) {
                let cell = sheet.cell(row: ref.row, column: ref.col)
                // Prefer cached value from xlsx
                if let num = Double(cell.value) {
                    values.append(num)
                } else if let formula = cell.formula {
                    let cellKey = "\(ref.row),\(ref.col)"
                    guard !evaluatingCells.contains(cellKey) else { continue }
                    evaluatingCells.insert(cellKey)
                    let val = evaluate(formula, in: sheet)
                    evaluatingCells.remove(cellKey)
                    if let num = Double(val) { values.append(num) }
                }
            } else if let num = Double(trimmed) {
                values.append(num)
            }
        }

        return values
    }

    private static func resolveAllValues(_ args: String, in sheet: STExcelSheet) throws -> [String] {
        var values: [String] = []

        let parts = splitArgs(args)
        for part in parts {
            let trimmed = part.trimmingCharacters(in: .whitespaces)
            if trimmed.contains(":") {
                let rangeParts = trimmed.split(separator: ":")
                guard rangeParts.count == 2,
                      let start = CellReference(string: String(rangeParts[0])),
                      let end = CellReference(string: String(rangeParts[1])) else { continue }
                for r in start.row...end.row {
                    for c in start.col...end.col {
                        values.append(sheet.cell(row: r, column: c).value)
                    }
                }
            } else if let ref = CellReference(string: trimmed) {
                values.append(sheet.cell(row: ref.row, column: ref.col).value)
            } else {
                values.append(trimmed)
            }
        }
        return values
    }

    // MARK: - Arithmetic

    private static func tryArithmetic(_ expr: String, in sheet: STExcelSheet) -> Double? {
        // Simple arithmetic: supports +, -, *, / with cell references and numbers
        // Tokenize
        var tokens: [(op: Character?, value: String)] = []
        var current = ""
        var depth = 0

        for char in expr {
            if char == "(" { depth += 1; current.append(char) }
            else if char == ")" { depth -= 1; current.append(char) }
            else if depth == 0 && "+-*/".contains(char) && !current.isEmpty {
                tokens.append((op: nil, value: current.trimmingCharacters(in: .whitespaces)))
                tokens.append((op: char, value: ""))
                current = ""
            } else {
                current.append(char)
            }
        }
        if !current.isEmpty {
            tokens.append((op: nil, value: current.trimmingCharacters(in: .whitespaces)))
        }

        // Need at least 3 tokens (val op val) to be arithmetic
        let valueTokens = tokens.filter { $0.op == nil }
        let opTokens = tokens.filter { $0.op != nil }
        guard valueTokens.count >= 2, opTokens.count >= 1 else { return nil }

        // Resolve all values
        var values: [Double] = []
        var ops: [Character] = []

        for token in tokens {
            if let op = token.op {
                ops.append(op)
            } else {
                let val = token.value
                if let num = Double(val) {
                    values.append(num)
                } else if let ref = CellReference(string: val) {
                    let cell = sheet.cell(row: ref.row, column: ref.col)
                    // Prefer cached value from xlsx
                    if let num = Double(cell.value) {
                        values.append(num)
                    } else if let formula = cell.formula {
                        let cellKey = "\(ref.row),\(ref.col)"
                        guard !evaluatingCells.contains(cellKey) else { return nil }
                        evaluatingCells.insert(cellKey)
                        let computed = evaluate(formula, in: sheet)
                        evaluatingCells.remove(cellKey)
                        if let num = Double(computed) { values.append(num) } else { return nil }
                    } else { return nil }
                } else {
                    // Try evaluating as sub-expression
                    do {
                        let result = try evaluateExpression(val, in: sheet)
                        if let num = result as? Double { values.append(num) } else { return nil }
                    } catch { return nil }
                }
            }
        }

        guard values.count == ops.count + 1 else { return nil }

        // Evaluate: * and / first, then + and -
        // First pass: * and /
        var i = 0
        while i < ops.count {
            if ops[i] == "*" || ops[i] == "/" {
                if ops[i] == "*" {
                    values[i] = values[i] * values[i + 1]
                } else {
                    if values[i + 1] == 0 { return nil } // div by zero
                    values[i] = values[i] / values[i + 1]
                }
                values.remove(at: i + 1)
                ops.remove(at: i)
            } else {
                i += 1
            }
        }

        // Second pass: + and -
        var result = values[0]
        for j in 0..<ops.count {
            if ops[j] == "+" { result += values[j + 1] }
            else if ops[j] == "-" { result -= values[j + 1] }
        }

        return result
    }

    // MARK: - Helpers

    /// Split comma-separated arguments, respecting parentheses depth
    private static func splitArgs(_ args: String) -> [String] {
        var result: [String] = []
        var current = ""
        var depth = 0

        for char in args {
            if char == "(" { depth += 1; current.append(char) }
            else if char == ")" { depth -= 1; current.append(char) }
            else if char == "," && depth == 0 {
                result.append(current.trimmingCharacters(in: .whitespaces))
                current = ""
            } else {
                current.append(char)
            }
        }
        if !current.isEmpty {
            result.append(current.trimmingCharacters(in: .whitespaces))
        }
        return result
    }

    /// Compare two values (for IF conditions like A1>5)
    static func evaluateComparison(_ expr: String, in sheet: STExcelSheet) -> Bool {
        let operators = [">=", "<=", "<>", "!=", ">", "<", "="]
        for op in operators {
            if let range = expr.range(of: op) {
                let left = String(expr[expr.startIndex..<range.lowerBound]).trimmingCharacters(in: .whitespaces)
                let right = String(expr[range.upperBound...]).trimmingCharacters(in: .whitespaces)
                let lVal = (try? evaluateExpression(left, in: sheet)) ?? left
                let rVal = (try? evaluateExpression(right, in: sheet)) ?? right
                let lNum = lVal as? Double ?? Double("\(lVal)")
                let rNum = rVal as? Double ?? Double("\(rVal)")

                if let l = lNum, let r = rNum {
                    switch op {
                    case ">": return l > r
                    case "<": return l < r
                    case ">=": return l >= r
                    case "<=": return l <= r
                    case "=": return l == r
                    case "<>", "!=": return l != r
                    default: return false
                    }
                }
            }
        }
        return false
    }
}
