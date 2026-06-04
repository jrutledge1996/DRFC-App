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
        ScrollView {
            VStack(spacing: 0) {
                // Score header
                ZStack {
                    DRFCTheme.navy
                    VStack(spacing: 8) {
                        Text(match.opponent).font(.subheadline).foregroundColor(DRFCTheme.lightBlue)
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
                            .font(.caption).fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12).padding(.vertical, 4)
                            .background(resultColor)
                            .cornerRadius(6)
                        Text("\(match.date.formatted(date: .long, time: .omitted)) · \(match.venue)")
                            .font(.caption).foregroundColor(.white.opacity(0.65))
                    }
                    .padding(.vertical, 24)
                }

                // Players
                VStack(alignment: .leading, spacing: 0) {
                    Text("Player Performances")
                        .font(.headline).foregroundColor(DRFCTheme.navy)
                        .padding()

                    ForEach(match.playerPerformances.filter { $0.played }) { perf in
                        HStack {
                            Text(perf.playerName).font(.subheadline)
                            Spacer()
                            if perf.tries > 0    { StatBadge(value: "\(perf.tries)",       label: "T") }
                            if perf.conversions > 0 { StatBadge(value: "\(perf.conversions)", label: "C") }
                            if perf.penalties > 0   { StatBadge(value: "\(perf.penalties)",   label: "P") }
                            if perf.dropGoals > 0   { StatBadge(value: "\(perf.dropGoals)",   label: "DG") }
                            if perf.points > 0 {
                                Text("\(perf.points)pts")
                                    .font(.caption).fontWeight(.bold)
                                    .foregroundColor(DRFCTheme.navy)
                                    .frame(minWidth: 44)
                            }
                        }
                        .padding(.horizontal).padding(.vertical, 8)
                        Divider().padding(.leading)
                    }
                }
            }
        }
        .navigationTitle(match.opponent)
        .navigationBarTitleDisplayMode(.inline)
    }
}
