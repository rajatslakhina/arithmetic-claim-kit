import Foundation

/// The result a claim states, with what it takes to judge it and to write a correction its way.
struct ClaimedValue: Sendable, Hashable {
    let value: Decimal
    /// One step in the last written digit; a correct result rounds to a multiple of it.
    let quantum: Decimal
    let decimals: Int
    /// What a value is divided by before it is written (0.01 writes 0.25 as `25%`).
    let scale: Decimal
    let prefix: String
    let suffix: String
    let isTruncated: Bool

    init(number: WrittenNumber, isNegative: Bool) {
        value = isNegative ? -number.value : number.value
        quantum = number.quantum
        decimals = number.decimals
        scale = number.scale
        prefix = number.prefix
        suffix = number.suffix
        isTruncated = number.isTruncated
    }

    /// An expression given as the result (`= 7 × 2`), judged to its finest written digit.
    private init?(expression: Expression) {
        guard let value = expression.value else { return nil }
        let numbers = expression.numbers
        self.value = value
        quantum = numbers.map(\.quantum).reduce(Decimal.greatestFiniteMagnitude) { Swift.min($0, $1) }
        decimals = numbers.map(\.decimals).reduce(0) { Swift.max($0, $1) }
        scale = 1
        prefix = ""
        suffix = ""
        isTruncated = false
    }

    /// The percentage in a change, signed by its direction word; points are hundredths.
    init(change figure: WrittenNumber, sign: Int, points: Bool) {
        let factor: Decimal = points && !figure.isPercent ? .hundredth : 1
        value = figure.value * factor * (sign < 0 ? -1 : 1)
        quantum = figure.quantum * factor
        decimals = figure.decimals
        scale = figure.scale * factor
        prefix = ""
        suffix = points ? " percentage-point" : "%"
        isTruncated = figure.isTruncated
    }

    /// The result an expression states: its number, or the expression's own value.
    static func of(_ expression: Expression) -> ClaimedValue? {
        if let plain = expression.plainNumber {
            return ClaimedValue(number: plain.number, isNegative: plain.isNegative)
        }
        return ClaimedValue(expression: expression)
    }

    /// The correct value written the claim's way: to its digits when that is exact, else to at
    /// least two decimals with "about".
    func correction(_ number: Decimal) -> String {
        let shown = number.magnitude / scale
        let exact = DecimalText.rounded(shown, places: decimals) == shown
        return written(number, places: exact ? decimals : Swift.max(decimals, 2), approximate: !exact)
    }

    /// `number` written the way the claim was: sign, currency, scale word or percent sign, unit.
    func written(_ number: Decimal, places: Int, approximate: Bool = false) -> String {
        let magnitude = number.magnitude / scale
        let digits = approximate
            ? DecimalText.approximate(magnitude, places: places)
            : DecimalText.text(magnitude, places: places)
        let about = digits.hasPrefix("about ") ? "about " : ""
        let sign = number < 0 ? "-" : ""
        return about + sign + prefix + digits.dropFirst(about.count) + suffix
    }
}

/// Decimal values written for people: rounded half away from zero, no trailing zeros, grouped thousands.
enum DecimalText {
    static func rounded(_ value: Decimal, places: Int) -> Decimal {
        var source = value
        var result = Decimal()
        NSDecimalRound(&result, &source, places, .plain)
        return result
    }

    static func text(_ value: Decimal, places: Int) -> String {
        let rounded = rounded(value, places: places)
        let parts = "\(rounded.magnitude)".split(separator: ".", omittingEmptySubsequences: false)
        var whole = String(parts[0])
        var grouped = ""
        while whole.count > 3 {
            grouped = "," + whole.suffix(3) + grouped
            whole.removeLast(3)
        }
        let fraction = parts.count > 1 ? "." + parts[1] : ""
        return (rounded < 0 ? "-" : "") + whole + grouped + fraction
    }

    /// Like `text`, starting "about " when rounding changed the value.
    static func approximate(_ value: Decimal, places: Int) -> String {
        (rounded(value, places: places) == value ? "" : "about ") + text(value, places: places)
    }
}
