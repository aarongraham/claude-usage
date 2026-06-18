import Foundation

/// Backoff math for 429 responses from the usage API.
///
/// The `/api/oauth/usage` endpoint shares one per-OAuth-token bucket with the
/// `claude` CLI and any claude.ai session, so this menu bar app can trip a 429
/// even when the account is nowhere near a usage limit. The endpoint normally
/// returns `Retry-After: 300`, but it can hand back much larger values. We must
/// not lock the UI out for an arbitrary server-chosen duration: a single 429
/// with a long `Retry-After` previously froze the popover for ~an hour even
/// though the limit had already cleared. Clamp it to a sane ceiling so the app
/// always self-heals on the next poll.
public enum RateLimit {
    /// Used when the 429 carries no parseable `Retry-After` header.
    public static let defaultRetrySeconds: TimeInterval = 300
    /// Upper bound on how long we'll honor a `Retry-After`. Matches the poll
    /// interval so a clamped window always expires by the next automatic fetch.
    public static let maxRetrySeconds: TimeInterval = 600

    /// Parse a 429 `Retry-After` header into a backoff duration, clamped to
    /// `[0, max]`. A missing/unparseable header falls back to `default`.
    public static func retrySeconds(
        fromHeader header: String?,
        default fallback: TimeInterval = defaultRetrySeconds,
        max cap: TimeInterval = maxRetrySeconds
    ) -> TimeInterval {
        let raw = header.flatMap { TimeInterval($0) } ?? fallback
        return min(Swift.max(raw, 0), cap)
    }
}
