import Foundation
import ClaudeUsageCore

@MainActor @Observable
class UsageService {
    var usageData: UsageData?
    var lastError: String?
    var isLoading = false

    private(set) var retryAfter: Date?
    private static let refreshInterval: TimeInterval = 180
    private static let apiURL = URL(string: "https://api.anthropic.com/api/oauth/usage")!

    private var pollingTask: Task<Void, Never>?

    func startPolling() {
        guard pollingTask == nil else { return }
        pollingTask = Task {
            while !Task.isCancelled {
                await fetch()
                try? await Task.sleep(for: .seconds(Self.refreshInterval))
            }
        }
    }

    func stopPolling() {
        pollingTask?.cancel()
        pollingTask = nil
    }

    func retryNow() async {
        retryAfter = nil
        KeychainHelper.clearCachedToken()
        await fetch()
    }

    func fetch() async {
        if let retryAfter, Date() < retryAfter {
            return
        }

        guard let token = KeychainHelper.getToken() else {
            lastError = "No OAuth token found"
            return
        }

        isLoading = true

        var request = URLRequest(url: Self.apiURL)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("oauth-2025-04-20", forHTTPHeaderField: "anthropic-beta")
        request.timeoutInterval = 5

        let (fetchData, fetchResponse): (Data?, URLResponse?)
        do {
            let result = try await URLSession.shared.data(for: request)
            fetchData = result.0
            fetchResponse = result.1
        } catch {
            isLoading = false
            lastError = "Network error"
            return
        }
        isLoading = false
        handleResponse(data: fetchData, response: fetchResponse)
    }

    private func handleResponse(data: Data?, response: URLResponse?) {
        guard let httpResponse = response as? HTTPURLResponse else {
            lastError = "Invalid response"
            return
        }

        if httpResponse.statusCode == 429 {
            let retrySeconds = httpResponse.value(forHTTPHeaderField: "Retry-After")
                .flatMap { Double($0) } ?? 300
            retryAfter = Date().addingTimeInterval(retrySeconds)
            lastError = "Rate limited"
            return
        }

        if httpResponse.statusCode == 401 {
            KeychainHelper.clearCachedToken()
            lastError = "Token expired — click Retry"
            return
        }

        guard httpResponse.statusCode == 200, let data else {
            lastError = "HTTP \(httpResponse.statusCode)"
            return
        }

        do {
            let apiResponse = try JSONDecoder().decode(UsageResponse.self, from: data)
            if let usage = UsageData.from(response: apiResponse) {
                usageData = usage
                lastError = nil
            } else {
                lastError = "Incomplete data"
            }
        } catch {
            lastError = "Parse error"
        }
    }
}
