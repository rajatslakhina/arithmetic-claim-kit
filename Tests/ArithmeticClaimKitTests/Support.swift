@testable import ArithmeticClaimKit
import XCTest

extension XCTestCase {
    /// Each claim read from `text`, as "statement = claimed".
    func read(_ text: String, reader: ArithmeticReader = ArithmeticReader()) -> [String] {
        reader.claims(in: text).map { "\($0.statement) = \($0.claimedText)" }
    }

    func outcomes(_ text: String, policy: ArithmeticPolicy = .standard) -> [ArithmeticFinding.Outcome] {
        ArithmeticChecker(policy: policy).check(text).findings.map(\.outcome)
    }

    func explanations(_ text: String, policy: ArithmeticPolicy = .standard) -> [String] {
        ArithmeticChecker(policy: policy).check(text).findings.map(\.explanation)
    }
}

extension Decimal {
    /// An exact decimal from its text, for expectations (float literals go through `Double`).
    static func of(_ text: String) -> Decimal {
        Decimal(string: text, locale: Locale(identifier: "en_US_POSIX")) ?? .nan
    }
}
