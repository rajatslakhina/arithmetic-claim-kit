@testable import ArithmeticClaimKit
import XCTest

final class LedgerTests: XCTestCase {
    func testRepeatsAcrossAConversation() async {
        let ledger = ArithmeticLedger()
        let first = await ledger.review("15% of $80 is $14, so $80 + $14 = $94.")
        XCTAssertEqual(first.repeatedCount, 0)
        let second = await ledger.review("Sorry: 15%  of $80 is $14, and $80 + $14 = $94.")
        XCTAssertEqual(second.repeatedCount, 1)
        XCTAssertEqual(second.flagged.map(\.isRepeated), [true])
        XCTAssertEqual(second.summary, "2 results checked, 1 hold, 1 wrong, 1 repeated")
        XCTAssertTrue(second.note?.hasSuffix("Some of this was stated again after a correction was asked for.") == true)
        let fixed = await ledger.review("15% of $80 is $12, so $80 + $12 = $92.")
        XCTAssertEqual(fixed.verdict, .verified)
        let statistics = await ledger.statistics
        XCTAssertEqual(statistics, ArithmeticLedger.Statistics(reviews: 3, results: 6, flagged: 2, repeated: 1))
        await ledger.forget()
        let fresh = await ledger.review("15% of $80 is $14")
        XCTAssertEqual(fresh.repeatedCount, 0)
        XCTAssertEqual(ledger.checker.policy, .standard)
    }
}
