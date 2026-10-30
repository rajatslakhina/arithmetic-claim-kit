import Foundation

/// Reads `=`, `≈` and `is` between expressions: `3 × 4 = 12`, the rewrite `(3 + 4) × 2 = 7 × 2 = 14`,
/// the run-on `3 × 4 = 12 + 5 = 17`, `12 times 4 is 48, plus 10 is 58`, and `12 is 15% of 80`.
struct ChainReader {
    private struct Segment {
        let expression: Expression
        let tokens: Range<Int>
    }

    private struct Link {
        let isWord: Bool
        let isApproximate: Bool
    }

    let tokens: [Token]
    let characters: [Character]

    func claims() -> [ArithmeticClaim] {
        var claims: [ArithmeticClaim] = []
        var index = 0
        while index < tokens.count {
            var parser = ExpressionParser(tokens: tokens, position: index)
            guard let first = parser.expression() else {
                index += 1
                continue
            }
            var previous = Segment(expression: first, tokens: index..<parser.position)
            var cursor = parser.position
            while let (segment, link) = next(after: previous, at: &cursor) {
                if let link, let claim = claim(previous, segment, link) { claims.append(claim) }
                previous = segment
            }
            index = cursor
        }
        return claims
    }

    /// The next segment of a chain: after an equality, or a continuation (`, plus 10`) with no link.
    private func next(after previous: Segment, at cursor: inout Int) -> (Segment, Link?)? {
        let link = linkStart(at: cursor)
        if case .equals(let isWord, let approximate)? = tokens[safe: link]?.kind {
            var start = link + 1
            var isApproximate = approximate
            // `is about`, `is equal to`, `= ~12`.
            loop: while true {
                switch tokens[safe: start]?.kind {
                case .approximately?:
                    isApproximate = true
                case .equals(_, let alsoApproximate)?:
                    isApproximate = isApproximate || alsoApproximate
                default:
                    break loop
                }
                start += 1
            }
            var parser = ExpressionParser(tokens: tokens, position: start)
            guard let expression = parser.expression() else { return nil }
            cursor = parser.position
            let segment = Segment(expression: expression, tokens: start..<parser.position)
            return (segment, Link(isWord: isWord, isApproximate: isApproximate))
        }
        guard previous.expression.plainNumber != nil, let start = continuationStart(at: cursor) else { return nil }
        var parser = ExpressionParser(tokens: tokens, position: start)
        guard let expression = parser.continuation(of: previous.expression) else { return nil }
        cursor = parser.position
        return (Segment(expression: expression, tokens: previous.tokens.lowerBound..<parser.position), nil)
    }

    /// Where the equality after a segment is: right there, or after `, which` (`15% of $80, which is $12`).
    private func linkStart(at cursor: Int) -> Int {
        guard case .comma? = tokens[safe: cursor]?.kind else { return cursor }
        var start = cursor + 1
        while case .word(let word)? = tokens[safe: start]?.kind, Vocabulary.relatives.contains(word) {
            start += 1
        }
        return start
    }

    /// Where `, plus 10` or `, then times 2` starts carrying a result on.
    private func continuationStart(at cursor: Int) -> Int? {
        guard case .comma? = tokens[safe: cursor]?.kind else { return nil }
        var start = cursor + 1
        while case .word(let word)? = tokens[safe: start]?.kind, Vocabulary.continuations.contains(word) {
            start += 1
        }
        return start
    }

    private func claim(_ left: Segment, _ right: Segment, _ link: Link) -> ArithmeticClaim? {
        switch (left.expression.hasOperation, right.expression.hasOperation) {
        case (true, false):
            return make(left, right.expression, right.tokens, link)
        case (false, true):
            // `12 = 3 × 4` reads either way round; with a word, only `12 is 15% of 80` does.
            guard !link.isWord || right.expression.isPercentOf else { return nil }
            return make(right, left.expression, left.tokens, link)
        case (true, true):
            return chained(left, right, link)
        case (false, false):
            return nil
        }
    }

    /// Both sides compute. `(3 + 4) × 2 = 7 × 2` rewrites the left side; `3 × 4 = 12 + 5` gives 12
    /// and carries on. The reading the numbers fit is the one judged; failing both, the closer one.
    private func chained(_ left: Segment, _ right: Segment, _ link: Link) -> ArithmeticClaim? {
        let rewrite = make(left, right.expression, right.tokens, link)
        let first = right.tokens.lowerBound
        guard let target = left.expression.value, let rewritten = rewrite?.claimed,
              !Self.near(target, rewritten), case .number(let lead) = tokens[first].kind else { return rewrite }
        let leading = ClaimedValue(number: lead, isNegative: false)
        let gap = (target - leading.value).magnitude
        guard Self.near(target, leading) || gap < (target - rewritten.value).magnitude else { return rewrite }
        return make(left, .number(lead), first..<first + 1, link)
    }

    private static func near(_ value: Decimal, _ claimed: ClaimedValue) -> Bool {
        (value - claimed.value).magnitude <= claimed.quantum
    }

    private func make(_ statement: Segment, _ claimed: Expression, _ claimedTokens: Range<Int>, _ link: Link)
        -> ArithmeticClaim? {
        guard let value = ClaimedValue.of(claimed) else { return nil }
        let lower = min(statement.tokens.lowerBound, claimedTokens.lowerBound)
        let upper = max(statement.tokens.upperBound, claimedTokens.upperBound)
        let range = tokens[lower].range.lowerBound..<tokens[upper - 1].range.upperBound
        return ArithmeticClaim(
            kind: statement.expression.isPercentOf ? .percentOf : .equation,
            statement: statement.expression.text,
            claimedText: claimed.text,
            excerpt: String(characters[range]),
            range: range,
            isApproximate: link.isApproximate,
            computed: statement.expression,
            claimed: value
        )
    }
}
