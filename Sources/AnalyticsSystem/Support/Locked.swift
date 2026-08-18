import Foundation

/// A minimal mutex box.
///
/// `Synchronization.Mutex` would be preferable but requires iOS 18, above this
/// package's iOS 15 floor. This is the only `@unchecked Sendable` in the package:
/// the stored value is reachable exclusively through ``withLock(_:)``, so the
/// unchecked conformance is discharged by construction.
///
/// - Note: Delete this type in favour of `Mutex` if the deployment floor ever
///   rises to iOS 18.
final class Locked<Value>: @unchecked Sendable {
    private var value: Value
    private let lock = NSLock()

    init(_ value: Value) {
        self.value = value
    }

    @discardableResult
    func withLock<Result>(_ body: (inout Value) throws -> Result) rethrows -> Result {
        lock.lock()
        defer { lock.unlock() }
        return try body(&value)
    }
}
