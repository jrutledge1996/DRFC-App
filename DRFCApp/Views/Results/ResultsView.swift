import SwiftUI

struct ResultsView: View {
    @EnvironmentObject var matchVM: MatchViewModel

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                DRFCHeader(title: "Results", subtitle: matchVM.selectedSeason)

                if matchVM.seasons.count > 1 {
                    Picker("Season", selection: $matchVM.selectedSeason) {
                        ForEach(matchVM.seasons, id: \.self) { Text($0).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }

                // Season summary bar
                if !matchVM.filteredMatches.isEmpty {
                    SeasonSummaryBar(matches: matchVM.filteredMatches)
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                }

                if matchVM.filteredMatches.isEmpty {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "sportscourt")
                            .font(.system(size: 44))
                            .foregroundColor(DRFCTheme.lightBlue)
                        Text("No results yet")
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                } else {
                    List(matchVM.filteredMatches) { match in
                        NavigationLink(destination: MatchDetailView(match: match)) {
                            MatchResultRow(match: match)
                        }
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    }
                    .listStyle(.plain)
                }
            }
            .navigationBarHidden(true)
        }
    }
}

// MARK: - Season summary

struct SeasonSummaryBar: View {
    let matches: [Match]

    var wins: Int   { matches.filter { $0.result == .win  }.count }
    var draws: Int  { matches.filter { $0.result == .draw }.count }
    var losses: Int { matches.filter { $0.result == .loss }.count }

    var body: some View {
        HStack(spacing: 0) {
            summaryCell(value: "\(wins)",   label: "W", color: .green)
            Divider()
            summaryCell(value: "\(draws)",  label: "D", color: .orange)
            Divider()
            summaryCell(value: "\(losses)", label: "L", color: .red)
        }
        .frame(height: 52)
        .background(DRFCTheme.navy.opacity(0.06))
        .cornerRadius(10)
    }

    func summaryCell(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.title3).fontWeight(.bold).foregroundColor(color)
            Text(label).font(.caption2).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Match row

struct MatchResultRow: View {
    let match: Match

    var resultColor: Color {
        switch match.result {
        case .win:  return .green
        case .loss: return .red
        case .draw: return .orange
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            // Result pill
            Text(match.result.rawValue.uppercased())
                .font(.caption).fontWeight(.black)
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(resultColor)
                .cornerRadius(6)

            VStack(alignment: .leading, spacing: 4) {
                Text("vs \(match.opponent)")
                    .font(.headline)
                    .foregroundColor(DRFCTheme.navy)
                Text(match.competition)
                    .font(.caption).foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(match.drfcScore) – \(match.opponentScore)")
                    .font(.title3).fontWeight(.bold)
                    .foregroundColor(DRFCTheme.navy)
                Text(match.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption2).foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
