/// Finds the arithmetic an answer states, outside fenced code.
public struct ArithmeticReader: Sendable {
    /// Whether `from A to B, a P% increase` is read.
    public var readsPercentChanges: Bool

    public init(readsPercentChanges: Bool = true) {
        self.readsPercentChanges = readsPercentChanges
    }

    public func claims(in text: String) -> [ArithmeticClaim] {
        let (tokens, characters) = Lexer.read(text)
        var claims = ChainReader(tokens: tokens, characters: characters).claims()
        if readsPercentChanges {
            claims += ChangeReader(tokens: tokens, characters: characters).claims()
        }
        return claims.sorted { $0.range.lowerBound < $1.range.lowerBound }
    }
}

/// Reads an answer's arithmetic and judges every result: the one call most callers need.
public struct ArithmeticChecker: Sendable {
    public let policy: ArithmeticPolicy

    public init(policy: ArithmeticPolicy = .standard) {
        self.policy = policy
    }

    public func claims(in text: String) -> [ArithmeticClaim] {
        ArithmeticReader(readsPercentChanges: policy.readsPercentChanges).claims(in: text)
    }

    public func check(_ text: String) -> ArithmeticReport {
        let evaluator = ArithmeticEvaluator(policy: policy)
        return ArithmeticReport(findings: claims(in: text).map(evaluator.judge))
    }
}
