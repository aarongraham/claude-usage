import Testing
import Foundation
@testable import ClaudeUsageCore

@Suite("KeychainHelper Token Extraction")
struct KeychainHelperTests {

    @Test func extractsTokenFromValidJSON() {
        let json = """
        { "claudeAiOauth": { "accessToken": "sk-test-token-123" } }
        """.data(using: .utf8)!
        let token = KeychainHelper.extractToken(from: json)
        #expect(token == "sk-test-token-123")
    }

    @Test func returnsNilForInvalidJSON() {
        let json = "not json".data(using: .utf8)!
        let token = KeychainHelper.extractToken(from: json)
        #expect(token == nil)
    }

    @Test func returnsNilForMissingOAuthField() {
        let json = """
        { "someOtherField": { "accessToken": "token" } }
        """.data(using: .utf8)!
        let token = KeychainHelper.extractToken(from: json)
        #expect(token == nil)
    }

    @Test func returnsNilForMissingAccessToken() {
        let json = """
        { "claudeAiOauth": { "refreshToken": "token" } }
        """.data(using: .utf8)!
        let token = KeychainHelper.extractToken(from: json)
        #expect(token == nil)
    }
}
