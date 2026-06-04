import SwiftUI

struct AddMatchView: View {
    @EnvironmentObject var matchVM: MatchViewModel
    @EnvironmentObject var fixtureVM: FixtureViewModel
    @EnvironmentObject var playerVM: PlayerViewModel
    @Environment(\.dismiss) var dismiss

    @State private var opponent = ""
    @State private var date = Date()
    @State private var isHome = true
    @State private var venue = ""
    @State private var competition = ""
    @State private var season = ""
    @State private var drfcScore = ""
    @State private var opponentScore = ""
    @State private var performances: [PlayerPerformance] = []
    @State private var selectedFixtureId: String? = nil

    var body: some View {
        Form {
            Section("Link to Fixture (optional)") {
                Picker("Fixture", selection: $selectedFixtureId) {
                    Text("None").tag(String?.none)
                    ForEach(fixtureVM.fixtures.filter { !$0.isPlayed }) { f in
                        Text("\(f.opponent) – \(f.date.formatted(date: .abbreviated, time: .omitted))")
                            .tag(String?.some(f.id ?? ""))
                    }
                }
                .onChange(of: selectedFixtureId) { id in
                    if let id, let f = fixtureVM.fixtures.first(where: { $0.id == id }) {
                        opponent    = f.opponent
                        date        = f.date
                        isHome      = f.isHome
                        venue       = f.venue
                        competition = f.competition
                        season      = f.season
                    }
                }
            }

            Section("Match Details") {
                TextField("Opponent", text: $opponent)
                DatePicker("Date", selection: $date, displayedComponents: .date)
                TextField("Venue", text: $venue)
                TextField("Competition", text: $competition)
                TextField("Season (e.g. 2025/26)", text: $season)
                Toggle("Home Game", isOn: $isHome)
            }

            Section("Score") {
                HStack {
                    VStack {
                        Text("DRFC").font(.caption).foregroundColor(.secondary)
                        TextField("0", text: $drfcScore).keyboardType(.numberPad).multilineTextAlignment(.center)
                    }
                    Text("–").font(.title2)
                    VStack {
                        Text(opponent.isEmpty ? "Opp" : opponent).font(.caption).foregroundColor(.secondary)
                        TextField("0", text: $opponentScore).keyboardType(.numberPad).multilineTextAlignment(.center)
                    }
                }
            }

            Section("Players") {
                ForEach($performances) { $p in
                    PlayerPerformanceRow(performance: $p)
                }
                Button("Add Player") {
                    performances.append(PlayerPerformance(
                        playerId: UUID().uuidString, playerName: "", played: true,
                        tries: 0, conversions: 0, penalties: 0, dropGoals: 0
                    ))
                }
                .foregroundColor(DRFCTheme.lightBlue)

                // Quick-add from squad
                if !playerVM.players.isEmpty {
                    Menu("Add from Squad") {
                        ForEach(playerVM.players) { player in
                            Button(player.name) {
                                if !performances.contains(where: { $0.playerId == player.id }) {
                                    performances.append(PlayerPerformance(
                                        playerId: player.id ?? UUID().uuidString,
                                        playerName: player.name, played: true,
                                        tries: 0, conversions: 0, penalties: 0, dropGoals: 0
                                    ))
                                }
                            }
                        }
                    }
                    .foregroundColor(DRFCTheme.navy)
                }
            }

            Section {
                Button("Save Result") {
                    guard let dc = Int(drfcScore), let oc = Int(opponentScore),
                          !opponent.isEmpty, !season.isEmpty else { return }
                    let match = Match(
                        fixtureId: selectedFixtureId ?? "",
                        opponent: opponent, date: date, isHome: isHome,
                        venue: venue, competition: competition, season: season,
                        drfcScore: dc, opponentScore: oc,
                        playerPerformances: performances
                    )
                    matchVM.addMatch(match)
                    dismiss()
                }
                .foregroundColor(DRFCTheme.navy)
                .fontWeight(.bold)
            }
        }
        .navigationTitle("Record Result")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Per-player row

struct PlayerPerformanceRow: View {
    @Binding var performance: PlayerPerformance

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                TextField("Player name", text: $performance.playerName)
                    .font(.headline)
                Toggle("Played", isOn: $performance.played)
                    .labelsHidden()
            }
            if performance.played {
                HStack(spacing: 12) {
                    Stepper("T:\(performance.tries)", value: $performance.tries, in: 0...20)
                    Stepper("C:\(performance.conversions)", value: $performance.conversions, in: 0...20)
                }
                .font(.caption)
                HStack(spacing: 12) {
                    Stepper("P:\(performance.penalties)", value: $performance.penalties, in: 0...20)
                    Stepper("DG:\(performance.dropGoals)", value: $performance.dropGoals, in: 0...20)
                }
                .font(.caption)
            }
        }
        .padding(.vertical, 4)
    }
}
