import Foundation

/// What a stated result turned out to be once the arithmetic was done exactly.
public struct ArithmeticFinding: Sendable, Hashable {
    public enum Outcome: Sendable, Hashable {
        /// The exact value.
        case exact
        /// The exact value rounded to the digits written (either way at a tie), or cut short with `...`.
        case rounded
        /// Marked approximate and within the policy's tolerance.
        case approximate
        /// Within one step of the last written digit, but not how the value rounds.
        case misrounded(correct: Decimal)
        case wrong(correct: Decimal)
        /// A change of the right size in the wrong direction.
        case wrongDirection
        /// A difference in percentage points written as a percent change (`from 40% to 50%, a 10%
        /// increase`); `points` is that difference.
        case pointsAsPercent(points: Decimal)
        /// The statement divides by zero, or a change starts from zero.
        case undefined
    }

    public enum Severity: Int, Sendable, Hashable, Comparable {
        case holds
        case caution
        case wrong

        public static func < (lhs: Severity, rhs: Severity) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }

    public let claim: ArithmeticClaim
    public let outcome: Outcome
    public let severity: Severity
    /// The exact value of the statement; `nil` when it has none.
    public let computed: Decimal?
    /// Flagged in an earlier review of the same conversation (set by `ArithmeticLedger`).
    public internal(set) var isRepeated = false

    /// Identifies the same claim across rewrites: statement and result, without spacing or case.
    var key: String {
        (claim.statement + "=" + claim.claimedText).lowercased().filter { !$0.isWhitespace }
    }
}
