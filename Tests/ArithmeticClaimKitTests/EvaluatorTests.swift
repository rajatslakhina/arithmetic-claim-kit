@testable import ArithmeticClaimKit
import XCTest

final class EvaluatorTests: XCTestCase {
    func testExactAndRounded() {
        XCTAssertEqual(outcomes("3 × 12 = 36. 1/3 = 0.33. 2/3 = 0.67. 1/3 = 33%. 2/3 = 0.666... 22 / 7 = 3.14…"),
                       [.exact, .rounded, .rounded, .rounded, .rounded, .rounded])
        // A tie rounds either way: half up gives 3, half to even gives 2.
        XCTAssertEqual(outcomes("5 / 2 = 2. 5 / 2 = 3. 7 / 2 = 4."), [.rounded, .rounded, .rounded])
        // Cut short with `...` and within the last digit counts as written.
        XCTAssertEqual(outcomes("2/3 = 0.667..."), [.rounded])
        XCTAssertEqual(outcomes("2/3 = 0.65..."), [.wrong(correct: Decimal(2) / 3)])
    }

    func testMisrounding() {
        XCTAssertEqual(outcomes("$100 / 3 = $33.34. 2/3 = 0.66. 7 / 2 = 3."),
                       [.misrounded(correct: .of("33.33")), .misrounded(correct: .of("0.67")), .misrounded(correct: 4)])
        let standard = ArithmeticChecker().check("2/3 = 0.66")
        let lenient = ArithmeticChecker(policy: .lenient).check("2/3 = 0.66")
        XCTAssertEqual(standard.findings.map(\.severity), [.caution])
        XCTAssertEqual(lenient.findings.map(\.severity), [.holds])
        XCTAssertEqual(lenient.verdict, .verified)
    }

    func testApproximationsByPolicy() {
        let text = "1000 / 7 is about 140."
        XCTAssertEqual(outcomes(text), [.wrong(correct: Decimal(1000) / 7)])
        XCTAssertEqual(outcomes(text, policy: .lenient), [.approximate])
        XCTAssertEqual(outcomes("1000 / 7 is about 142", policy: .standard), [.approximate])
        XCTAssertEqual(outcomes("1000 / 7 ≈ 142.9"), [.rounded])
        XCTAssertEqual(outcomes("100 / 3 ≈ 33.5"), [.approximate])
        XCTAssertEqual(outcomes("100 / 3 ≈ 33.5", policy: .strict), [.wrong(correct: Decimal(100) / 3)])
        XCTAssertEqual(outcomes("100 / 3 = 33.5"), [.wrong(correct: Decimal(100) / 3)])
    }

    func testChanges() {
        XCTAssertEqual(outcomes("From $40k to $50k, a 20% increase."), [.wrong(correct: .of("0.25"))])
        XCTAssertEqual(outcomes("From 200 to 250, a 25% decrease."), [.wrongDirection])
        XCTAssertEqual(outcomes("From 5% to 4%, a 1% decrease."), [.pointsAsPercent(points: .of("-0.01"))])
        XCTAssertEqual(outcomes("From 50 to 40 is a 20% change. From 40 to 50 is a 25% change."), [.exact, .exact])
        XCTAssertEqual(outcomes("From 30 to 40, a 33% increase. From 30 to 40, a 34% increase."),
                       [.rounded, .misrounded(correct: .of("0.33"))])
        XCTAssertEqual(outcomes("From 40% to 50%, up 10 percentage points. From 40% to 50%, up 25 points."),
                       [.exact, .wrong(correct: .of("0.1"))])
        XCTAssertEqual(outcomes("From 0 to 5, a 100% increase."), [.undefined])
        XCTAssertEqual(outcomes("From 5% to 4%, a 1% increase."), [.wrong(correct: .of("-0.2"))])
    }

    func testUndefined() {
        let report = ArithmeticChecker().check("10 / 0 = 5 and 100000000000000000000^12 = 1 and (1 / 0) + 1 = 2")
        XCTAssertEqual(report.findings.map(\.outcome), [.undefined, .undefined, .undefined])
        XCTAssertEqual(report.findings.map(\.computed), [nil, nil, nil])
        XCTAssertEqual(report.findings.map(\.severity), [.wrong, .wrong, .wrong])
    }

    func testExpressionParts() {
        let five = WrittenNumber(digits: 5, decimals: 0, scale: .hundredth, suffix: "%", prefix: "",
                                 isPercent: true, isTruncated: false, text: "5%")
        let four = WrittenNumber(digits: 4, decimals: 0, scale: .hundredth, suffix: "%", prefix: "",
                                 isPercent: true, isTruncated: false, text: "4%")
        let points = Expression.pointChange(from: five, to: four)
        XCTAssertEqual(points.numbers, [five, four])
        XCTAssertEqual(points.text, "from 5% to 4%")
        XCTAssertEqual(points.value, .of("-0.01"))
        XCTAssertNil(points.pointDifference)
        XCTAssertEqual(Expression.change(from: five, to: four).numbers, [five, four])
        XCTAssertEqual(Expression.percentOf(five, .power(.negated(.grouped(.number(four))), 2)).numbers, [five, four])
        XCTAssertFalse(Expression.number(five).isPercentOf)
        XCTAssertNil(Expression.binary(.plus, .number(five), .number(four)).plainNumber)
        XCTAssertEqual(Expression.grouped(.number(five)).plainNumber?.number, five)
        XCTAssertEqual(Expression.negated(.negated(.number(five))).plainNumber?.isNegative, false)
        XCTAssertEqual(five.exponent, nil)
        XCTAssertEqual(Decimal(7).rounded(toMultipleOf: 2, .plain), 8)
    }
}
