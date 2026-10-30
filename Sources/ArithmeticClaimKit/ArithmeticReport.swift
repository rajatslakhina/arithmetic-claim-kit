/// Everything one answer's arithmetic came to.
public struct ArithmeticReport: Sendable, Hashable {
    public enum Verdict: String, Sendable, Hashable, CaseIterable {
        /// No arithmetic stated.
        case noArithmetic
        /// Every result holds.
        case verified
        /// Nothing wrong, but a result is misrounded or mixes points with percent.
        case caution
        /// At least one result is wrong.
        case wrong
    }

    public let findings: [ArithmeticFinding]
    public let verdict: Verdict

    public init(findings: [ArithmeticFinding]) {
        self.findings = findings
        switch findings.map(\.severity).max() {
        case nil:
            verdict = .noArithmetic
        case .holds?:
            verdict = .verified
        case .caution?:
            verdict = .caution
        case .wrong?:
            verdict = .wrong
        }
    }

    /// The findings that need a correction or a second look.
    public var flagged: [ArithmeticFinding] {
        findings.filter { $0.severity > .holds }
    }

    /// Flagged findings that were already flagged earlier in the conversation.
    public var repeatedCount: Int {
        flagged.filter(\.isRepeated).count
    }

    /// One sentence per flagged finding, with the correct value.
    public var corrections: [String] {
        flagged.map(\.explanation)
    }
}
