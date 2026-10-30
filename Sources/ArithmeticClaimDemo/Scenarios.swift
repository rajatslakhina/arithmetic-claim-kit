import ArithmeticClaimKit

enum Scenarios {
    static func tipAndTotal() {
        Out.heading(1, "A tip, and the total that depends on it")
        Out.quote("asked", "Dinner was $80. What is a 15% tip, and what do I pay in all?")
        let answer = "A 15% tip is 15% of $80, which is $14. So you pay $80 + $14 = $94."
        Out.quote("answer", answer)
        let report = ArithmeticChecker().check(answer)
        Out.report(report)
        Out.line("($94 is right for $80 + $14, and wrong as the bill: the feedback asks for dependent figures too.)")
        Out.block("feedback to the model", report.feedback)
        let rewrite = "A 15% tip is 15% of $80, which is $12. So you pay $80 + $12 = $92."
        Out.quote("rewrite", rewrite)
        Out.report(ArithmeticChecker().check(rewrite))
    }

    static func runOn() {
        Out.heading(2, "A run-on chain")
        let answer = "Three dozen eggs and five more: 3 × 12 = 36 + 5 = 42 eggs."
        Out.quote("answer", answer)
        let report = ArithmeticChecker().check(answer)
        Out.report(report)
        Out.line(report.note ?? "")
    }

    static func changes() {
        Out.heading(3, "Percentage changes")
        let answer = "Revenue went from $40k to $50k, a 20% increase. Churn fell from 5% to 4%, a 1% decrease. "
            + "Signups dropped from 200 to 250, a 25% decrease."
        Out.quote("answer", answer)
        let report = ArithmeticChecker().check(answer)
        Out.report(report)
        for correction in report.corrections { Out.line("- " + correction) }
    }

    static func rounding() {
        Out.heading(4, "Rounding")
        let answer = "Split three ways, $100 / 3 = $33.34 each. Two thirds is 2/3 ≈ 0.67, "
            + "and 22 / 7 = 3.14… is close to pi."
        Out.quote("answer", answer)
        let standard = ArithmeticChecker().check(answer)
        Out.report(standard)
        Out.line(standard.note ?? "")
        let lenient = ArithmeticChecker(policy: .lenient).check(answer)
        Out.line("under .lenient: \(lenient.verdict.rawValue) (\(lenient.summary))")
    }

    static func latex() {
        Out.heading(5, "LaTeX")
        let answer = "Three quarters of 80 is $\\frac{3}{4} \\times 80 = 60$, and $12^2 = 124$."
        Out.quote("answer", answer)
        let report = ArithmeticChecker().check(answer)
        Out.report(report)
        Out.line(report.note ?? "")
    }

    static func leftAlone() {
        Out.heading(6, "What is left alone")
        let answer = """
            - Solve 2x + 3 = 13 for x.
            - The release is on 2026-11-02.
            - A 15% tip on $80 is $14.
            ```python
            total = 3 + 4  # = 8
            ```
            """
        for row in answer.split(separator: "\n") { Out.line("| " + row) }
        let claims = ArithmeticChecker().claims(in: answer)
        Out.line("results read: \(claims.count) (algebra, a date, code, and \"tip on\" are not read as arithmetic)")
    }

    static func policies() {
        Out.heading(7, "Approximations, by policy")
        let answer = "1000 / 7 is about 140, and 100 / 3 is about 33.3."
        Out.quote("answer", answer)
        let policies: [(String, ArithmeticPolicy)] = [
            ("standard", .standard), ("lenient", .lenient), ("strict", .strict)
        ]
        for (name, policy) in policies {
            let report = ArithmeticChecker(policy: policy).check(answer)
            let outcomes = report.findings.map { "\($0.claim.statement): \($0.severity)" }.joined(separator: ", ")
            Out.line("\(name): \(outcomes) -> \(report.verdict.rawValue)")
        }
    }

    static func conversation() async {
        Out.heading(8, "A conversation: the same mistake twice")
        let ledger = ArithmeticLedger()
        let turns = [
            "A 20% discount takes 20% of $45, which is $8, off the price.",
            "You're right to ask. The discount is 20% of $45, which is $8.",
            "Correction: 20% of $45 is $9, so you pay $45 - $9 = $36."
        ]
        for (number, turn) in turns.enumerated() {
            Out.quote("turn \(number + 1)", turn)
            let report = await ledger.review(turn)
            Out.report(report)
            if report.repeatedCount > 0 { Out.line(report.note ?? "") }
        }
        let statistics = await ledger.statistics
        Out.line("ledger: \(statistics.reviews) reviews, \(statistics.results) results, "
            + "\(statistics.flagged) flagged, \(statistics.repeated) repeated")
    }
}
