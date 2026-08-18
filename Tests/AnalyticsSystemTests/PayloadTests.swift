import Foundation
import Testing
@testable import AnalyticsSystem

@Suite("Payload")
struct PayloadTests {
    @Test("Dictionary literals produce the same payload as explicit cases")
    func literalsMatchExplicitCases() {
        let literal: AnalyticsPayload = ["a": 1, "b": "x", "c": true, "d": 2.5]
        let explicit = AnalyticsPayload([
            "a": .int(1),
            "b": .string("x"),
            "c": .bool(true),
            "d": .double(2.5)
        ])

        #expect(literal == explicit)
    }

    @Test("RawRepresentable enums convert without boilerplate")
    func rawRepresentableConversion() {
        #expect(RegistrationMethod.facebook.analyticsValue == .string("Facebook"))
    }

    @Test("A nil optional becomes .null")
    func optionalBecomesNull() {
        let absent: String? = nil
        #expect(absent.analyticsValue == .null)
        #expect(String?("x").analyticsValue == .string("x"))
    }

    @Test("Equatable and Hashable hold for nested values")
    func hashableForNestedValues() {
        let first: AnalyticsValue = .object(["a": .array([1, 2])])
        let second: AnalyticsValue = .object(["a": .array([1, 2])])

        #expect(first == second)
        #expect(Set([first, second]).count == 1)
    }

    @Test("merging layers the argument on top")
    func mergingLayersArgument() {
        let base: AnalyticsPayload = ["a": 1, "b": 2]
        let merged = base.merging(["b": 3, "c": 4])

        #expect(merged == ["a": 1, "b": 3, "c": 4])
    }

    @Test(
        "Flattening collapses nested containers into compound keys",
        arguments: [
            (
                AnalyticsPayload(["user": .object(["id": .string("7")])]),
                AnalyticsPayload(["user_id": .string("7")])
            ),
            (
                AnalyticsPayload(["tags": .array([.string("a"), .string("b")])]),
                AnalyticsPayload(["tags_0": .string("a"), "tags_1": .string("b")])
            ),
            (
                AnalyticsPayload(["a": .object(["b": .object(["c": .int(1)])])]),
                AnalyticsPayload(["a_b_c": .int(1)])
            ),
            (
                AnalyticsPayload(["flat": .int(1)]),
                AnalyticsPayload(["flat": .int(1)])
            )
        ]
    )
    func flatteningShapes(input: AnalyticsPayload, expected: AnalyticsPayload) {
        #expect(input.flattened() == expected)
    }

    @Test("A custom separator is honoured")
    func flatteningUsesSeparator() {
        let payload = AnalyticsPayload(["user": .object(["id": .string("7")])])
        #expect(payload.flattened(separator: ".") == ["user.id": .string("7")])
    }
}
