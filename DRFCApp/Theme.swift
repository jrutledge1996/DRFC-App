import SwiftUI

struct DRFCTheme {
    static let navy      = Color(red: 0.05, green: 0.12, blue: 0.30)
    static let lightBlue = Color(red: 0.45, green: 0.72, blue: 0.92)
    static let white     = Color.white
    static let background = Color(UIColor.systemGroupedBackground)

    // Gradient used in headers
    static var navyGradient: LinearGradient {
        LinearGradient(
            colors: [navy, navy.opacity(0.80)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Reusable header banner

struct DRFCHeader: View {
    var title: String
    var subtitle: String? = nil

    var body: some View {
        ZStack {
            DRFCTheme.navyGradient
            VStack(spacing: 4) {
                Text("DRFC")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(DRFCTheme.lightBlue)
                    .tracking(4)
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                if let sub = subtitle {
                    Text(sub)
                        .font(.caption)
                        .foregroundColor(DRFCTheme.lightBlue.opacity(0.85))
                }
            }
            .padding(.vertical, 16)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Stat badge

struct StatBadge: View {
    var value: String
    var label: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.title3).fontWeight(.bold)
                .foregroundColor(DRFCTheme.navy)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(minWidth: 52)
    }
}
