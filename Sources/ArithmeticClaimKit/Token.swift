/// The four operations an answer writes out.
enum ArithmeticOperator: String, Sendable, Hashable {
    case plus = "+"
    case minus = "-"
    case times = "×"
    case dividedBy = "/"
}

/// What a stretch of text means to the readers.
enum TokenKind: Sendable, Hashable {
    case number(WrittenNumber)
    case operation(ArithmeticOperator)
    /// `^` (exponent follows) or superscript digits (exponent known).
    case power(Int?)
    /// `of`, as in `15% of 80`.
    case of
    case open
    case close
    /// `=`, `≈`, `is`, `equals`, `comes to`; `isWord` for the spelled-out ones.
    case equals(isWord: Bool, isApproximate: Bool)
    /// `about`, `roughly`, `~`.
    case approximately
    case comma
    case word(String)
    /// The end of a sentence, a line or a clause no claim runs across.
    case stop
}

/// A token and the characters of the text it was read from.
struct Token: Sendable, Hashable {
    let kind: TokenKind
    let range: Range<Int>
}

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

extension Character {
    /// The value of an ASCII digit; `nil` for anything else, including other scripts' digits.
    var asciiDigit: Int? {
        isASCII ? wholeNumberValue : nil
    }
}
