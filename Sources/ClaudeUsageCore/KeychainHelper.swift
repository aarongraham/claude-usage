import Foundation

public enum KeychainHelper {

    struct Credentials: Codable {
        let claudeAiOauth: OAuthToken
    }

    struct OAuthToken: Codable {
        let accessToken: String
    }

    nonisolated(unsafe) private static var cachedToken: String?

    public static func clearCachedToken() {
        cachedToken = nil
    }

    public static func getToken() -> String? {
        if let cached = cachedToken {
            return cached
        }
        let token = readViaSecurityCLI()
        cachedToken = token
        return token
    }

    // Reading via /usr/bin/security (rather than calling SecItemCopyMatching
    // from this process) avoids a recurring password prompt. Claude Code
    // rotates the OAuth token every ~4h and its SecItemUpdate scrubs non-Apple
    // entries from the keychain item's partition_id list — including this
    // app's cdhash — so the next direct read reprompts. /usr/bin/security is
    // in the apple-tool: partition, which is never scrubbed, so it can read
    // silently across rotations.
    static func readViaSecurityCLI() -> String? {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/security")
        task.arguments = ["find-generic-password", "-s", "Claude Code-credentials", "-w"]

        let stdout = Pipe()
        task.standardOutput = stdout
        task.standardError = Pipe()

        do {
            try task.run()
            task.waitUntilExit()
        } catch {
            return nil
        }

        guard task.terminationStatus == 0 else {
            return nil
        }

        let data = stdout.fileHandleForReading.readDataToEndOfFile()
        return extractToken(from: data)
    }

    public static func extractToken(from data: Data) -> String? {
        guard let credentials = try? JSONDecoder().decode(Credentials.self, from: data) else {
            return nil
        }
        return credentials.claudeAiOauth.accessToken
    }
}
