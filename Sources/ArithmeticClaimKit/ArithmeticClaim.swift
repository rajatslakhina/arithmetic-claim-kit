import Foundation

/// One piece of arithmetic an answer states: what was computed, and the result it gives.
public struct ArithmeticClaim: Sendable, Hashable {
    public enum Direction: String, Sendable, Hashable {
        case increase
        case decrease
        case unstated
    }

    public enum Kind: Sendable, Hashable {
        /// `3 × 12 = 36`, `(40 + 60) / 2 is 50`, `12^2 = 144`, `$100 / 3 = $33.33`.
        case equation
        /// `15% of 80 is 12`, `12 is 15% of 80`.
        case percentOf
        /// `went from 40 to 50, a 25% increase`.
        case percentChange(Direction)
        /// `from 40% to 50%, up 10 percentage points`.
        case pointChange(Direction)
    }

    public let kind: Kind
    /// What was computed, written back out with the numbers as the answer wrote them.
    public let statement: String
    /// The result as the answer gave it.
    public let claimedText: String
    /// The stretch of the answer the claim was read from, exactly as written.
    public let excerpt: String
    /// Where `excerpt` sits in the answer, in characters.
    public let range: Range<Int>
    /// Stated with `≈`, `about`, `roughly` or the like.
    public let isApproximate: Bool
    let computed: Expression
    let claimed: ClaimedValue

    /// The direction a change claim states; `nil` for the other kinds.
    var direction: Direction? {
        switch kind {
        case .percentChange(let direction), .pointChange(let direction):
            return direction
        case .equation, .percentOf:
            return nil
        }
    }
}
