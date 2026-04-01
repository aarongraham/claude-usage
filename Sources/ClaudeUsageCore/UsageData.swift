import Foundation

public struct UsageResponse: Codable {
    public let fiveHour: FiveHourUsage?
    public let sevenDay: SevenDayUsage?
    public let extraUsage: ExtraUsage?

    enum CodingKeys: String, CodingKey {
        case fiveHour = "five_hour"
        case sevenDay = "seven_day"
        case extraUsage = "extra_usage"
    }
}

public struct FiveHourUsage: Codable {
    public let utilization: Double
    public let resetsAt: String

    enum CodingKeys: String, CodingKey {
        case utilization
        case resetsAt = "resets_at"
    }
}

public struct SevenDayUsage: Codable {
    public let utilization: Double
    public let resetsAt: String

    enum CodingKeys: String, CodingKey {
        case utilization
        case resetsAt = "resets_at"
    }
}

public struct ExtraUsage: Codable {
    public let isEnabled: Bool
    public let monthlyLimit: Int?
    public let usedCredits: Int?
    public let utilization: Double?

    enum CodingKeys: String, CodingKey {
        case isEnabled = "is_enabled"
        case monthlyLimit = "monthly_limit"
        case usedCredits = "used_credits"
        case utilization
    }
}

public struct UsageData {
    public let sessionUsage: Double
    public let sessionResetAt: Date
    public let weeklyUsage: Double
    public let weeklyResetAt: Date
    public let extraUsageEnabled: Bool
    public let extraUsageUtilization: Double?
    public let extraUsageUsed: Int?
    public let extraUsageLimit: Int?

    public static func from(response: UsageResponse) -> UsageData? {
        guard let fiveHour = response.fiveHour,
              let sevenDay = response.sevenDay else {
            return nil
        }

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        guard let sessionReset = formatter.date(from: fiveHour.resetsAt),
              let weeklyReset = formatter.date(from: sevenDay.resetsAt) else {
            return nil
        }

        return UsageData(
            sessionUsage: min(max(fiveHour.utilization, 0), 100),
            sessionResetAt: sessionReset,
            weeklyUsage: min(max(sevenDay.utilization, 0), 100),
            weeklyResetAt: weeklyReset,
            extraUsageEnabled: response.extraUsage?.isEnabled ?? false,
            extraUsageUtilization: response.extraUsage?.utilization,
            extraUsageUsed: response.extraUsage?.usedCredits,
            extraUsageLimit: response.extraUsage?.monthlyLimit
        )
    }
}
