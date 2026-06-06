import SwiftUI

struct StatsTabView: View {
    @EnvironmentObject var statsVM: StatsViewModel
    @State private var selectedTab = 0

    let teamOptions = ["All Teams"] + Team.allCases.map { $0.rawValue }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.07, green: 0.09, blue: 0.18).ignoresSafeArea()

                VStack(spacing: 0) {
                    DRFCHeader(title: "Stats", subtitle: statsVM.selectedSeason)

                    // Season picker
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(statsVM.seasons, id: \.self) { s in
                                Button(s) { statsVM.selectedSeason = s; statsVM.recompute() }
                                    .padding(.horizontal, 12).padding(.vertical, 6)
                                    .background(statsVM.selectedSeason == s ? Color.white : Color.white.opacity(0.15))
                                    .foregroundColor(statsVM.selectedSeason == s ? DRFCTheme.navy : .white)
                                    .cornerRadius(16)
                                    .font(.caption).fontWeight(.semibold)
                            }
                        }
                        .padding(.horizontal).padding(.vertical, 8)
                    }

                    // Team picker
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(teamOptions, id: \.self) { t in
                                Button(t) { statsVM.selectedTeam = t; statsVM.recompute() }
                                    .padding(.horizontal, 12).padding(.vertical, 6)
                                    .background(statsVM.selectedTeam == t ? DRFCTheme.lightBlue : Color.white.opacity(0.10))
                                    .foregroundColor(.white)
                                    .cornerRadius(16)
                                    .font(.caption).fontWeight(.semibold)
                            }
                        }
                        .padding(.horizontal).padding(.bottom, 8)
                    }

                    // Stat category picker
                    Picker("Stat", selection: $selectedTab) {
                        Text("Apps").tag(0)
                        Text("Tries").tag(1)
                        Text("Points").tag(2)
                        Text("Kicking").tag(3)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal).padding(.bottom, 8)

                    switch selectedTab {
                    case 1:  StatLeaderboard(players: statsVM.topTryScorers,   valueKey: \.tries,       label: "Tries")
                    case 2:  StatLeaderboard(players: statsVM.topPointScorers, valueKey: \.points,      label: "Pts")
                    case 3:  KickingLeaderboard(players: statsVM.topKickers)
                    default: StatLeaderboard(players: statsVM.topAppearances,  valueKey: \.appearances, label: "Apps")
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
}

// MARK: - Generic leaderboard

struct StatLeaderboard: View {
    let players: [PlayerStat]
    let valueKey: KeyPath<PlayerStat, Int>
    let label: String

    var body: some View {
        if players.isEmpty {
            Spacer()
            Text("No data yet").foregroundColor(.white.opacity(0.5))
            Spacer()
        } else {
            List {
                ForEach(Array(players.enumerated()), id: \.element.id) { index, player in
                    HStack(spacing: 14) {
                        Text("\(index + 1)")
                            .font(.headline)
                            .foregroundColor(index == 0 ? DRFCTheme.lightBlue : .white.opacity(0.5))
                            .frame(width: 28, alignment: .center)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(player.name).font(.headline).foregroundColor(.white)
                            if label == "Pts" {
                                HStack(spacing: 8) {
                                    Text("T:\(player.tries)")
                                    Text("C:\(player.conversions)")
                                    Text("P:\(player.penalties)")
                                    Text("DG:\(player.dropGoals)")
                                }
                                .font(.caption2).foregroundColor(.white.opacity(0.6))
                            }
                        }

                        Spacer()

                        Text("\(player[keyPath: valueKey])")
                            .font(.title2).fontWeight(.bold).foregroundColor(.white)
                        Text(label).font(.caption).foregroundColor(.white.opacity(0.6))
                    }
                    .padding(.vertical, 4)
                    .listRowBackground(Color(red: 0.10, green: 0.13, blue: 0.25))
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
    }
}

// MARK: - Kicking leaderboard

struct KickingLeaderboard: View {
    let players: [PlayerStat]

    var body: some View {
        if players.isEmpty {
            Spacer()
            Text("No kicking data yet").foregroundColor(.white.opacity(0.5))
            Spacer()
        } else {
            List {
                ForEach(Array(players.enumerated()), id: \.element.id) { index, player in
                    HStack(spacing: 14) {
                        Text("\(index + 1)")
                            .font(.headline)
                            .foregroundColor(index == 0 ? DRFCTheme.lightBlue : .white.opacity(0.5))
                            .frame(width: 28)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(player.name).font(.headline).foregroundColor(.white)
                            Text("\(player.kicksMade)/\(player.kicksAttempted) kicks")
                                .font(.caption2).foregroundColor(.white.opacity(0.6))
                        }

                        Spacer()

                        if let pct = player.kickingPercentage {
                            Text(String(format: "%.0f%%", pct))
                                .font(.title2).fontWeight(.bold).foregroundColor(.white)
                        }
                    }
                    .padding(.vertical, 4)
                    .listRowBackground(Color(red: 0.10, green: 0.13, blue: 0.25))
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
    }
}
