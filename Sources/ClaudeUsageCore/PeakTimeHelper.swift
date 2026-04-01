import Foundation

public struct PeakStatus {
    public let isPeak: Bool
    public let timeUntilTransition: TimeInterval

    public init(isPeak: Bool, timeUntilTransition: TimeInterval) {
        self.isPeak = isPeak
        self.timeUntilTransition = timeUntilTransition
    }
}

public enum PeakTimeHelper {
    public static let peakStartHour = 5
    public static let peakEndHour = 11

    private static var ptCalendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "America/Los_Angeles")!
        return cal
    }

    public static func status(at date: Date = Date()) -> PeakStatus {
        let cal = ptCalendar
        let weekday = cal.component(.weekday, from: date)
        let hour = cal.component(.hour, from: date)
        let isWeekday = weekday >= 2 && weekday <= 6
        let isPeak = isWeekday && hour >= peakStartHour && hour < peakEndHour

        let transition: TimeInterval
        if isPeak {
            let endOfPeak = cal.date(bySettingHour: peakEndHour, minute: 0, second: 0, of: date)!
            transition = endOfPeak.timeIntervalSince(date)
        } else if isWeekday && hour < peakStartHour {
            let startOfPeak = cal.date(bySettingHour: peakStartHour, minute: 0, second: 0, of: date)!
            transition = startOfPeak.timeIntervalSince(date)
        } else {
            transition = timeUntilNextPeakStart(from: date, calendar: cal)
        }

        return PeakStatus(isPeak: isPeak, timeUntilTransition: max(0, transition))
    }

    private static func timeUntilNextPeakStart(from date: Date, calendar cal: Calendar) -> TimeInterval {
        var next = cal.startOfDay(for: date)
        next = cal.date(byAdding: .day, value: 1, to: next)!
        while true {
            let wd = cal.component(.weekday, from: next)
            if wd >= 2 && wd <= 6 { break }
            next = cal.date(byAdding: .day, value: 1, to: next)!
        }
        next = cal.date(bySettingHour: peakStartHour, minute: 0, second: 0, of: next)!
        return next.timeIntervalSince(date)
    }
}
