import Testing
import Foundation
@testable import ClaudeUsageCore

@Suite("UsageData JSON Decoding")
struct UsageDataTests {

    let fullJSON = """
    {
        "five_hour": { "utilization": 42.5, "resets_at": "2030-01-01T12:00:00.000Z" },
        "seven_day": { "utilization": 17.3, "resets_at": "2030-01-07T00:00:00.000Z" },
        "extra_usage": {
            "is_enabled": true,
            "monthly_limit": 10000,
            "used_credits": 2500,
            "utilization": 25.0
        }
    }
    """.data(using: .utf8)!

    let noExtraUsageJSON = """
    {
        "five_hour": { "utilization": 10.0, "resets_at": "2030-01-01T12:00:00.000Z" },
        "seven_day": { "utilization": 5.0, "resets_at": "2030-01-07T00:00:00.000Z" }
    }
    """.data(using: .utf8)!

    @Test func decodesCompleteResponse() throws {
        let response = try JSONDecoder().decode(UsageResponse.self, from: fullJSON)
        let data = try #require(UsageData.from(response: response))
        #expect(data.sessionUsage == 42.5)
        #expect(data.weeklyUsage == 17.3)
        #expect(data.extraUsageEnabled == true)
        #expect(data.extraUsageUsed == 2500)
        #expect(data.extraUsageLimit == 10000)
    }

    @Test func decodesResponseWithoutExtraUsage() throws {
        let response = try JSONDecoder().decode(UsageResponse.self, from: noExtraUsageJSON)
        let data = try #require(UsageData.from(response: response))
        #expect(data.sessionUsage == 10.0)
        #expect(data.weeklyUsage == 5.0)
        #expect(data.extraUsageEnabled == false)
        #expect(data.extraUsageUsed == nil)
    }

    @Test func clampsUtilizationToRange() throws {
        let json = """
        {
            "five_hour": { "utilization": 150.0, "resets_at": "2030-01-01T12:00:00.000Z" },
            "seven_day": { "utilization": -5.0, "resets_at": "2030-01-07T00:00:00.000Z" }
        }
        """.data(using: .utf8)!
        let response = try JSONDecoder().decode(UsageResponse.self, from: json)
        let data = try #require(UsageData.from(response: response))
        #expect(data.sessionUsage == 100.0)
        #expect(data.weeklyUsage == 0.0)
    }

    @Test func parsesResetDates() throws {
        let response = try JSONDecoder().decode(UsageResponse.self, from: fullJSON)
        let data = try #require(UsageData.from(response: response))
        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents(in: TimeZone(identifier: "UTC")!, from: data.sessionResetAt)
        #expect(components.year == 2030)
        #expect(components.month == 1)
        #expect(components.day == 1)
        #expect(components.hour == 12)
    }

    @Test func returnsNilForMissingFiveHour() throws {
        let json = """
        { "seven_day": { "utilization": 5.0, "resets_at": "2030-01-07T00:00:00.000Z" } }
        """.data(using: .utf8)!
        let response = try JSONDecoder().decode(UsageResponse.self, from: json)
        #expect(UsageData.from(response: response) == nil)
    }
}
