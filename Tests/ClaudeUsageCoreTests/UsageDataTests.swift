import Testing
@testable import ClaudeUsageCore

@Test func placeholder() {
    let data = UsageData(sessionUsage: 42.0)
    #expect(data.sessionUsage == 42.0)
}
