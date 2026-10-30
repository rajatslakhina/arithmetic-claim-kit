import Foundation

/// Symbols, LaTeX commands and code fences.
extension Lexer {
    mutating func readSymbol(_ character: Character) {
        let start = index
        index += 1
        if "+-−–*".contains(character), isListMarker(at: start) { return }
        if let kind = Vocabulary.symbols[character] {
            append(kind, from: start)
            return
        }
        switch character {
        case "*":
            readStar(from: start)
        case "=":
            readEquals(from: start)
        case "~":
            readTilde(from: start)
        case "}":
            append(.close, from: start)
            // `\frac{3}{4}`: the second group divides the first.
            if characters[safe: index] == "{" { append(.operation(.dividedBy), from: index) }
        case "^":
            readCaret(from: start)
        case "%":
            readPercentSign()
        default:
            readRemaining(character, from: start)
        }
    }

    /// `=` and `==` both state a result.
    private mutating func readEquals(from start: Int) {
        while characters[safe: index] == "=" { index += 1 }
        append(.equals(isWord: false, isApproximate: false), from: start)
    }

    /// `*` multiplies; `**` (bold) is dropped.
    private mutating func readStar(from start: Int) {
        guard characters[safe: index] == "*" else {
            append(.operation(.times), from: start)
            return
        }
        while characters[safe: index] == "*" { index += 1 }
    }

    /// `~=` is approximately equal; `~` alone marks the number after it as approximate.
    private mutating func readTilde(from start: Int) {
        guard characters[safe: index] == "=" else {
            append(.approximately, from: start)
            return
        }
        index += 1
        append(.equals(isWord: false, isApproximate: true), from: start)
    }

    /// `2^10` raises; `m^2` belongs to a unit, so its exponent is skipped.
    private mutating func readCaret(from start: Int) {
        guard characters[safe: start - 1]?.isLetter == true else {
            append(.power(nil), from: start)
            return
        }
        while characters[safe: index]?.asciiDigit != nil { index += 1 }
        extendUnit()
    }

    /// `15 %` and `15\%` make the number before a percentage.
    mutating func readPercentSign() {
        guard case .number(let number)? = tokens.last?.kind, !number.isPercent else { return }
        extendLast(number.adding(scale: .hundredth, suffix: "%", percent: true, text: ""))
    }

    mutating func readRemaining(_ character: Character, from start: Int) {
        if Vocabulary.currencies.contains(character), characters[safe: index]?.asciiDigit != nil,
           !(character == "$" && opensMath(at: start)) {
            currencyStart = start
        } else if let first = Vocabulary.superscripts[character] {
            var exponent = first
            while let next = characters[safe: index].flatMap({ Vocabulary.superscripts[$0] }) {
                exponent = exponent * 10 + next
                index += 1
            }
            if characters[safe: start - 1]?.isLetter == true {
                extendUnit()
            } else {
                append(.power(exponent), from: start)
            }
        } else if character.isNewline {
            append(.stop, from: start)
        }
    }

    /// Whether a `$` before digits opens LaTeX math rather than a price: a later `$` on the same line
    /// closes it (written straight after something, with no digit after it). `$12 + $8` has none.
    private func opensMath(at position: Int) -> Bool {
        var probe = position + 1
        while let character = characters[safe: probe], !character.isNewline {
            if character == "$", characters[safe: probe - 1]?.isWhitespace == false,
               characters[safe: probe + 1]?.asciiDigit == nil {
                return true
            }
            probe += 1
        }
        return false
    }

    /// `m²` and `m^2` belong to a unit: they join the number before them, which they do not raise.
    private mutating func extendUnit() {
        guard case .number(let number)? = tokens.last?.kind else { return }
        extendLast(number)
    }

    /// A `-`, `*` or `+` that starts a line and is followed by a space marks a list item.
    private func isListMarker(at position: Int) -> Bool {
        guard characters[safe: position + 1] == " " else { return false }
        var before = position - 1
        while let character = characters[safe: before], character == " " || character == "\t" { before -= 1 }
        return characters[safe: before]?.isNewline ?? true
    }

    // MARK: - LaTeX and code

    mutating func readCommand() {
        let start = index
        index += 1
        guard characters[safe: index]?.isLetter == true else {
            readEscaped(from: start)
            return
        }
        let name = readLetters()
        switch name {
        case "times", "cdot":
            append(.operation(.times), from: start)
        case "div":
            append(.operation(.dividedBy), from: start)
        case "approx", "simeq":
            append(.equals(isWord: false, isApproximate: true), from: start)
        case "frac", "dfrac", "tfrac":
            groupStart = start
        case "left", "right":
            break
        case "text", "mathrm", "textrm", "textbf", "mathbf", "mbox", "operatorname":
            skipGroup()
        case "neq", "ne", "le", "ge", "leq", "geq", "pm":
            append(.stop, from: start)
        default:
            append(.word(name.lowercased()), from: start)
        }
    }

    /// `\(`, `\)`, `\[`, `\]`, `\,` and the like; `\%` marks a percent, `\$` a currency.
    private mutating func readEscaped(from start: Int) {
        let escaped = characters[safe: index]
        index += 1
        if escaped == "%" { readPercentSign() }
        if escaped == "$" { readRemaining("$", from: start) }
    }

    private mutating func skipGroup() {
        guard characters[safe: index] == "{" else { return }
        var depth = 0
        while let character = characters[safe: index] {
            index += 1
            if character == "{" { depth += 1 }
            if character == "}" { depth -= 1 }
            if depth == 0 { return }
        }
    }

    /// Skips a fenced block whole (code computes on its own terms); a single backtick is just dropped.
    mutating func skipCode() {
        let start = index
        guard characters[safe: index + 1] == "`", characters[safe: index + 2] == "`" else {
            index += 1
            return
        }
        index += 3
        while index < characters.count {
            if characters[index] == "`", characters[safe: index + 1] == "`", characters[safe: index + 2] == "`" {
                index += 3
                break
            }
            index += 1
        }
        append(.stop, from: start)
    }
}
