@testable import ArithmeticClaimKit
import XCTest

final class ReaderTests: XCTestCase {
    func testOperatorsInSymbolsAndWords() {
        XCTAssertEqual(read("3 × 4 = 12. 3 x 4 = 12. 3 * 4 = 12. 3 · 4 = 12. 3 ⋅ 4 = 12. 3 ∙ 4 = 12. 3 ✕ 4 = 12."),
                       Array(repeating: "3 × 4 = 12", count: 7))
        XCTAssertEqual(read("8 ÷ 2 = 4. 8 / 2 = 4. 8 ∕ 2 = 4. 5 − 2 = 3. 5 – 2 = 3. 5 - 2 = 3. 5 + 2 = 7."),
                       ["8 / 2 = 4", "8 / 2 = 4", "8 / 2 = 4", "5 - 2 = 3", "5 - 2 = 3", "5 - 2 = 3", "5 + 2 = 7"])
        XCTAssertEqual(read("2 plus 3 is 5. 9 minus 4 gives 5. 6 times 7 makes 42. 6 multiplied by 7 yields 42."),
                       ["2 + 3 = 5", "9 - 4 = 5", "6 × 7 = 42", "6 × 7 = 42"])
        XCTAssertEqual(read("20 divided by 4 is equal to 5. 2 + 2 equals 4. 3 + 3 totals 6. 9 - 4 works out to 5. 1 + 1 comes to 2."),
                       ["20 / 4 = 5", "2 + 2 = 4", "3 + 3 = 6", "9 - 4 = 5", "1 + 1 = 2"])
        XCTAssertEqual(read("3 + 4 == 7 and 9 - 2 come to 7"), ["3 + 4 = 7", "9 - 2 = 7"])
    }

    func testApproximateMarks() {
        let claims = ArithmeticReader().claims(in: "100 / 3 ≈ 33. 100 / 3 ≅ 33. 100 / 3 ~= 33. 100 / 3 = ~33. 100 / 3 is about 33. 100 / 3 = 33.")
        XCTAssertEqual(claims.map(\.isApproximate), [true, true, true, true, true, false])
        XCTAssertEqual(read("3 × 3 is approx. 9 and approx. 2 × 2 = 4"), ["3 × 3 = 9", "2 × 2 = 4"])
    }

    func testPrecedenceBracketsAndSigns() {
        XCTAssertEqual(outcomes("2 + 3 × 4 = 14. (2 + 3) × 4 = 20. -5 + 3 = -2. 5 - (-3) = 8. -(2 + 3) = -5. 3 + 4 = (7)."),
                       Array(repeating: .exact, count: 6))
        XCTAssertEqual(read("2^3 = 8 and 2 ^ 10 = 1024 and 5² = 25 and 3³ = 27"),
                       ["2^3 = 8", "2^10 = 1024", "5^2 = 25", "3^3 = 27"])
        XCTAssertEqual(read("2^1.5 = 2.8 and 2^13 = 8192 and 10¹⁵ = 5 and 2^ = 4 and 2^x = 4"), [])
    }

    func testChainsRewriteAndRunOn() {
        XCTAssertEqual(read("(3 + 4) × 2 = 7 × 2 = 14"), ["(3 + 4) × 2 = 7 × 2", "7 × 2 = 14"])
        XCTAssertEqual(read("3 × 12 = 36 + 5 = 42"), ["3 × 12 = 36", "36 + 5 = 42"])
        // The run-on lead is within its last digit of 12; the rewrite (18) is not.
        XCTAssertEqual(read("3 × 4 = 13 + 5 = 18"), ["3 × 4 = 13", "13 + 5 = 18"])
        // Neither reading fits: the lead (15) is closer to 12 than the rewrite (20).
        XCTAssertEqual(read("3 × 4 = 15 + 5 = 20"), ["3 × 4 = 15", "15 + 5 = 20"])
        // Neither fits and the rewrite is closer: the rewrite is judged.
        XCTAssertEqual(read("(2 + 3) × 4 = 5 × 5"), ["(2 + 3) × 4 = 5 × 5"])
        // The lead is near (within its last digit) though the rewrite is closer.
        XCTAssertEqual(read("3.3 × 3 = 10 - 0.05"), ["3.3 × 3 = 10"])
        // A bracket or a sign leads the right side: only the rewrite reading exists.
        XCTAssertEqual(read("3 × 4 = (10 + 5)"), ["3 × 4 = (10 + 5)"])
        // The right side divides by zero, or the left side does: no reading to hold the other to.
        XCTAssertEqual(read("6 / 2 = 3 / 0"), [])
        XCTAssertEqual(read("6 / 0 = 3 + 1"), ["6 / 0 = 3 + 1"])
    }

