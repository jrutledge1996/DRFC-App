import SwiftUI

struct DRFCTheme {
    static let navy      = Color(red: 0.05, green: 0.12, blue: 0.30)
    static let lightBlue = Color(red: 0.45, green: 0.72, blue: 0.92)
    static let white     = Color.white
    static let background = Color(UIColor.systemBackground)
    static let primaryText = Color.white
    static let secondaryText = Color.white.opacity(0.70)
    static let accent = Color.white

    // Gradient used in headers
    static var navyGradient: LinearGradient {
        LinearGradient(
            colors: [navy, navy.opacity(0.85)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // Full dark background for screens
    static var darkBackground: some View {
        Color(red: 0.07, green: 0.09, blue: 0.18).ignoresSafeArea()
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
                    .foregroundColor(.white.opacity(0.75))
                    .tracking(4)
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                if let sub = subtitle {
                    Text(sub)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.70))
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
                .foregroundColor(.white)
            Text(label)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.65))
        }
        .frame(minWidth: 52)
    }
}
