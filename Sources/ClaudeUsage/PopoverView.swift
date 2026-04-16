import SwiftUI
import ClaudeUsageCore

struct PopoverView: View {
    let usageService: UsageService
    @State private var now = Date()
    @State private var isManualRefreshing = false
    @State private var showCompleted = false
    @State private var completedTask: Task<Void, Never>?

    private let minuteTimer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    private var peakStatus: PeakStatus {
        PeakTimeHelper.status(at: now)
    }

    private var isRateLimited: Bool {
        if let until = usageService.retryAfter {
            return now < until
        }
        return false
    }

    private let peakColor = Color(red: 0.83, green: 0.65, blue: 0.46)
    private let offPeakColor = Color(red: 0.20, green: 0.45, blue: 0.65)

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            if let data = usageService.usageData {
                usageContent(data: data)
            } else if let error = usageService.lastError {
                VStack(spacing: 8) {
                    Text(error)
                        .font(.system(size: 12))
                        .foregroundStyle(.red)
                    if error == "No OAuth token found" {
                        Text("Log in to Claude Code CLI first:\nclaude login")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                    Button("Retry") {
                        Task { await usageService.retryNow() }
                    }
                    .font(.system(size: 11))
                    .buttonStyle(.plain)
                    .foregroundStyle(Color.accentColor)
                }
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity)
            }
            Divider().opacity(0.3)
            HStack {
                Spacer()
                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.plain)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
            }
        }
        .padding(20)
        .frame(width: 320)
        .onReceive(minuteTimer) { _ in now = Date() }
    }

    private var header: some View {
        HStack(spacing: 8) {
            Text("Claude Usage")
                .font(.system(size: 14, weight: .semibold))
            peakBadge
            Spacer()
            refreshButton
        }
    }

    private var refreshButton: some View {
        Button(action: startManualRefresh) {
            ZStack {
                if showCompleted {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.green)
                } else if isManualRefreshing {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Image(systemName: "arrow.clockwise")
                        .foregroundStyle(.secondary)
                        .opacity(isRateLimited ? 0.4 : 1.0)
                }
            }
            .font(.system(size: 13, weight: .medium))
            .frame(width: 16, height: 16)
        }
        .buttonStyle(.plain)
        .disabled(isManualRefreshing || isRateLimited || showCompleted)
        .help(isRateLimited ? "Rate limited — try again in a few minutes" : "Refresh now")
    }

    private func startManualRefresh() {
        completedTask?.cancel()
        showCompleted = false
        isManualRefreshing = true
        Task {
            await usageService.fetch()
            isManualRefreshing = false
            guard usageService.lastError == nil, usageService.usageData != nil else {
                return
            }
            showCompleted = true
            completedTask = Task {
                try? await Task.sleep(for: .milliseconds(1200))
                if !Task.isCancelled {
                    showCompleted = false
                }
            }
        }
    }

    private var peakBadge: some View {
        Group {
            if peakStatus.isPeak {
                Text("● Peak")
                    .font(.system(size: 11))
                    .foregroundStyle(peakColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(peakColor.opacity(0.15))
                    .clipShape(Capsule())
            } else {
                Text("✦ Off-Peak")
                    .font(.system(size: 11))
                    .foregroundStyle(offPeakColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(offPeakColor.opacity(0.15))
                    .clipShape(Capsule())
            }
        }
    }

    @ViewBuilder
    private func usageContent(data: UsageData) -> some View {
        UsageBarView(
            label: "5-Hour Session",
            percentage: data.sessionUsage,
            resetDate: data.sessionResetAt,
            isPeak: peakStatus.isPeak
        )
        UsageBarView(
            label: "Weekly",
            percentage: data.weeklyUsage,
            resetDate: data.weeklyResetAt,
            isPeak: peakStatus.isPeak
        )
        peakInfoCard
        if data.extraUsageEnabled {
            extraUsageSection(data: data)
        }
    }

    private var peakInfoCard: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text("Peak Hours")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(peakTransitionText)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary.opacity(0.6))
            }
            Text("Weekdays 5am\u{2013}11am PT")
                .font(.system(size: 10))
                .foregroundStyle(.secondary.opacity(0.5))
        }
        .padding(10)
        .background(.secondary.opacity(0.05))
        .cornerRadius(8)
    }

    private var peakTransitionText: String {
        let remaining = peakStatus.timeUntilTransition
        let hours = Int(remaining) / 3600
        let minutes = (Int(remaining) % 3600) / 60
        let prefix = peakStatus.isPeak ? "Ends in" : "Starts in"
        if hours >= 24 {
            let days = hours / 24
            let remHours = hours % 24
            return "\(prefix) \(days)d \(remHours)h"
        }
        return "\(prefix) \(hours)h \(minutes)m"
    }

    private func extraUsageSection(data: UsageData) -> some View {
        VStack(spacing: 0) {
            Divider().opacity(0.3)
            HStack {
                Text("Extra Usage")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                Spacer()
                if let used = data.extraUsageUsed, let limit = data.extraUsageLimit {
                    Text("$\(String(format: "%.2f", used / 100)) / $\(String(format: "%.2f", limit / 100))")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary.opacity(0.7))
                }
            }
            .padding(.top, 10)
        }
    }
}
