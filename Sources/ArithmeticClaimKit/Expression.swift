import Foundation

/// What a claim says was computed, kept as a tree so it can be evaluated and written back out.
indirect enum Expression: Sendable, Hashable {
    case number(WrittenNumber)
    case negated(Expression)
    case grouped(Expression)
    case binary(ArithmeticOperator, Expression, Expression)
    case power(Expression, Int)
    /// `15% of 80`.
    case percentOf(WrittenNumber, Expression)
    /// The relative change `from A to B`, as a fraction (0.25 for a quarter more).
    case change(from: WrittenNumber, to: WrittenNumber)
    /// The difference between two percentages, as a fraction (0.1 for ten points).
    case pointChange(from: WrittenNumber, to: WrittenNumber)

    /// The exact value, or `nil` when the expression divides by zero or overflows.
    var value: Decimal? {
        let result: Decimal?
        switch self {
        case .number(let number):
            result = number.value
        case .negated(let inner):
            result = inner.value.map { -$0 }
        case .grouped(let inner):
            result = inner.value
        case let .binary(operation, left, right):
            result = Self.apply(operation, left, right)
        case let .power(base, exponent):
            result = base.value.map { pow($0, exponent) }
        case let .percentOf(percent, whole):
            result = whole.value.map { $0 * percent.value }
        case let .change(from, to):
            result = (to.value - from.value) / from.value
        case let .pointChange(from, to):
            result = to.value - from.value
        }
        guard let result, !result.isNaN else { return nil }
        return result
    }

    /// `80 - 15%` takes 15% of 80 away, the way a calculator does; `15% - 5%` is ten points.
    private static func apply(_ operation: ArithmeticOperator, _ left: Expression, _ right: Expression) -> Decimal? {
        guard let lhs = left.value, let rhs = right.value else { return nil }
        switch operation {
        case .plus, .minus:
            let amount = right.isBarePercent && !left.isBarePercent ? lhs * rhs : rhs
            return operation == .plus ? lhs + amount : lhs - amount
        case .times:
            return lhs * rhs
        case .dividedBy:
            return lhs / rhs
        }
    }

    private var isBarePercent: Bool {
        if case .number(let number) = self { return number.isPercent }
        return false
    }

    /// Whether any arithmetic happens: a lone number, signed or bracketed, does none.
    var hasOperation: Bool {
        switch self {
        case .number:
            return false
        case .negated(let inner), .grouped(let inner):
            return inner.hasOperation
        default:
            return true
        }
    }

    /// The number this is, when it is only a number (`12`, `-3`, `(5)`), and whether it is negated.
    var plainNumber: (number: WrittenNumber, isNegative: Bool)? {
        switch self {
        case .number(let number):
            return (number, false)
        case .negated(let inner):
            return inner.plainNumber.map { ($0.number, !$0.isNegative) }
        case .grouped(let inner):
            return inner.plainNumber
        default:
            return nil
        }
    }

    var isPercentOf: Bool {
        switch self {
        case .percentOf:
            return true
        case .grouped(let inner):
            return inner.isPercentOf
        default:
            return false
        }
    }

    /// Every number written in the expression.
    var numbers: [WrittenNumber] {
        switch self {
        case .number(let number):
            return [number]
        case .negated(let inner), .grouped(let inner), .power(let inner, _):
            return inner.numbers
        case let .binary(_, left, right):
            return left.numbers + right.numbers
        case let .percentOf(percent, whole):
            return [percent] + whole.numbers
        case let .change(from, to), let .pointChange(from, to):
            return [from, to]
        }
    }

    /// For a change between two percentages, the difference in points (as a fraction).
    var pointDifference: Decimal? {
        guard case let .change(from, to) = self, from.isPercent, to.isPercent else { return nil }
        return to.value - from.value
    }

    /// The expression written back out, numbers as the answer wrote them.
    var text: String {
        switch self {
        case .number(let number):
            return number.text
        case .negated(let inner):
            return "-" + inner.text
        case .grouped(let inner):
            return "(" + inner.text + ")"
        case let .binary(operation, left, right):
            return "\(left.text) \(operation.rawValue) \(right.text)"
        case let .power(base, exponent):
            return "\(base.text)^\(exponent)"
        case let .percentOf(percent, whole):
            return "\(percent.text) of \(whole.text)"
        case let .change(from, to), let .pointChange(from, to):
            return "from \(from.text) to \(to.text)"
        }
    }
}
