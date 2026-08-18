import Foundation

/// A coarse classification used to admit or reject events per tracker.
///
/// Unlike its v1 predecessor this option set actually ships members, so
/// `filter: .categories(.authentication)` works out of the box. Bits 0–15 are
/// reserved by the library; adopters declare their own via ``reserved(_:)``.
public struct AnalyticsEventCategory: OptionSet, Hashable, Sendable {
    public let rawValue: UInt32

    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }

    public static let lifecycle = Self(rawValue: 1 << 0)
    public static let authentication = Self(rawValue: 1 << 1)
    public static let onboarding = Self(rawValue: 1 << 2)
    public static let engagement = Self(rawValue: 1 << 3)
    public static let commerce = Self(rawValue: 1 << 4)
    public static let diagnostics = Self(rawValue: 1 << 5)
    public static let custom = Self(rawValue: 1 << 6)

    /// Declares an adopter-defined category. `bit` is zero-based within the
    /// adopter range, so `.reserved(0)` is the first category you own.
    ///
    /// - Precondition: `bit` must be less than 16.
    public static func reserved(_ bit: UInt32) -> Self {
        precondition(bit < 16, "Adopter categories are limited to bits 0..<16.")
        return Self(rawValue: 1 << (16 + bit))
    }

    public static let all = Self(rawValue: .max)
    public static let none: Self = []
}
