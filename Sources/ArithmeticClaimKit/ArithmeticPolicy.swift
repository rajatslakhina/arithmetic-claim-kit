import Foundation

/// How strictly stated arithmetic is held to its exact value.
public struct ArithmeticPolicy: Sendable, Hashable {
    /// How far an approximate claim (`≈`, `about`) may be from the exact value, relative to it.
    public var approximateTolerance: Decimal
    /// Whether a result off by its last digit (`2/3 = 0.66`) is reported, or let through as rounding.
    public var flagsMisrounding: Bool
    /// Whether `from A to B, a P% increase` is read and checked.
    public var readsPercentChanges: Bool

    public init(
        approximateTolerance: Decimal = Decimal(sign: .plus, exponent: -2, significand: 1),
        flagsMisrounding: Bool = true,
        readsPercentChanges: Bool = true
    ) {
        self.approximateTolerance = approximateTolerance
        self.flagsMisrounding = flagsMisrounding
        self.readsPercentChanges = readsPercentChanges
    }

    /// Approximations within 1%; misrounding reported.
    public static let standard = ArithmeticPolicy()

    /// Approximations within 5%; misrounding let through.
    public static let lenient = ArithmeticPolicy(approximateTolerance: .hundredth * 5, flagsMisrounding: false)

    /// An approximation must still round to the digits it gives.
    public static let strict = ArithmeticPolicy(approximateTolerance: 0)
}
