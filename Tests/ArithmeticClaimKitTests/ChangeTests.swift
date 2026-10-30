@testable import ArithmeticClaimKit
import XCTest

final class ChangeTests: XCTestCase {
    func testFigureAfterOrBeforeTheSpan() {
        XCTAssertEqual(read("Revenue went from $40k to $50k, a 20% increase."), ["from $40k to $50k = a 20% increase"])
        XCTAssertEqual(read("It rose 25% from 40 to 50."), ["from 40 to 50 = a 25% increase"])
        XCTAssertEqual(read("Signups dropped from 200 to 250, a 25% decrease."), ["from 200 to 250 = a 25% decrease"])
        XCTAssertEqual(read("From 50 to 40 is a 20% change."), ["from 50 to 40 = a 20% change"])
        let claims = ArithmeticReader().claims(in: "It fell from 50 to 40 (down 20%).")
        XCTAssertEqual(claims.map(\.kind), [.percentChange(.decrease)])
        XCTAssertEqual(claims.map(\.excerpt), ["from 50 to 40 (down 20%"])
        XCTAssertEqual(claims.map(\.direction), [.decrease])
    }

    func testPoints() {
        let claims = ArithmeticReader().claims(in: "From 40% to 50% is up 10 percentage points. From 5% to 4%, down 1 pp. From 5% to 4%: 1 point")
        XCTAssertEqual(claims.map(\.kind), [.pointChange(.increase), .pointChange(.decrease)])
        XCTAssertEqual(claims.map(\.claimedText), ["a 10 percentage-point increase", "a 1 percentage-point decrease"])
        // Points between two numbers that are not percentages are not read.
        XCTAssertEqual(read("From 40 to 50, up 10 points."), [])
    }

    func testWhatIsNotAChange() {
        XCTAssertEqual(read("Sales grew from 40 to 50 while churn rose 3%."), [])
        XCTAssertEqual(read("From 40 to 50 users. Churn rose 3%."), [])
        XCTAssertEqual(read("From 40 to 50 then 60, up 5%."), [])
        XCTAssertEqual(read("From 40 to 50, 25% of them new."), [])
        XCTAssertEqual(read("From 40 to 50, a 25% share."), [])
        XCTAssertEqual(read("From 40 to 50 a b c d e f 25% increase."), [])
        XCTAssertEqual(read("From 40 to 50 the result."), [])
        XCTAssertEqual(read("from 40 to"), [])
        XCTAssertEqual(read("rose 25% from 40 to 50", reader: ArithmeticReader(readsPercentChanges: false)), [])
        XCTAssertEqual(read("from 40 to 50", reader: ArithmeticReader(readsPercentChanges: true)), [])
    }

    func testApproximateChange() {
        let claims = ArithmeticReader().claims(in: "From 30 to 40 is roughly a 33% increase. From 30 to 40, about 33% up.")
        XCTAssertEqual(claims.map(\.isApproximate), [true, true])
    }
}
