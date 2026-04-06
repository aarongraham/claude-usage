import Foundation
@preconcurrency import Security

public enum KeychainHelper {

    struct Credentials: Codable {
        let claudeAiOauth: OAuthToken
    }

    struct OAuthToken: Codable {
        let accessToken: String
    }

    nonisolated(unsafe) private static var cachedToken: String?

    public static func getToken() -> String? {
        if let cached = cachedToken {
            return cached
        }
        // Prefer credentials file (no password prompt).
        // Fall back to keychain (prompts once, then cached for session).
        let token = readFromCredentialsFile() ?? readFromKeychain()
        cachedToken = token
        return token
    }

    static func readFromKeychain() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "Claude Code-credentials",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data else {
            return nil
        }

        return extractToken(from: data)
    }

    static func readFromCredentialsFile() -> String? {
        let configDir = ProcessInfo.processInfo.environment["CLAUDE_CONFIG_DIR"]
            ?? NSHomeDirectory() + "/.claude"
        let path = configDir + "/.credentials.json"

        guard let data = FileManager.default.contents(atPath: path) else {
            return nil
        }

        return extractToken(from: data)
    }

    public static func extractToken(from data: Data) -> String? {
        guard let credentials = try? JSONDecoder().decode(Credentials.self, from: data) else {
            return nil
        }
        return credentials.claudeAiOauth.accessToken
    }
}
