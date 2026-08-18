import Foundation
import Testing
@testable import AnalyticsSystem

@Suite("AnalyticsValue")
struct AnalyticsValueTests {
    @Test("Typed accessors return a value only for the matching case")
    func typedAccessors() {
        #expect(AnalyticsValue.string("x").stringValue == "x")
        #expect(AnalyticsValue.int(3).stringValue == nil)

        #expect(AnalyticsValue.int(3).intValue == 3)
        #expect(AnalyticsValue.string("x").intValue == nil)

        #expect(AnalyticsValue.bool(true).boolValue == true)
        #expect(AnalyticsValue.int(1).boolValue == nil)

        #expect(AnalyticsValue.null.isNull)
        #expect(!AnalyticsValue.int(0).isNull)
    }

    @Test("doubleValue promotes an integer")
    func doubleValuePromotesInt() {
        #expect(AnalyticsValue.double(2.5).doubleValue == 2.5)
        #expect(AnalyticsValue.int(2).doubleValue == 2.0)
        #expect(AnalyticsValue.string("2").doubleValue == nil)
    }

    @Test("Every case renders without a placeholder")
    func descriptions() throws {
        let url = try #require(URL(string: "https://example.com"))
        #expect(AnalyticsValue.string("x").description == "x")
        #expect(AnalyticsValue.int(3).description == "3")
        #expect(AnalyticsValue.bool(false).description == "false")
        #expect(AnalyticsValue.null.description == "null")
        #expect(AnalyticsValue.url(url).description == "https://example.com")
        #expect(AnalyticsValue.array([1, 2]).description == "[1, 2]")
        // Object keys are sorted so the rendering is stable enough to assert on.
        #expect(AnalyticsValue.object(["b": 2, "a": 1]).description == "{a: 1, b: 2}")
        #expect(AnalyticsValue.date(Date(timeIntervalSince1970: 0)).description.hasPrefix("1970-01-01"))
    }

    @Test("Every literal form produces the expected case")
    func literals() {
        #expect(AnalyticsValue("x") == .string("x"))
        #expect(AnalyticsValue(3) == .int(3))
        #expect(AnalyticsValue(2.5) == .double(2.5))
        #expect(AnalyticsValue(true) == .bool(true))
        #expect(AnalyticsValue(nilLiteral: ()) == .null)
        #expect([1, 2] as AnalyticsValue == .array([.int(1), .int(2)]))
        #expect(["a": 1] as AnalyticsValue == .object(["a": .int(1)]))
    }

    @Test("Scalar and collection conversions cover the convertible protocol")
    func convertibleConformances() throws {
        #expect("x".analyticsValue == .string("x"))
        #expect(3.analyticsValue == .int(3))
        #expect(Double(2.5).analyticsValue == .double(2.5))
        #expect(Float(1.5).analyticsValue == .double(1.5))
        #expect(true.analyticsValue == .bool(true))
        #expect(AnalyticsValue.int(1).analyticsValue == .int(1))

        let uuid = UUID()
        #expect(uuid.analyticsValue == .string(uuid.uuidString))

        let url = try #require(URL(string: "https://example.com"))
        #expect(url.analyticsValue == .url(url))

        #expect(["a", "b"].analyticsValue == .array([.string("a"), .string("b")]))
        #expect(["k": 1].analyticsValue == .object(["k": .int(1)]))
    }

    @Test("Payload mutation and access behave")
    func payloadOperations() {
        var payload = AnalyticsPayload()
        #expect(payload.isEmpty)

        payload.set("a", 1)
        payload["b"] = .string("x")
        #expect(payload.count == 2)
        #expect(Set(payload.keys) == ["a", "b"])
        #expect(payload.adding("c", true)["c"] == .bool(true))

        payload.remove("a")
        #expect(payload["a"] == nil)
        #expect(!payload.isEmpty)

        #expect(AnalyticsPayload(attributes: ["n": 1, "s": "x"]) == ["n": 1, "s": "x"])
        #expect(AnalyticsPayload(["a": 1]).description == "a: 1")
        #expect(payload.map(\.key).count == 1)
    }

    @Test("Records render name and payload")
    func recordDescription() {
        #expect(AnalyticsRecord(name: "e").description == "e")
        #expect(AnalyticsRecord(name: "e", attributes: ["a": 1]).description == "e { a: 1 }")
        #expect(!AnalyticsRecord(name: "").isValid)
    }

    @Test("Identifiers and users render and compose")
    func identifiersAndUsers() {
        #expect(AnalyticsID(rawValue: "x").description == "x")
        #expect(AnalyticsTrackerID.firebase.description == "firebase")

        let user = AnalyticsUser(id: "1", firstName: "Ada", lastName: "Lovelace")
        #expect(user.fullName == "Ada Lovelace")
        #expect(AnalyticsUser(id: "1", firstName: "Ada").fullName == "Ada")
        #expect(AnalyticsUser(id: "1").fullName == nil)
    }

    @Test("Adopter categories occupy the reserved range")
    func reservedCategories() {
        #expect(AnalyticsEventCategory.reserved(0).rawValue == 1 << 16)
        #expect(AnalyticsEventCategory.all.contains(.reserved(3)))
        #expect(!AnalyticsEventCategory.lifecycle.contains(.reserved(0)))
    }

    @Test("Errors describe themselves")
    func errorDescriptions() throws {
        let duplicate = AnalyticsError.duplicateTracker(.console)
        #expect(try #require(duplicate.errorDescription).contains("already registered"))

        let unknown = AnalyticsError.unknownTracker("nope")
        #expect(try #require(unknown.errorDescription).contains("nope"))
    }
}
