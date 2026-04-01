import Foundation
import ClaudeUsageCore

@Observable
class UsageService {
    var usageData: UsageData?
    var lastError: String?
    var isLoading = false

    private var timer: Timer?
    private var retryAfter: Date?
    private static let refreshInterval: TimeInterval = 180
    private static let apiURL = URL(string: "https://api.anthropic.com/api/oauth/usage")!

    func startPolling() {
        guard timer == nil else { return }
        fetch()
        timer = Timer.scheduledTimer(withTimeInterval: Self.refreshInterval, repeats: true) { [weak self] _ in
            self?.fetch()
        }
    }

    func stopPolling() {
        timer?.invalidate()
        timer = nil
    }

    func fetch() {
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

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                self?.handleResponse(data: data, response: response, error: error)
            }
        }.resume()
    }

    private func handleResponse(data: Data?, response: URLResponse?, error: Error?) {
        if error != nil {
            lastError = "Network error"
            return
        }

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
