import Foundation

/// The identified user handed to providers on log in.
///
/// This is a `struct`, not a protocol as in v1: an `any AnalyticsUser` existential
/// would drag every adopter's user model into the concurrency domain and require it
/// to be `Sendable`. A value type with an open `traits` bag is simpler and copy-safe.
public struct AnalyticsUser: Hashable, Sendable {
    public var id: AnalyticsID
    public var firstName: String?
    public var lastName: String?
    public var email: String?

    /// Additional provider-agnostic attributes.
    public var traits: AnalyticsPayload

    public init(
        id: AnalyticsID,
        firstName: String? = nil,
        lastName: String? = nil,
        email: String? = nil,
        traits: AnalyticsPayload = .empty
    ) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.traits = traits
    }

    public var fullName: String? {
        let parts = [firstName, lastName].compactMap(\.self).filter { !$0.isEmpty }
        return parts.isEmpty ? nil : parts.joined(separator: " ")
    }
}
