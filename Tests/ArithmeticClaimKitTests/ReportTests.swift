@testable import ArithmeticClaimKit
import XCTest

final class ReportTests: XCTestCase {
    func testVerdicts() {
        XCTAssertEqual(ArithmeticChecker().check("No sums here.").verdict, .noArithmetic)
        XCTAssertEqual(ArithmeticChecker().check("3 + 4 = 7").verdict, .verified)
        XCTAssertEqual(ArithmeticChecker().check("3 + 4 = 7 and 2/3 = 0.66").verdict, .caution)
        XCTAssertEqual(ArithmeticChecker().check("3 + 4 = 8 and 2/3 = 0.66").verdict, .wrong)
        XCTAssertEqual(ArithmeticReport.Verdict.allCases.count, 4)
        XCTAssertLessThan(ArithmeticFinding.Severity.holds, .wrong)
    }

    func testExplanations() {
        XCTAssertEqual(explanations("A 15% tip: 15% of $80 is $14. 3 + 4 = 7."),
                       ["15% of $80 is $12, not $14.", "3 + 4 is 7, which holds."])
        XCTAssertEqual(explanations("$100 / 3 = $33.34. 7 / 2 = 3. 1000 / 7 = 140. -2 × 3 = 6."), [
            "$100 / 3 is about $33.3333, which rounds to $33.33, not $33.34.",
            "7 / 2 is 3.5, which rounds to 4, not 3.",
            "1000 / 7 is about 142.86, not 140.",
            "-2 × 3 is -6, not 6."
        ])
        XCTAssertEqual(explanations("1.2 million × 3 = 3.5 million. 3/4 = 70%. 12000 + 1 = 12,000."), [
            "1.2 million × 3 is 3.6 million, not 3.5 million.",
            "3 / 4 is 75%, not 70%.",
            "12000 + 1 is 12,001, not 12,000."
        ])
        XCTAssertEqual(explanations("10 / 0 = 5. From 0 to 5, a 100% increase."), [
            "10 / 0 divides by zero, so it has no value.",
            "from 0 to 5 starts at zero, so it has no percentage change."
        ])
    }

    func testChangeExplanations() {
        XCTAssertEqual(explanations("From $40k to $50k, a 20% increase. From 200 to 250, a 25% decrease."), [
            "from $40k to $50k is a 25% increase, not a 20% increase.",
            "from 200 to 250 is a 25% increase, not a 25% decrease."
        ])
        XCTAssertEqual(explanations("From 30 to 40, a 30% increase. From 30 to 40, a 34% increase. From 40 to 40, a 5% change."), [
            "from 30 to 40 is about a 33.33% increase, not a 30% increase.",
            "from 30 to 40 is about a 33.33% increase, which rounds to a 33% increase, not a 34% increase.",
            "from 40 to 40 is a 0% change, not a 5% change."
        ])
        XCTAssertEqual(explanations("From 5% to 4%, a 1% decrease. From 50% to 40%, a 10% decrease."), [
            "from 5% to 4% is 1 percentage point but a 20% decrease; \"a 1% decrease\" reads the points as a percent.",
            "from 50% to 40% is 10 percentage points but a 20% decrease; \"a 10% decrease\" reads the points as a percent."
        ])
        XCTAssertEqual(explanations("From 40% to 50%, up 25 points. From 50 to 40, a 25% decrease."), [
            "from 40% to 50% is a 10 percentage-point increase, not a 25 percentage-point increase.",
            "from 50 to 40 is a 20% decrease, not a 25% decrease."
        ])
    }

    func testNoteFeedbackAndSummary() {
        let clean = ArithmeticChecker().check("3 + 4 = 7")
        XCTAssertNil(clean.note)
        XCTAssertNil(clean.feedback)
        XCTAssertEqual(clean.summary, "1 result checked, 1 hold")
        XCTAssertEqual(ArithmeticChecker().check("Nothing.").summary, "no arithmetic stated")
        XCTAssertEqual(ArithmeticChecker().check("3 + 4 = 8").summary, "1 result checked, 0 hold, 1 wrong")

        let report = ArithmeticChecker().check("15% of $80 is $14, so $80 + $14 = $94. 2/3 = 0.66.")
        XCTAssertEqual(report.note, "Arithmetic check: 15% of $80 is $12, not $14. "
            + "2 / 3 is about 0.6667, which rounds to 0.67, not 0.66.")
        XCTAssertEqual(report.feedback, """
            Some arithmetic in your answer does not hold:
            - 15% of $80 is $12, not $14.
            - 2 / 3 is about 0.6667, which rounds to 0.67, not 0.66.
            Recompute each of these, correct every figure that depends on them, and keep the rest of the answer as it is.
            """)
        XCTAssertEqual(report.summary, "3 results checked, 1 hold, 1 to check, 1 wrong")
        XCTAssertEqual(report.flagged.count, 2)
        XCTAssertEqual(report.corrections.count, 2)
        XCTAssertEqual(report.repeatedCount, 0)
    }

    func testWritingNumbers() {
        XCTAssertEqual(DecimalText.text(.of("1234567.891"), places: 2), "1,234,567.89")
        XCTAssertEqual(DecimalText.text(.of("-1234.5"), places: 0), "-1,235")
        XCTAssertEqual(DecimalText.text(.of("12.50"), places: 2), "12.5")
        XCTAssertEqual(DecimalText.approximate(.of("0.125"), places: 2), "about 0.13")
        XCTAssertEqual(DecimalText.approximate(.of("0.125"), places: 3), "0.125")
        let price = WrittenNumber(digits: 5, decimals: 0, scale: 1, suffix: "", prefix: "$",
                                  isPercent: false, isTruncated: false, text: "$5")
        XCTAssertEqual(ClaimedValue(number: price, isNegative: true).written(-5, places: 0), "-$5")
        XCTAssertEqual(ClaimedValue(number: price, isNegative: false).correction(.of("2.5")), "$2.5")
    }
}