    func testContinuationsAfterAComma() {
        XCTAssertEqual(read("12 times 4 is 48, plus 10 is 58"), ["12 × 4 = 48", "48 + 10 = 58"])
        XCTAssertEqual(read("12 × 4 = 48, then times 2 = 96"), ["12 × 4 = 48", "48 × 2 = 96"])
        XCTAssertEqual(read("12 × 4 = 48, and the rest is 10"), ["12 × 4 = 48"])
        XCTAssertEqual(read("12 × 4 = 48, + "), ["12 × 4 = 48"])
        XCTAssertEqual(read("3 + 4 = 7 × 1, plus 1 = 8"), ["3 + 4 = 7 × 1"])
        XCTAssertEqual(read("15% of $80, which is $14. 3 × 4, that is 12. 3 × 4, = 12. 3 × 4, so 12."),
                       ["15% of $80 = $14", "3 × 4 = 12", "3 × 4 = 12"])
    }

    func testEitherWayRound() {
        XCTAssertEqual(read("12 = 3 × 4. 12 is 15% of 80. 12 is 3 + 9. Step 2 is 3 + 4 = 7. 12 = 12."),
                       ["3 × 4 = 12", "15% of 80 = 12", "3 + 4 = 7"])
        XCTAssertEqual(read("12 is (15% of 80)"), ["(15% of 80) = 12"])
        XCTAssertEqual(ArithmeticReader().claims(in: "12 is 15% of 80").map(\.kind), [.percentOf])
    }

    func testNumbersAsWritten() {
        XCTAssertEqual(read("1,234 + 1 = 1,235. 1,23 + 1 = 2. .5 + .5 = 1. 1,234,567 - 1 = 1,234,566."),
                       ["1,234 + 1 = 1,235", "23 + 1 = 2", ".5 + .5 = 1", "1,234,567 - 1 = 1,234,566"])
        XCTAssertEqual(read("$12 + $8 = $20. €5 + £5 + ₹5 + ¥5 = 20. $ 5 + 5 = 10."),
                       ["$12 + $8 = $20", "€5 + £5 + ₹5 + ¥5 = 20", "5 + 5 = 10"])
        XCTAssertEqual(read("15 per cent of 200 is 30. 15 percent of 200 = 30. 15 pct of 200 = 30. 15 % of 200 = 30."),
                       ["15 per cent of 200 = 30", "15 percent of 200 = 30", "15 pct of 200 = 30", "15 % of 200 = 30"])
        XCTAssertEqual(outcomes("3 lakh × 2 = 6 lakh. 2 crore / 2 = 1 crore. 5k + 5k = 10k. 2bn / 2 = 1B. 3M - 1M = 2 million."),
                       Array(repeating: .exact, count: 5))
        XCTAssertEqual(outcomes("1.2 million × 3 = 3.6 million. 1 thousand + 1 = 1,001. 1 billion / 1 trillion = 0.001."),
                       Array(repeating: .exact, count: 3))
        XCTAssertEqual(read("12 kg + 3kg = 15 kg. 10 m² + 5 m^2 = 15 m². 2 hours × 3 = 6 hours."),
                       ["12 kg + 3kg = 15 kg", "10 m² + 5 m^2 = 15 m²", "2 hours × 3 = 6 hours"])
    }

    func testWhatIsNotANumber() {
        XCTAssertEqual(read("3rd + 4G = 7. 2x + 3 = 13. 10am + 2 = 12. 15% percent + 1 = 2. 5k thousand + 1 = 2."), [])
        let long = String(repeating: "9", count: 31)
        XCTAssertEqual(read("\(long) + 1 = 2"), [])
        XCTAssertEqual(read("per cent + 1 = 2. 15% per cent of 10 = 1.5"), [])
    }

