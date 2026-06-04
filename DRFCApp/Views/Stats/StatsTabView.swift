import SwiftUI

struct StatsTabView: View {
    @EnvironmentObject var statsVM: StatsViewModel
    @State private var selectedTab = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                DRFCHeader(title: "Stats", subtitle: statsVM.selectedSeason)

                if statsVM.seasons.count > 1 {
                    Picker("Season", selection: $statsVM.selectedSeason) {
                        ForEach(statsVM.seasons, id: \.self) { Text($0).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal).padding(.vertical, 8)
                    .onChange(of: statsVM.selectedSeason) { _ in
                        // recompute when season changes – handled in VM
                    }
                }

                Picker("Stat", selection: $selectedTab) {
                    Text("Appearances").tag(0)
                    Text("Try Scorers").tag(1)
                    Text("Points").tag(2)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal).padding(.bottom, 8)

                switch selectedTab {
                case 1:  StatLeaderboard(players: statsVM.topTryScorers,   valueKey: \.tries,       label: "Tries")
                case 2:  StatLeaderboard(players: statsVM.topPointScorers, valueKey: \.points,      label: "Pts")
                default: StatLeaderboard(players: statsVM.topAppearances,  valueKey: \.appearances, label: "Apps")
                }
            }
            .navigationBarHidden(true)
        }
    }
}

struct StatLeaderboard: View {
    let players: [PlayerStat]
    let valueKey: KeyPath<PlayerStat, Int>
    let label: String

    var body: some View {
        if players.isEmpty {
            Spacer()
            Text("No data yet").foregroundColor(.secondary)
            Spacer()
        } else {
            List {
                ForEach(Array(players.enumerated()), id: \.element.id) { index, player in
                    HStack(spacing: 14) {
                        // Rank
                        Text("\(index + 1)")
                            .font(.headline)
                            .foregroundColor(index == 0 ? DRFCTheme.lightBlue : .secondary)
                            .frame(width: 28, alignment: .center)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(player.name).font(.headline)
                            if label == "Pts" {
                                HStack(spacing: 8) {
                                    Text("T:\(player.tries)")
                                    Text("C:\(player.conversions)")
                                    Text("P:\(player.penalties)")
                                    Text("DG:\(player.dropGoals)")
                                }
                                .font(.caption2).foregroundColor(.secondary)
                            }
                        }

                        Spacer()

                        Text("\(player[keyPath: valueKey])")
                            .font(.title2).fontWeight(.bold)
                            .foregroundColor(DRFCTheme.navy)
                        Text(label)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .listStyle(.plain)
        }
    }
}
