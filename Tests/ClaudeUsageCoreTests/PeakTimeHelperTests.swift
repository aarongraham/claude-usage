import Testing
import Foundation
@testable import ClaudeUsageCore

@Suite("PeakTimeHelper")
struct PeakTimeHelperTests {

    private let pt = TimeZone(identifier: "America/Los_Angeles")!

    private func date(year: Int, month: Int, day: Int, hour: Int, minute: Int = 0) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        components.timeZone = pt
        return Calendar(identifier: .gregorian).date(from: components)!
    }

    // 2030-01-01 is a Tuesday
    @Test func tuesdayDuringPeakHoursIsPeak() {
        let tuesday8am = date(year: 2030, month: 1, day: 1, hour: 8)
        let status = PeakTimeHelper.status(at: tuesday8am)
        #expect(status.isPeak == true)
    }

    @Test func tuesdayAfterPeakIsNotPeak() {
        let tuesday3pm = date(year: 2030, month: 1, day: 1, hour: 15)
        let status = PeakTimeHelper.status(at: tuesday3pm)
        #expect(status.isPeak == false)
    }

    @Test func tuesdayBeforePeakIsNotPeak() {
        let tuesday4am = date(year: 2030, month: 1, day: 1, hour: 4)
        let status = PeakTimeHelper.status(at: tuesday4am)
        #expect(status.isPeak == false)
    }

    // 2030-01-05 is a Saturday
    @Test func saturdayDuringPeakHoursIsNotPeak() {
        let saturday8am = date(year: 2030, month: 1, day: 5, hour: 8)
        let status = PeakTimeHelper.status(at: saturday8am)
        #expect(status.isPeak == false)
    }

    @Test func peakStartBoundaryIsInclusive() {
        let tuesday5am = date(year: 2030, month: 1, day: 1, hour: 5, minute: 0)
        let status = PeakTimeHelper.status(at: tuesday5am)
        #expect(status.isPeak == true)
    }

    @Test func peakEndBoundaryIsExclusive() {
        let tuesday11am = date(year: 2030, month: 1, day: 1, hour: 11, minute: 0)
        let status = PeakTimeHelper.status(at: tuesday11am)
        #expect(status.isPeak == false)
    }

    @Test func transitionTimeFromPeakToEnd() {
        let tuesday8am = date(year: 2030, month: 1, day: 1, hour: 8, minute: 0)
        let status = PeakTimeHelper.status(at: tuesday8am)
        // 3 hours until 11am
        #expect(abs(status.timeUntilTransition - 3 * 3600) < 60)
    }

    @Test func transitionTimeBeforePeakSameDay() {
        let tuesday3am = date(year: 2030, month: 1, day: 1, hour: 3, minute: 0)
        let status = PeakTimeHelper.status(at: tuesday3am)
        // 2 hours until 5am
        #expect(abs(status.timeUntilTransition - 2 * 3600) < 60)
    }

    @Test func transitionTimeFromWeekendToMonday() {
        // Saturday 8am → next Monday 5am = ~45 hours
        let saturday8am = date(year: 2030, month: 1, day: 5, hour: 8)
        let status = PeakTimeHelper.status(at: saturday8am)
        let expectedHours = 45.0 // Sat 8am → Mon 5am
        #expect(abs(status.timeUntilTransition - expectedHours * 3600) < 60)
    }

    @Test func transitionTimeAfterPeakOnWeekday() {
        // Tuesday 3pm → Wednesday 5am = 14 hours
        let tuesday3pm = date(year: 2030, month: 1, day: 1, hour: 15, minute: 0)
        let status = PeakTimeHelper.status(at: tuesday3pm)
        let expectedHours = 14.0
        #expect(abs(status.timeUntilTransition - expectedHours * 3600) < 60)
    }
}
