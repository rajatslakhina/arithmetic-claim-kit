/// Reads percentage changes stated over `from A to B`: `went from 40 to 50, a 25% increase`,
/// `fell 20% from 50 to 40`, `from 40% to 50%, up 10 percentage points`.
struct ChangeReader {
    let tokens: [Token]
    let characters: [Character]

    func claims() -> [ArithmeticClaim] {
        tokens.indices.compactMap(claim(at:))
    }

    private func claim(at index: Int) -> ArithmeticClaim? {
        guard case .word("from") = tokens[index].kind,
              case .number(let from)? = tokens[safe: index + 1]?.kind,
              case .word("to")? = tokens[safe: index + 2]?.kind,
              case .number(let to)? = tokens[safe: index + 3]?.kind,
              let (figureIndex, figure) = self.figure(from: index + 4, step: 1)
                ?? self.figure(from: index - 1, step: -1)
        else { return nil }
        let points = pointWords(after: figureIndex)
        guard tokens[safe: figureIndex + points + 1]?.kind != .of,
              let (sign, signIndex) = direction(near: figureIndex, points: points),
              points == 0 ? figure.isPercent : from.isPercent && to.isPercent
        else { return nil }
        let lower = Swift.min(index, figureIndex, signIndex)
        let upper = Swift.max(index + 3, figureIndex + points, signIndex)
        let range = tokens[lower].range.lowerBound..<tokens[upper].range.upperBound
        let direction: ArithmeticClaim.Direction = sign > 0 ? .increase : sign < 0 ? .decrease : .unstated
        let computed: Expression = points > 0 ? .pointChange(from: from, to: to) : .change(from: from, to: to)
        let size = points > 0 ? " percentage-point" : ""
        let noun = direction == .unstated ? "change" : direction.rawValue
        let approximate = [figureIndex - 1, figureIndex - 2].contains { tokens[safe: $0]?.kind == .approximately }
        return ArithmeticClaim(
            kind: points > 0 ? .pointChange(direction) : .percentChange(direction),
            statement: computed.text,
            claimedText: "a \(figure.text)\(size) \(noun)",
            excerpt: String(characters[range]),
            range: range,
            isApproximate: approximate,
            computed: computed,
            claimed: ClaimedValue(change: figure, sign: sign, points: points > 0)
        )
    }

    /// The first percentage (or point figure) within six tokens, unless a stop, a clause word or
    /// another number comes first.
    private func figure(from start: Int, step: Int) -> (Int, WrittenNumber)? {
        for position in stride(from: start, to: start + 6 * step, by: step) {
            switch tokens[safe: position]?.kind {
            case .number(let number)?:
                return number.isPercent || pointWords(after: position) > 0 ? (position, number) : nil
            case .word(let word)? where Vocabulary.barriers.contains(word):
                return nil
            case .stop?, nil:
                return nil
            default:
                continue
            }
        }
        return nil
    }

    /// How many words after a figure say it is in points: `points`, `pp`, `percentage points`.
    private func pointWords(after position: Int) -> Int {
        if case .word(let word)? = tokens[safe: position + 1]?.kind, Vocabulary.pointWords.contains(word) {
            return 1
        }
        guard case .word("percentage")? = tokens[safe: position + 1]?.kind,
              case .word(let word)? = tokens[safe: position + 2]?.kind,
              Vocabulary.pointWords.contains(word) else { return 0 }
        return 2
    }

    /// The direction word nearest the figure, within three tokens either side.
    private func direction(near position: Int, points: Int) -> (Int, Int)? {
        for offset in [1 + points, -1, 2 + points, -2, 3 + points, -3] {
            if case .word(let word)? = tokens[safe: position + offset]?.kind,
               let sign = Vocabulary.direction(of: word) {
                return (sign, position + offset)
            }
        }
        return nil
    }
}
