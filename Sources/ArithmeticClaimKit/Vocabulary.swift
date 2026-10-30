import Foundation

/// The words and letters the readers give a meaning to. Every other word is just a word.
enum Vocabulary {
    /// Scale letters written straight after the digits: `5k`, `3M`, `2bn`. Case matters (`3m` is metres).
    static let attachedScales: [String: Decimal] = [
        "k": 1_000, "K": 1_000, "M": 1_000_000, "bn": 1_000_000_000, "B": 1_000_000_000
    ]

    /// Scale words written after a number: `1.2 million`, `3 lakh`.
    static let scaleWords: [String: Decimal] = [
        "thousand": 1_000, "million": 1_000_000, "billion": 1_000_000_000, "trillion": 1_000_000_000_000,
        "lakh": 100_000, "lakhs": 100_000, "crore": 10_000_000, "crores": 10_000_000
    ]

    /// Units a number may carry, attached or after a space. They stay in the text; nothing converts them.
    static let units: Set<String> = [
        "kg", "g", "mg", "km", "m", "cm", "mm", "mi", "ft", "h", "hr", "hrs", "min", "mins", "s", "sec", "secs",
        "ms", "gb", "mb", "kb", "tb", "kwh", "w", "kw", "mph", "l", "ml", "lb", "lbs", "oz", "usd", "eur", "inr",
        "gbp", "dollars", "euros", "rupees", "hours", "minutes", "seconds", "days", "weeks", "months", "years",
        "miles", "metres", "meters", "kilometres", "kilometers", "grams", "kilograms", "litres", "liters",
        "items", "units", "tokens", "users", "people"
    ]

    static let operators: [String: ArithmeticOperator] = [
        "plus": .plus, "minus": .minus, "times": .times, "x": .times
    ]

    /// Two-word forms, keyed by the first word: `multiplied by`, `equal to`, `works out to`.
    static let pairs: [String: [String: TokenKind]] = [
        "multiplied": ["by": .operation(.times)],
        "divided": ["by": .operation(.dividedBy)],
        "equal": ["to": wordEquals],
        "comes": ["to": wordEquals],
        "come": ["to": wordEquals],
        "works": ["out": .word("works out")],
        "works out": ["to": wordEquals]
    ]

    static let equalityWords: Set<String> = ["is", "equals", "gives", "makes", "yields", "totals"]

    static let approximations: Set<String> = [
        "about", "approximately", "approx", "roughly", "around", "nearly", "almost"
    ]

    static let increases: Set<String> = [
        "increase", "increases", "increased", "rise", "rises", "rose", "risen", "grew", "grow", "grows",
        "growth", "gain", "gains", "gained", "up", "jump", "jumped", "climb", "climbed", "higher", "more"
    ]

    static let decreases: Set<String> = [
        "decrease", "decreases", "decreased", "decline", "declines", "declined", "drop", "drops", "dropped",
        "fell", "fall", "falls", "fallen", "down", "lower", "cut", "reduction", "less", "shrank", "loss"
    ]

    static let neutralChanges: Set<String> = ["change", "changed", "difference"]

    static let pointWords: Set<String> = ["point", "points", "pp", "pts", "ppt"]

    /// Words that start another clause, so a percentage after them is about something else.
    static let barriers: Set<String> = ["while", "whereas", "but", "although", "however", "meanwhile", "and"]

    /// Words allowed between a comma and the equality that follows it: `15% of 80, which is 12`.
    static let relatives: Set<String> = ["which", "that", "this"]

    /// Words allowed between a result and the operator that continues it: `48, then plus 10`.
    static let continuations: Set<String> = ["then", "and", "so", "which"]

    static let superscripts: [Character: Int] = [
        "⁰": 0, "¹": 1, "²": 2, "³": 3, "⁴": 4, "⁵": 5, "⁶": 6, "⁷": 7, "⁸": 8, "⁹": 9
    ]

    static let currencies: Set<Character> = ["$", "€", "£", "₹", "¥"]

    /// Single characters whose meaning never depends on what is around them.
    static let symbols: [Character: TokenKind] = [
        "+": .operation(.plus), "-": .operation(.minus), "−": .operation(.minus), "–": .operation(.minus),
        "×": .operation(.times), "✕": .operation(.times), "·": .operation(.times), "⋅": .operation(.times),
        "∙": .operation(.times), "/": .operation(.dividedBy), "÷": .operation(.dividedBy),
        "∕": .operation(.dividedBy), "≈": .equals(isWord: false, isApproximate: true),
        "≅": .equals(isWord: false, isApproximate: true), "(": .open, "[": .open, "{": .open, ")": .close,
        "]": .close, ",": .comma, "—": .comma, ".": .stop, "!": .stop, "?": .stop, ";": .stop, ":": .stop,
        "≠": .stop
    ]

    static let wordEquals = TokenKind.equals(isWord: true, isApproximate: false)

    /// What a single word means on its own.
    static func kind(of word: String) -> TokenKind {
        if let operation = operators[word] { return .operation(operation) }
        if word == "of" { return .of }
        if equalityWords.contains(word) { return wordEquals }
        if approximations.contains(word) { return .approximately }
        return .word(word)
    }

    /// +1 for a word that says up, -1 for down, 0 for a change with no direction, `nil` otherwise.
    static func direction(of word: String) -> Int? {
        if increases.contains(word) { return 1 }
        if decreases.contains(word) { return -1 }
        return neutralChanges.contains(word) ? 0 : nil
    }
}
