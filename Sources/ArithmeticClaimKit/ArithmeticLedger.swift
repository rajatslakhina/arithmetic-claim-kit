/// Checks a conversation's answers one after another and remembers what it flagged, so a wrong
/// result stated again after a correction was asked for is marked as repeated rather than new.
public actor ArithmeticLedger {
    public struct Statistics: Sendable, Hashable {
        public var reviews = 0
        public var results = 0
        public var flagged = 0
        public var repeated = 0
    }

    public nonisolated let checker: ArithmeticChecker
    public private(set) var statistics = Statistics()
    private var flaggedKeys: Set<String> = []

    public init(checker: ArithmeticChecker = ArithmeticChecker()) {
        self.checker = checker
    }

    public func review(_ text: String) -> ArithmeticReport {
        var findings = checker.check(text).findings
        var keys: Set<String> = []
        for index in findings.indices where findings[index].severity > .holds {
            let key = findings[index].key
            findings[index].isRepeated = flaggedKeys.contains(key)
            keys.insert(key)
        }
        flaggedKeys.formUnion(keys)
        let report = ArithmeticReport(findings: findings)
        statistics.reviews += 1
        statistics.results += findings.count
        statistics.flagged += report.flagged.count
        statistics.repeated += report.repeatedCount
        return report
    }

    /// Starts a new conversation: nothing flagged so far counts as a repeat.
    public func forget() {
        flaggedKeys.removeAll()
    }
}
