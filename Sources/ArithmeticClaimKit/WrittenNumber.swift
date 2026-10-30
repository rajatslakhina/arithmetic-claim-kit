import Foundation

/// A number as an answer wrote it.
///
/// `value` carries every marker the text gave the number (`15%` is 0.15, `1.2 million` is
/// 1,200,000), and `quantum` is what one step in its last written digit is worth (`2.35` is 0.01,
/// `3.6 million` is 100,000, `15%` is 0.01). The quantum is what separates a result that was
/// rounded from one that is wrong.
public struct WrittenNumber: Sendable, Hashable {
    /// The digits read as a whole number of their last place (`2.35` is 235).
    let digits: Decimal
    /// Digits written after the decimal point.
    public let decimals: Int
    /// What the digits were multiplied by: 1, 0.01 for a percent, 1,000,000 for `million`.
    let scale: Decimal
    /// `%`, ` million`, `k`, ` kg` and the like, so a corrected value can be written the same way.
    let suffix: String
    /// A currency sign written before the digits.
    let prefix: String
    /// Written with `%`, `percent` or `per cent`.
    public let isPercent: Bool
    /// Followed by `...` or `…`: digits cut short on purpose.
    public let isTruncated: Bool
    /// The text as written.
    public let text: String

    /// The value with scale and percent applied.
    public var value: Decimal { digits * quantum }

    /// One step in the last written digit.
    public var quantum: Decimal { Decimal.power10(-decimals) * scale }

    /// A whole number small enough to be an exponent, as in `2^10`.
    var exponent: Int? {
        guard decimals == 0, scale == 1, prefix.isEmpty, digits <= 12 else { return nil }
        return NSDecimalNumber(decimal: digits).intValue
    }

    /// The same number with a scale word, unit or percent sign read after it.
    func adding(
        scale multiplier: Decimal = 1, suffix more: String, percent: Bool = false, text newText: String
    ) -> WrittenNumber {
        WrittenNumber(
            digits: digits,
            decimals: decimals,
            scale: scale * multiplier,
            suffix: suffix + more,
            prefix: prefix,
            isPercent: isPercent || percent,
            isTruncated: isTruncated,
            text: newText
        )
    }
}

extension Decimal {
    /// Ten to the power `exponent`, exactly.
    static func power10(_ exponent: Int) -> Decimal {
        Decimal(sign: .plus, exponent: exponent, significand: 1)
    }

    /// One hundredth, exactly (a `Decimal` float literal goes through `Double` and is not exact).
    static let hundredth = power10(-2)

    /// The nearest multiple of `quantum`, using `mode` for ties.
    func rounded(toMultipleOf quantum: Decimal, _ mode: NSDecimalNumber.RoundingMode) -> Decimal {
        var ratio = self / quantum
        var whole = Decimal()
        NSDecimalRound(&whole, &ratio, 0, mode)
        return whole * quantum
    }
}
