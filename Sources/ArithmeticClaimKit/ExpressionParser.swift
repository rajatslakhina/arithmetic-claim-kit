/// Reads one expression from a token position, the usual way: powers, then `×` and `/`, then `+`
/// and `-`, with brackets, a leading minus and `15% of 80`. Whatever it cannot use, it leaves.
struct ExpressionParser {
    let tokens: [Token]
    var position: Int

    mutating func expression() -> Expression? {
        guard let first = term() else { return nil }
        return additions(after: first)
    }

    /// Carries on from `seed` (`48, plus 10` is `48 + 10`); `nil` unless an operator is used.
    mutating func continuation(of seed: Expression) -> Expression? {
        let start = position
        let result = additions(after: multiplications(after: seed))
        return position == start ? nil : result
    }

    private mutating func additions(after first: Expression) -> Expression {
        var result = first
        while case .operation(let operation)? = tokens[safe: position]?.kind,
              operation == .plus || operation == .minus {
            let mark = position
            position += 1
            guard let right = term() else {
                position = mark
                break
            }
            result = .binary(operation, result, right)
        }
        return result
    }

    private mutating func term() -> Expression? {
        guard let first = factor() else { return nil }
        return multiplications(after: first)
    }

    private mutating func multiplications(after first: Expression) -> Expression {
        var result = first
        while case .operation(let operation)? = tokens[safe: position]?.kind,
              operation == .times || operation == .dividedBy {
            let mark = position
            position += 1
            guard let right = factor() else {
                position = mark
                break
            }
            result = .binary(operation, result, right)
        }
        return result
    }

    private mutating func factor() -> Expression? {
        if case .operation(.minus)? = tokens[safe: position]?.kind {
            let mark = position
            position += 1
            guard let inner = factor() else {
                position = mark
                return nil
            }
            return .negated(inner)
        }
        guard let base = primary() else { return nil }
        let raised = powers(of: base)
        guard case .number(let percent) = raised, percent.isPercent, case .of? = tokens[safe: position]?.kind else {
            return raised
        }
        let mark = position
        position += 1
        guard let whole = factor() else {
            position = mark
            return raised
        }
        return .percentOf(percent, whole)
    }

    private mutating func powers(of base: Expression) -> Expression {
        guard case .power(let written)? = tokens[safe: position]?.kind else { return base }
        let mark = position
        position += 1
        var exponent = written
        if exponent == nil, case .number(let number)? = tokens[safe: position]?.kind, let value = number.exponent {
            exponent = value
            position += 1
        }
        guard let exponent, exponent <= 12 else {
            position = mark
            return base
        }
        return .power(base, exponent)
    }

    private mutating func primary() -> Expression? {
        switch tokens[safe: position]?.kind {
        case .number(let number)?:
            position += 1
            return .number(number)
        case .open?:
            let mark = position
            position += 1
            guard let inner = expression(), case .close? = tokens[safe: position]?.kind else {
                position = mark
                return nil
            }
            position += 1
            return .grouped(inner)
        default:
            return nil
        }
    }
}
