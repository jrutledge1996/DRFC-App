import SwiftUI

struct MatchDetailView: View {
    let match: Match

    var resultColor: Color {
        switch match.result {
        case .win:  return .green
        case .loss: return .red
        case .draw: return .orange
        }
    }

    var body: some View {
        ZStack {
            Color(red: 0.07, green: 0.09, blue: 0.18).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    // Score header
                    ZStack {
                        DRFCTheme.navyGradient
                        VStack(spacing: 8) {
                            Text(match.opponent).font(.subheadline).foregroundColor(.white.opacity(0.75))
                            HStack(spacing: 20) {
                                VStack {
                                    Text("DRFC").font(.caption).foregroundColor(.white.opacity(0.7))
                                    Text("\(match.drfcScore)").font(.system(size: 52, weight: .black)).foregroundColor(.white)
                                }
                                Text("–").font(.largeTitle).foregroundColor(.white.opacity(0.5))
                                VStack {
                                    Text(match.opponent).font(.caption).foregroundColor(.white.opacity(0.7))
                                    Text("\(match.opponentScore)").font(.system(size: 52, weight: .black)).foregroundColor(.white)
                                }
                            }
                            Text(match.result.rawValue.uppercased())
                                .font(.caption).fontWeight(.bold).foregroundColor(.white)
                                .padding(.horizontal, 12).padding(.vertical, 4)
                                .background(resultColor).cornerRadius(6)
                            Text("\(match.date.formatted(date: .long, time: .omitted)) · \(match.venue)")
                                .font(.caption).foregroundColor(.white.opacity(0.65))
                            Text(match.team)
                                .font(.caption2).foregroundColor(DRFCTheme.lightBlue)
                        }
                        .padding(.vertical, 24)
                    }

                    // Player performances
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Player Performances")
                            .font(.headline).foregroundColor(.white)
                            .padding()

                        ForEach(match.playerPerformances.filter { $0.played }) { perf in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(perf.playerName).font(.subheadline).foregroundColor(.white)
                                    Spacer()
                                    if perf.tries > 0    { StatBadge(value: "\(perf.tries)",        label: "T") }
                                    if perf.conversions > 0 { StatBadge(value: "\(perf.conversions)", label: "C") }
                                    if perf.penalties > 0   { StatBadge(value: "\(perf.penalties)",   label: "P") }
                                    if perf.dropGoals > 0   { StatBadge(value: "\(perf.dropGoals)",   label: "DG") }
                                    if perf.points > 0 {
                                        Text("\(perf.points)pts")
                                            .font(.caption).fontWeight(.bold).foregroundColor(.white)
                                            .frame(minWidth: 44)
                                    }
                                }
                                if let pct = perf.kickingPercentage {
                                    Text("Kicking: \(perf.kicksMade)/\(perf.kicksAttempted) (\(String(format: "%.0f", pct))%)")
                                        .font(.caption2).foregroundColor(DRFCTheme.lightBlue)
                                }
                            }
                            .padding(.horizontal).padding(.vertical, 8)
                            Divider().background(Color.white.opacity(0.1)).padding(.leading)
                        }
                    }
                }
            }
        }
        .navigationTitle(match.opponent)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}
