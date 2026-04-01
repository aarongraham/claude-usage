import SwiftUI

struct UsageBarView: View {
    let label: String
    let percentage: Double
    let resetDate: Date
    let isPeak: Bool

    private var barColor: Color {
        isPeak
            ? Color(red: 0.83, green: 0.65, blue: 0.46)
            : Color(red: 0.49, green: 0.72, blue: 0.85)
    }

    private var resetText: String {
        let remaining = resetDate.timeIntervalSinceNow
        if remaining <= 0 { return "Resetting..." }
        let hours = Int(remaining) / 3600
        let minutes = (Int(remaining) % 3600) / 60
        if hours >= 24 {
            let days = hours / 24
            let remHours = hours % 24
            return "Resets in \(days)d \(remHours)h"
        }
        return "Resets in \(hours)h \(minutes)m"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(label)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(Int(percentage))%")
                    .font(.system(size: 13, weight: .medium))
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(.secondary.opacity(0.2))
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(barColor)
                        .frame(
                            width: geometry.size.width * min(percentage / 100, 1),
                            height: 6
                        )
                }
            }
            .frame(height: 6)

            Text(resetText)
                .font(.system(size: 10))
                .foregroundStyle(.secondary.opacity(0.6))
        }
    }
}
