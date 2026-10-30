import Foundation

extension ArithmeticFinding {
    /// One sentence on this finding, with the correct value where there is one.
    public var explanation: String {
        let claim = self.claim
        let claimed = claim.claimed
        switch (outcome, computed) {
        case let (.misrounded(correct), exact?):
            let exactText = stated(exact, claimed.written(exact, places: claimed.decimals + 2, approximate: true))
            let roundedText = stated(correct, claimed.written(correct, places: claimed.decimals))
            return "\(claim.statement) is \(exactText), which rounds to \(roundedText), not \(claim.claimedText)."
        case let (.wrong(correct), _):
            return "\(claim.statement) is \(stated(correct, claimed.correction(correct))), not \(claim.claimedText)."
        case let (.wrongDirection, value?):
            return "\(claim.statement) is \(stated(value, claimed.correction(value))), not \(claim.claimedText)."
        case let (.pointsAsPercent(points), value?):
            let size = DecimalText.text(points.magnitude * 100, places: claimed.decimals)
            let unit = size == "1" ? "percentage point" : "percentage points"
            let relative = stated(value, claimed.correction(value))
            return "\(claim.statement) is \(size) \(unit) but \(relative); "
                + "\"\(claim.claimedText)\" reads the points as a percent."
        case (.undefined, _):
            let reason = claim.direction == nil
                ? "divides by zero, so it has no value"
                : "starts at zero, so it has no percentage change"
            return "\(claim.statement) \(reason)."
        default:
            return "\(claim.statement) is \(claim.claimedText), which holds."
        }
    }

    /// A value as the claim would state it: a number for arithmetic, "a 25% increase" for a change.
    private func stated(_ value: Decimal, _ written: String) -> String {
        guard claim.direction != nil else { return written }
        let about = written.hasPrefix("about ") ? "about " : ""
        let noun = value > 0 ? "increase" : value < 0 ? "decrease" : "change"
        return "\(about)a \(written.dropFirst(about.count).drop { $0 == "-" }) \(noun)"
    }
}

extension ArithmeticReport {
    /// A note for the person reading the answer; `nil` when every result holds or none is stated.
    public var note: String? {
        guard !flagged.isEmpty else { return nil }
        let again = repeatedCount > 0 ? " Some of this was stated again after a correction was asked for." : ""
        return "Arithmetic check: " + corrections.joined(separator: " ") + again
    }

    /// A message asking the model to redo its arithmetic; `nil` when there is nothing to redo.
    public var feedback: String? {
        guard !flagged.isEmpty else { return nil }
        let lines = corrections.map { "- " + $0 }.joined(separator: "\n")
        return "Some arithmetic in your answer does not hold:\n" + lines
            + "\nRecompute each of these, correct every figure that depends on them, "
            + "and keep the rest of the answer as it is."
    }

    /// A short line for a trace or a log.
    public var summary: String {
        guard !findings.isEmpty else { return "no arithmetic stated" }
        let counts = Dictionary(grouping: findings, by: \.severity).mapValues(\.count)
        let noun = findings.count == 1 ? "result" : "results"
        var parts = ["\(findings.count) \(noun) checked", "\(counts[.holds, default: 0]) hold"]
        if let caution = counts[.caution] { parts.append("\(caution) to check") }
        if let wrong = counts[.wrong] { parts.append("\(wrong) wrong") }
        if repeatedCount > 0 { parts.append("\(repeatedCount) repeated") }
        return parts.joined(separator: ", ")
    }
}
