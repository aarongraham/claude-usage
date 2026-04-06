import Foundation
@preconcurrency import Security

public enum KeychainHelper {

    struct Credentials: Codable {
        let claudeAiOauth: OAuthToken
    }

    struct OAuthToken: Codable {
        let accessToken: String
    }

    public static func getToken() -> String? {
        // Read from credentials file directly to avoid repeated keychain password prompts.
        // The keychain item is owned by Claude Code, so macOS prompts on every access.
        return readFromCredentialsFile()
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
