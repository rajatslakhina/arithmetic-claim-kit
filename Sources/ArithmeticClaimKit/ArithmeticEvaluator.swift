import Foundation

/// Does each claim's arithmetic exactly, in `Decimal`, and says how the stated result compares.
public struct ArithmeticEvaluator: Sendable {
    public let policy: ArithmeticPolicy

    public init(policy: ArithmeticPolicy = .standard) {
        self.policy = policy
    }

    public func judge(_ claim: ArithmeticClaim) -> ArithmeticFinding {
        let computed = claim.computed.value
        let target = claim.direction == .unstated ? computed?.magnitude : computed
        let outcome = target.map { outcome(of: claim, value: $0) } ?? .undefined
        return ArithmeticFinding(claim: claim, outcome: outcome, severity: severity(of: outcome), computed: target)
    }

    private func outcome(of claim: ArithmeticClaim, value: Decimal) -> ArithmeticFinding.Outcome {
        switch match(value, claim) {
        case .exact?:
            return .exact
        case .rounded?:
            return .rounded
        case .approximate?:
            return .approximate
        case .misrounded(let correct)?:
            return .misrounded(correct: correct)
        default:
            break
        }
        let directed = claim.direction == .increase || claim.direction == .decrease
        if directed, match(-value, claim) != nil { return .wrongDirection }
        if let points = claim.computed.pointDifference, match(points, claim) != nil {
            return .pointsAsPercent(points: points)
        }
        return .wrong(correct: value)
    }

    /// How `value` compares with the claim's result; `nil` when it is simply different.
    private func match(_ value: Decimal, _ claim: ArithmeticClaim) -> ArithmeticFinding.Outcome? {
        let claimed = claim.claimed
        if value == claimed.value { return .exact }
        let quantum = claimed.quantum
        let roundings = [value.rounded(toMultipleOf: quantum, .plain), value.rounded(toMultipleOf: quantum, .bankers)]
        if roundings.contains(claimed.value) { return .rounded }
        let gap = (value - claimed.value).magnitude
        if claimed.isTruncated, gap < quantum { return .rounded }
        if claim.isApproximate, gap <= policy.approximateTolerance * value.magnitude { return .approximate }
        return gap < quantum ? .misrounded(correct: roundings[0]) : nil
    }

    private func severity(of outcome: ArithmeticFinding.Outcome) -> ArithmeticFinding.Severity {
        switch outcome {
        case .exact, .rounded, .approximate:
            return .holds
        case .misrounded:
            return policy.flagsMisrounding ? .caution : .holds
        case .pointsAsPercent:
            return .caution
        case .wrong, .wrongDirection, .undefined:
            return .wrong
        }
    }
}
