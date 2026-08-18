import Foundation

/// The typed attribute bag carried by an event or a record.
public struct AnalyticsPayload: Hashable, Sendable {
    public private(set) var storage: [String: AnalyticsValue]

    public static let empty = AnalyticsPayload()

    public init(_ storage: [String: AnalyticsValue] = [:]) {
        self.storage = storage
    }

    /// Builds a payload from mixed convertible values, so call sites need not spell
    /// out `.analyticsValue` on every entry.
    public init(attributes: [String: any AnalyticsValueConvertible]) {
        self.storage = attributes.mapValues(\.analyticsValue)
    }

    // MARK: Access

    public subscript(key: String) -> AnalyticsValue? {
        get { storage[key] }
        set { storage[key] = newValue }
    }

    public var isEmpty: Bool { storage.isEmpty }
    public var count: Int { storage.count }
    public var keys: Dictionary<String, AnalyticsValue>.Keys { storage.keys }

    // MARK: Mutation

    public mutating func set(_ key: String, _ value: some AnalyticsValueConvertible) {
        storage[key] = value.analyticsValue
    }

    public mutating func remove(_ key: String) {
        storage.removeValue(forKey: key)
    }

    /// Returns a payload with `other`'s entries layered on top of this one's.
    public func merging(_ other: AnalyticsPayload) -> AnalyticsPayload {
        AnalyticsPayload(storage.merging(other.storage) { _, new in new })
    }

    public func adding(_ key: String, _ value: some AnalyticsValueConvertible) -> AnalyticsPayload {
        var copy = self
        copy.set(key, value)
        return copy
    }
}

// MARK: - ExpressibleByDictionaryLiteral

extension AnalyticsPayload: ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral elements: (String, AnalyticsValue)...) {
        self.init(Dictionary(elements) { _, latest in latest })
    }
}

// MARK: - Sequence

extension AnalyticsPayload: Sequence {
    public func makeIterator() -> Dictionary<String, AnalyticsValue>.Iterator {
        storage.makeIterator()
    }
}

// MARK: - CustomStringConvertible

extension AnalyticsPayload: CustomStringConvertible {
    public var description: String {
        storage
            .sorted { $0.key < $1.key }
            .map { "\($0.key): \($0.value)" }
            .joined(separator: ", ")
    }
}
