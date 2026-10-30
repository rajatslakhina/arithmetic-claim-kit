import ArithmeticClaimKit

/// Printing for the demo: one line per stated result, then the verdict.
enum Out {
    static func heading(_ number: Int, _ title: String) {
        print("")
        print("[\(number)] \(title)")
    }

    static func line(_ text: String) {
        print("    " + text)
    }

    static func quote(_ label: String, _ text: String) {
        line("\(label): \"\(text)\"")
    }

    static func report(_ report: ArithmeticReport) {
        for finding in report.findings {
            line("\(mark(finding.severity)) \(finding.claim.excerpt)  ->  \(label(finding.outcome))")
        }
        line("verdict: \(report.verdict.rawValue) (\(report.summary))")
    }

    static func block(_ label: String, _ text: String?) {
        guard let text else { return }
        line(label + ":")
        for row in text.split(separator: "\n") { line("  " + row) }
    }

    private static func mark(_ severity: ArithmeticFinding.Severity) -> String {
        switch severity {
        case .holds: "ok"
        case .caution: "??"
        case .wrong: "XX"
        }
    }

    private static func label(_ outcome: ArithmeticFinding.Outcome) -> String {
        switch outcome {
        case .exact: "exact"
        case .rounded: "rounded as written"
        case .approximate: "approximate, within tolerance"
        case .misrounded: "misrounded"
        case .wrong: "wrong"
        case .wrongDirection: "wrong direction"
        case .pointsAsPercent: "points written as a percent"
        case .undefined: "no value"
        }
    }
}
