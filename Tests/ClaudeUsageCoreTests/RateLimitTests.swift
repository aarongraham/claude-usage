import Testing
import Foundation
import ClaudeUsageCore

@Suite("RateLimit")
struct RateLimitTests {

    @Test("Parses a normal Retry-After header")
    func parsesNormalHeader() {
        #expect(RateLimit.retrySeconds(fromHeader: "300") == 300)
    }

    @Test("Clamps an over-long Retry-After to the ceiling")
    func clampsLongHeader() {
        // The bug: a 429 carrying ~59 minutes froze the popover for an hour.
        #expect(RateLimit.retrySeconds(fromHeader: "3540") == RateLimit.maxRetrySeconds)
    }

    @Test("Falls back to the default when the header is missing")
    func missingHeader() {
        #expect(RateLimit.retrySeconds(fromHeader: nil) == RateLimit.defaultRetrySeconds)
    }

    @Test("Falls back to the default when the header is not a number (e.g. HTTP-date)")
    func nonNumericHeader() {
        #expect(RateLimit.retrySeconds(fromHeader: "Wed, 10 Jun 2026 13:08:00 GMT")
            == RateLimit.defaultRetrySeconds)
    }

    @Test("Never returns a negative backoff")
    func negativeHeader() {
        #expect(RateLimit.retrySeconds(fromHeader: "-100") == 0)
    }
}