    func testTruncatedResults() {
        let claims = ArithmeticReader().claims(in: "2/3 = 0.666... and 22 / 7 = 3.14…")
        XCTAssertEqual(claims.map(\.claimedText), ["0.666...", "3.14…"])
        XCTAssertEqual(claims.map(\.claimed.isTruncated), [true, true])
    }

    func testLatex() {
        XCTAssertEqual(read("$\\frac{3}{4} \\times 80 = 60$ and \\(3 \\div 4 = 0.75\\) and $3 \\cdot 4 = 12$"),
                       ["(3) / (4) × 80 = 60", "3 / 4 = 0.75", "3 × 4 = 12"])
        XCTAssertEqual(read("$12^2 = 124$ but $12 + $8 = $20"), ["12^2 = 124", "$12 + $8 = $20"])
        XCTAssertEqual(ArithmeticReader().claims(in: "$\\dfrac{3}{4} \\times 80 = 60$").map(\.excerpt),
                       ["\\dfrac{3}{4} \\times 80 = 60"])
        XCTAssertEqual(read("\\[ \\text{total} = 3 + 4 = 7 \\] and \\left( 2 + 3 \\right) \\times 2 = 10"),
                       ["3 + 4 = 7", "(2 + 3) × 2 = 10"])
        XCTAssertEqual(read("100 / 3 \\approx 33 and 100 / 3 \\simeq 33 and \\mathrm{a{b}c} 2 + 2 = 4 and \\text 5 + 5 = 10"),
                       ["100 / 3 = 33", "100 / 3 = 33", "2 + 2 = 4", "5 + 5 = 10"])
        XCTAssertEqual(read("\\text{never closed 3 + 4 = 7"), [])
        XCTAssertEqual(read("3 \\neq 4 = 4. 5 \\% 3 = 1. \\$5 + \\$5 = \\$10. \\sqrt 4 + 1 = 3. 2 + 2 = 4 \\"),
                       ["\\$5 + \\$5 = \\$10", "4 + 1 = 3", "2 + 2 = 4"])
    }

    func testWhatIsSkipped() {
        let text = """
        - 3 + 4 = 7
          * 2 + 2 = 4
        + 1 + 1 = 2
        ```
        total = 3 + 4  # = 8
        ```
        On 2026-10-30 = Friday. 3 - 1 = 2. **2 × 2 = 4** and x² + 1 = 5 and x^2 = 4.
        ```swift
        let a = 1 + 1 // = 3
        """
        XCTAssertEqual(read(text), ["3 + 4 = 7", "2 + 2 = 4", "1 + 1 = 2", "3 - 1 = 2", "2 × 2 = 4"])
        XCTAssertEqual(read("-3 + 5 = 2 and `2 + 2 = 4`"), ["-3 + 5 = 2", "2 + 2 = 4"])
        XCTAssertEqual(read("% 3 + 3 = 6 and 3 ≠ 4 = 4 and 3: 4 = 4"), ["3 + 3 = 6"])
    }

    func testPercentArithmetic() {
        XCTAssertEqual(outcomes("80 - 15% = 68. 80 + 15% = 92. 15% + 5% = 20%. 25% of 25% of 80 = 5. 3/4 = 75%. 80 × 15% = 12."),
                       Array(repeating: .exact, count: 6))
        XCTAssertEqual(read("15% of = 3 and 15% of 80 + 5 = 17"), ["15% of 80 + 5 = 17"])
        XCTAssertEqual(ArithmeticReader().claims(in: "15% of 80 + 5 = 17").map(\.kind), [.equation])
    }

    func testIncompleteExpressionsLeaveWhatTheyCannotUse() {
        XCTAssertEqual(read("(3 + 4 = 7 and 3 + = 3 and - = 1 and 3 × = 3 and --3 = 3"), ["3 + 4 = 7"])
        XCTAssertEqual(read("3 + 4 ="), [])
    }

    func testRangesAndExcerpts() {
        let text = "So: 15% of $80 is $12."
        let claim = ArithmeticReader().claims(in: text)[0]
        XCTAssertEqual(claim.excerpt, "15% of $80 is $12")
        XCTAssertEqual(claim.range, 4..<21)
        XCTAssertNil(claim.direction)
        XCTAssertEqual(ArithmeticReader().claims(in: "12 = 3 × 4")[0].excerpt, "12 = 3 × 4")
    }
}
