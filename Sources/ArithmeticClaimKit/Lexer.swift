import Foundation

/// Turns an answer into tokens: numbers as written, operators in symbols, words and LaTeX,
/// equality, and the stops no claim runs across. Fenced code is skipped whole.
struct Lexer {
    let characters: [Character]
    var index = 0
    var tokens: [Token] = []
    /// A currency sign just read, waiting for its digits.
    var currencyStart: Int?
    /// A `\frac` just read: the group after it starts here, so excerpts keep the command.
    var groupStart: Int?

    static func read(_ text: String) -> (tokens: [Token], characters: [Character]) {
        var lexer = Lexer(characters: Array(text))
        lexer.run()
        return (lexer.tokens, lexer.characters)
    }

    private init(characters: [Character]) {
        self.characters = characters
    }

    private mutating func run() {
        while let character = characters[safe: index] {
            if character.asciiDigit != nil || (character == "." && characters[safe: index + 1]?.asciiDigit != nil) {
                readNumber()
            } else if character.isLetter {
                readWord()
            } else if character == "\\" {
                readCommand()
            } else if character == "`" {
                skipCode()
            } else {
                readSymbol(character)
            }
        }
    }

    // MARK: - Numbers

    private mutating func readNumber() {
        let start = currencyStart ?? index
        let prefix = currencyStart.map { String(characters[$0]) } ?? ""
        currencyStart = nil
        var digits: [Int] = []
        var decimals = 0
        while let digit = characters[safe: index]?.asciiDigit {
            digits.append(digit)
            index += 1
            if characters[safe: index] == ",", isDigitGroup(at: index + 1) { index += 1 }
        }
        if characters[safe: index] == ".", characters[safe: index + 1]?.asciiDigit != nil {
            index += 1
            while let digit = characters[safe: index]?.asciiDigit {
                digits.append(digit)
                decimals += 1
                index += 1
            }
        }
        let truncated = skipEllipsis()
        let percent = characters[safe: index] == "%"
        if percent { index += 1 }
        var scale: Decimal = percent ? .hundredth : 1
        var suffix = percent ? "%" : ""
        if !percent, characters[safe: index]?.isLetter == true {
            let letters = readLetters()
            if let multiplier = Vocabulary.attachedScales[letters] {
                scale = multiplier
            } else if !Vocabulary.units.contains(letters.lowercased()) {
                // `3rd`, `2x`, `4G`: not a quantity.
                append(.word(text(from: start).lowercased()), from: start)
                return
            }
            suffix = letters
        }
        guard digits.count <= 30 else {
            append(.word(text(from: start)), from: start)
            return
        }
        let number = WrittenNumber(
            digits: digits.reduce(Decimal(0)) { $0 * 10 + Decimal($1) },
            decimals: decimals,
            scale: scale,
            suffix: suffix,
            prefix: prefix,
            isPercent: percent,
            isTruncated: truncated,
            text: text(from: start)
        )
        append(.number(number), from: start)
    }

    private func isDigitGroup(at position: Int) -> Bool {
        (0..<3).allSatisfy { characters[safe: position + $0]?.asciiDigit != nil }
            && characters[safe: position + 3]?.asciiDigit == nil
    }

    private mutating func skipEllipsis() -> Bool {
        if characters[safe: index] == "…" {
            index += 1
            return true
        }
        guard (0..<3).allSatisfy({ characters[safe: index + $0] == "." }) else { return false }
        index += 3
        return true
    }

    // MARK: - Words

    private mutating func readWord() {
        let start = index
        let word = readLetters().lowercased()
        if word == "approx", characters[safe: index] == "." { index += 1 }
        if absorbIntoNumber(word) { return }
        if case .word(let previous)? = tokens.last?.kind, let kind = Vocabulary.pairs[previous]?[word] {
            let first = tokens.removeLast().range.lowerBound
            append(kind, from: first)
            return
        }
        append(Vocabulary.kind(of: word), from: start)
    }

    /// A scale word, unit, `percent` or `per cent` after a number becomes part of it.
    private mutating func absorbIntoNumber(_ word: String) -> Bool {
        if word == "cent", case .word("per")? = tokens.last?.kind,
           case .number(let number)? = tokens[safe: tokens.count - 2]?.kind, !number.isPercent {
            tokens.removeLast()
            extendLast(number.adding(scale: .hundredth, suffix: "%", percent: true, text: ""))
            return true
        }
        guard case .number(let number)? = tokens.last?.kind else { return false }
        if let multiplier = Vocabulary.scaleWords[word], number.scale == 1 {
            extendLast(number.adding(scale: multiplier, suffix: " " + word, text: ""))
        } else if word == "percent" || word == "pct", !number.isPercent {
            extendLast(number.adding(scale: .hundredth, suffix: "%", percent: true, text: ""))
        } else if Vocabulary.units.contains(word) {
            extendLast(number.adding(suffix: " " + word, text: ""))
        } else {
            return false
        }
        return true
    }

    mutating func readLetters() -> String {
        let start = index
        while characters[safe: index]?.isLetter == true { index += 1 }
        return text(from: start)
    }

    // MARK: - Output

    func text(from start: Int) -> String {
        String(characters[start..<index])
    }

    mutating func append(_ kind: TokenKind, from start: Int) {
        var start = start
        if kind == .open, let group = groupStart {
            start = group
            groupStart = nil
        }
        tokens.append(Token(kind: kind, range: start..<max(index, start)))
    }

    /// Replaces the last token, a number, with `number` and stretches it to the current position.
    mutating func extendLast(_ number: WrittenNumber) {
        let start = tokens.removeLast().range.lowerBound
        let extended = number.adding(suffix: "", text: text(from: start))
        tokens.append(Token(kind: .number(extended), range: start..<index))
    }
}
