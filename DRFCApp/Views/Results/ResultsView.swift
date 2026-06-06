import SwiftUI

struct ResultsView: View {
    @EnvironmentObject var matchVM: MatchViewModel
    @EnvironmentObject var authVM: AuthViewModel
    @State private var editMatch: Match? = nil

    let teamOptions = ["All Teams"] + Team.allCases.map { $0.rawValue }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.07, green: 0.09, blue: 0.18).ignoresSafeArea()

                VStack(spacing: 0) {
                    DRFCHeader(title: "Results", subtitle: matchVM.selectedSeason)

                    // Season picker
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(matchVM.seasons, id: \.self) { s in
                                Button(s) { matchVM.selectedSeason = s }
                                    .padding(.horizontal, 12).padding(.vertical, 6)
                                    .background(matchVM.selectedSeason == s ? Color.white : Color.white.opacity(0.15))
                                    .foregroundColor(matchVM.selectedSeason == s ? DRFCTheme.navy : .white)
                                    .cornerRadius(16).font(.caption).fontWeight(.semibold)
                            }
                        }
                        .padding(.horizontal).padding(.vertical, 8)
                    }

                    // Team picker
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(teamOptions, id: \.self) { t in
                                Button(t) { matchVM.selectedTeam = t }
                                    .padding(.horizontal, 12).padding(.vertical, 6)
                                    .background(matchVM.selectedTeam == t ? DRFCTheme.lightBlue : Color.white.opacity(0.10))
                                    .foregroundColor(.white)
                                    .cornerRadius(16).font(.caption).fontWeight(.semibold)
                            }
                        }
                        .padding(.horizontal).padding(.bottom, 8)
                    }

                    if !matchVM.filteredMatches.filter({ !$0.isFriendly }).isEmpty {
                        SeasonSummaryBar(matches: matchVM.filteredMatches.filter { !$0.isFriendly }).padding(.horizontal).padding(.bottom, 8)
                    }

                    if matchVM.filteredMatches.isEmpty {
                        Spacer()
                        VStack(spacing: 8) {
                            Image(systemName: "sportscourt").font(.system(size: 44)).foregroundColor(DRFCTheme.lightBlue)
                            Text("No results yet").foregroundColor(.white.opacity(0.6))
                        }
                        Spacer()
                    } else {
                        List(matchVM.filteredMatches) { match in
                            NavigationLink(destination: MatchDetailView(match: match)) {
                                MatchResultRow(match: match)
                            }
                            .listRowBackground(Color(red: 0.10, green: 0.13, blue: 0.25))
                            .swipeActions(edge: .trailing) {
                                if authVM.currentUser?.role == .admin {
                                    Button { editMatch = match } label: {
                                        Label("Edit", systemImage: "pencil")
                                    }.tint(.orange)
                                    Button(role: .destructive) {
                                        matchVM.deleteMatch(match)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(item: $editMatch) { match in
                NavigationStack {
                    AddMatchView(existingMatch: match)
                        .environmentObject(matchVM)
                        .environmentObject(fixtureVMPlaceholder)
                        .environmentObject(PlayerViewModel())
                }
            }
        }
    }

    // Needed for the sheet — pull from environment properly
    @EnvironmentObject var fixtureVM: FixtureViewModel
    var fixtureVMPlaceholder: FixtureViewModel { fixtureVM }
}

// MARK: - Season summary bar

struct SeasonSummaryBar: View {
    let matches: [Match]

    var wins:   Int { matches.filter { $0.result == .win  }.count }
    var draws:  Int { matches.filter { $0.result == .draw }.count }
    var losses: Int { matches.filter { $0.result == .loss }.count }

    var winPct: String {
        let total = wins + draws + losses
        guard total > 0 else { return "–" }
        return String(format: "%.0f%%", Double(wins) / Double(total) * 100)
    }

    var body: some View {
        HStack(spacing: 0) {
            summaryCell(value: "\(wins)",   label: "W", color: .green)
            Divider().background(Color.white.opacity(0.2))
            summaryCell(value: "\(draws)",  label: "D", color: .orange)
            Divider().background(Color.white.opacity(0.2))
            summaryCell(value: "\(losses)", label: "L", color: .red)
            Divider().background(Color.white.opacity(0.2))
            summaryCell(value: winPct, label: "Win%", color: .white)
        }
        .frame(height: 52)
        .background(Color.white.opacity(0.08))
        .cornerRadius(10)
    }

    func summaryCell(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.title3).fontWeight(.bold).foregroundColor(color)
            Text(label).font(.caption2).foregroundColor(.white.opacity(0.6))
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
            Text(match.result.rawValue.uppercased())
                .font(.caption).fontWeight(.black).foregroundColor(.white)
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(resultColor).cornerRadius(6)

            VStack(alignment: .leading, spacing: 4) {
                Text("vs \(match.opponent)").font(.headline).foregroundColor(.white)
                HStack(spacing: 6) {
                    Text(match.competition).font(.caption).foregroundColor(.white.opacity(0.6))
                    Text("·").foregroundColor(.white.opacity(0.3))
                    Text(match.team).font(.caption).foregroundColor(DRFCTheme.lightBlue)
                    if match.isFriendly {
                        Text("Friendly").font(.caption2).fontWeight(.semibold)
                            .foregroundColor(.white).padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Color.orange.opacity(0.7)).cornerRadius(4)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(match.drfcScore) – \(match.opponentScore)")
                    .font(.title3).fontWeight(.bold).foregroundColor(.white)
                Text(match.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption2).foregroundColor(.white.opacity(0.6))
            }
        }
        .padding(.vertical, 4)
    }
}
