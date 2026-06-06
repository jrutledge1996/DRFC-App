import SwiftUI

struct AddMatchView: View {
    @EnvironmentObject var matchVM: MatchViewModel
    @EnvironmentObject var fixtureVM: FixtureViewModel
    @EnvironmentObject var playerVM: PlayerViewModel
    @Environment(\.dismiss) var dismiss

    var existingMatch: Match? = nil

    @State private var opponent = ""
    @State private var date = Date()
    @State private var isHome = true
    @State private var venue = ""
    @State private var competition = ""
    @State private var season = ""
    @State private var selectedTeam = Team.firsts.rawValue
    @State private var isFriendly = false
    @State private var drfcScore = ""
    @State private var opponentScore = ""
    @State private var selectedFixtureId: String? = nil

    // Starters: slots 1-15
    @State private var starters: [Int: PlayerPerformance] = [:]
    // Bench: unlimited
    @State private var bench: [PlayerPerformance] = []

    // Player picker state
    @State private var pickingSlot: Int? = nil      // 1-15 = starter slot, 0 = bench
    @State private var showPicker = false

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Match details
                matchDetailsSection

                // Score
                scoreSection

                // Starters 1-15
                startersSection

                // Bench
                benchSection

                // Save button
                saveButton
                    .padding()
            }
        }
        .navigationTitle(existingMatch == nil ? "Record Result" : "Edit Result")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { loadExisting() }
        .sheet(isPresented: $showPicker) {
            PlayerPickerSheet(
                players: playerVM.players,
                alreadyPicked: pickedPlayerIds
            ) { player in
                assignPlayer(player)
            }
        }
    }

    // MARK: - Sections

    var matchDetailsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("Match Details")
            VStack(spacing: 12) {
                // Link fixture
                if !fixtureVM.fixtures.filter({ !$0.isPlayed }).isEmpty {
                    Menu {
                        Button("None") { selectedFixtureId = nil }
                        ForEach(fixtureVM.fixtures.filter { !$0.isPlayed }) { f in
                            Button("\(f.opponent) – \(f.date.formatted(date: .abbreviated, time: .omitted))") {
                                selectedFixtureId = f.id
                                if let fix = fixtureVM.fixtures.first(where: { $0.id == f.id }) {
                                    opponent = fix.opponent; date = fix.date; isHome = fix.isHome
                                    venue = fix.venue; competition = fix.competition; season = fix.season
                                    selectedTeam = fix.team; isFriendly = fix.isFriendly
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Text(selectedFixtureId == nil ? "Link to fixture (optional)" : "Fixture linked")
                                .foregroundColor(selectedFixtureId == nil ? .secondary : DRFCTheme.navy)
                            Spacer()
                            Image(systemName: "chevron.down").foregroundColor(.secondary)
                        }
                        .padding(12).background(Color(.systemGray6)).cornerRadius(10)
                    }
                }

                fieldRow("Opponent", text: $opponent)
                DatePicker("Date", selection: $date, displayedComponents: .date)
                    .padding(.horizontal, 4)
                fieldRow("Venue", text: $venue)
                fieldRow("Competition", text: $competition)
                fieldRow("Season (e.g. 2025/26)", text: $season)

                HStack {
                    Toggle("Home Game", isOn: $isHome)
                    Spacer()
                    Picker("Team", selection: $selectedTeam) {
                        ForEach(Team.allCases) { t in Text(t.rawValue).tag(t.rawValue) }
                    }
                    .pickerStyle(.menu)
                }
                .padding(.horizontal, 4)
            }
            .padding()
        }
    }

    var scoreSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("Score")
            HStack(spacing: 24) {
                VStack(spacing: 4) {
                    Text("DRFC").font(.caption).foregroundColor(.secondary)
                    TextField("0", text: $drfcScore)
                        .keyboardType(.numberPad).multilineTextAlignment(.center)
                        .font(.title).fontWeight(.bold)
                        .frame(width: 70).padding(8)
                        .background(Color(.systemGray6)).cornerRadius(10)
                }
                Text("–").font(.largeTitle).foregroundColor(.secondary)
                VStack(spacing: 4) {
                    Text(opponent.isEmpty ? "Opp" : opponent).font(.caption).foregroundColor(.secondary)
                    TextField("0", text: $opponentScore)
                        .keyboardType(.numberPad).multilineTextAlignment(.center)
                        .font(.title).fontWeight(.bold)
                        .frame(width: 70).padding(8)
                        .background(Color(.systemGray6)).cornerRadius(10)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
        }
    }

    var startersSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("Starting XV")
            VStack(spacing: 8) {
                ForEach(1...15, id: \.self) { slot in
                    StarterSlotRow(
                        slot: slot,
                        performance: starters[slot],
                        onTap: {
                            pickingSlot = slot
                            showPicker = true
                        },
                        onClear: { starters.removeValue(forKey: slot) },
                        onUpdate: { updated in starters[slot] = updated }
                    )
                }
            }
            .padding()
        }
    }

    var benchSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                sectionHeader("Bench")
                Spacer()
                Button {
                    pickingSlot = 0
                    showPicker = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(DRFCTheme.navy)
                        .font(.title3)
                }
                .padding(.trailing)
            }

            if bench.isEmpty {
                Text("Tap + to add bench players")
                    .font(.caption).foregroundColor(.secondary)
                    .padding()
            } else {
                VStack(spacing: 8) {
                    ForEach($bench) { $perf in
                        BenchPlayerRow(
                            performance: $perf,
                            onRemove: { bench.removeAll { $0.id == perf.id } }
                        )
                    }
                }
                .padding()
            }
        }
    }

    var saveButton: some View {
        Button(existingMatch == nil ? "Save Result" : "Update Result") {
            guard let dc = Int(drfcScore), let oc = Int(opponentScore),
                  !opponent.isEmpty, !season.isEmpty else { return }

            var allPerfs = Array(starters.values) + bench
            // Mark all as played
            for i in allPerfs.indices { allPerfs[i].played = true }

            var match = Match(
                fixtureId: selectedFixtureId ?? "",
                opponent: opponent, date: date, isHome: isHome,
                venue: venue, competition: competition, season: season,
                team: selectedTeam, isFriendly: isFriendly, drfcScore: dc, opponentScore: oc,
                playerPerformances: allPerfs
            )

            if let existing = existingMatch {
                match.id = existing.id
                matchVM.updateMatch(match, oldPerformances: existing.playerPerformances)
            } else {
                matchVM.addMatch(match)
            }
            dismiss()
        }
        .font(.headline).fontWeight(.bold).foregroundColor(.white)
        .frame(maxWidth: .infinity).padding()
        .background(DRFCTheme.navy).cornerRadius(14)
    }

    // MARK: - Helpers

    var pickedPlayerIds: Set<String> {
        var ids = Set(starters.values.map { $0.playerId })
        ids.formUnion(bench.map { $0.playerId })
        return ids
    }

    func assignPlayer(_ player: Player) {
        let perf = PlayerPerformance(
            playerId: player.id ?? UUID().uuidString,
            playerName: playerVM.players.disambiguatedName(for: player), played: true,
            positionNumber: pickingSlot == 0 ? nil : pickingSlot,
            isBench: pickingSlot == 0
        )
        if pickingSlot == 0 {
            bench.append(perf)
        } else if let slot = pickingSlot {
            starters[slot] = perf
        }
    }

    func loadExisting() {
        guard let m = existingMatch else { return }
        opponent = m.opponent; date = m.date; isHome = m.isHome
        venue = m.venue; competition = m.competition; season = m.season
        selectedTeam = m.team
        isFriendly = m.isFriendly
        drfcScore = "\(m.drfcScore)"; opponentScore = "\(m.opponentScore)"
        for perf in m.playerPerformances {
            if perf.isBench { bench.append(perf) }
            else if let slot = perf.positionNumber { starters[slot] = perf }
            else { bench.append(perf) }
        }
    }

    func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.headline).fontWeight(.bold)
            .padding(.horizontal).padding(.top, 16).padding(.bottom, 4)
    }

    func fieldRow(_ placeholder: String, text: Binding<String>) -> some View {
        TextField(placeholder, text: text)
            .padding(12).background(Color(.systemGray6)).cornerRadius(10)
    }
}

// MARK: - Starter slot row

struct StarterSlotRow: View {
    let slot: Int
    let performance: PlayerPerformance?
    let onTap: () -> Void
    let onClear: () -> Void
    let onUpdate: (PlayerPerformance) -> Void

    @State private var expanded = false

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Text("\(slot)")
                    .font(.caption).fontWeight(.bold).foregroundColor(.white)
                    .frame(width: 28, height: 28)
                    .background(DRFCTheme.navy).clipShape(Circle())

                if let perf = performance {
                    Button { expanded.toggle() } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(perf.playerName).font(.subheadline).fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                if perf.points > 0 {
                                    Text(scoreSummary(perf)).font(.caption).foregroundColor(.secondary)
                                }
                            }
                            Spacer()
                            if perf.points > 0 {
                                Text("\(perf.points)pts").font(.caption).fontWeight(.bold)
                                    .foregroundColor(DRFCTheme.navy)
                            }
                            Image(systemName: expanded ? "chevron.up" : "chevron.down")
                                .font(.caption).foregroundColor(.secondary)
                        }
                    }

                    Button { onClear() } label: {
                        Image(systemName: "xmark.circle.fill").foregroundColor(.red.opacity(0.7))
                    }
                } else {
                    Button { onTap() } label: {
                        Text("Add Player").foregroundColor(.secondary).font(.subheadline)
                        Spacer()
                        Image(systemName: "plus").foregroundColor(DRFCTheme.navy)
                    }
                }
            }
            .padding(10)
            .background(Color(.systemGray6)).cornerRadius(10)

            if expanded, var perf = performance {
                ScoringInputView(performance: Binding(
                    get: { perf },
                    set: { perf = $0; onUpdate($0) }
                ))
                .padding(.horizontal, 4).padding(.bottom, 4)
            }
        }
    }
}

// MARK: - Bench player row

struct BenchPlayerRow: View {
    @Binding var performance: PlayerPerformance
    let onRemove: () -> Void
    @State private var expanded = false

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Text("B")
                    .font(.caption).fontWeight(.bold).foregroundColor(.white)
                    .frame(width: 28, height: 28)
                    .background(DRFCTheme.lightBlue).clipShape(Circle())

                Button { expanded.toggle() } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(performance.playerName).font(.subheadline).fontWeight(.semibold)
                                .foregroundColor(.primary)
                            if performance.points > 0 {
                                Text(scoreSummary(performance)).font(.caption).foregroundColor(.secondary)
                            }
                        }
                        Spacer()
                        if performance.points > 0 {
                            Text("\(performance.points)pts").font(.caption).fontWeight(.bold)
                                .foregroundColor(DRFCTheme.navy)
                        }
                        Image(systemName: expanded ? "chevron.up" : "chevron.down")
                            .font(.caption).foregroundColor(.secondary)
                    }
                }

                Button { onRemove() } label: {
                    Image(systemName: "xmark.circle.fill").foregroundColor(.red.opacity(0.7))
                }
            }
            .padding(10)
            .background(Color(.systemGray6)).cornerRadius(10)

            if expanded {
                ScoringInputView(performance: $performance)
                    .padding(.horizontal, 4).padding(.bottom, 4)
            }
        }
    }
}

// MARK: - Scoring input

struct ScoringInputView: View {
    @Binding var performance: PlayerPerformance

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 16) {
                counterField("Tries", value: $performance.tries)
                counterField("Conv", value: $performance.conversions)
                counterField("Pens", value: $performance.penalties)
                counterField("DG", value: $performance.dropGoals)
            }

            HStack(spacing: 8) {
                Text("Kicking:").font(.caption).foregroundColor(.secondary)
                counterField("Made", value: $performance.kicksMade)
                Text("/").foregroundColor(.secondary)
                counterField("Att", value: $performance.kicksAttempted)
                if let pct = performance.kickingPercentage {
                    Text(String(format: "%.0f%%", pct))
                        .font(.caption).fontWeight(.bold).foregroundColor(DRFCTheme.navy)
                }
            }
        }
        .padding(10)
        .background(Color(.systemGray5)).cornerRadius(8)
    }

    func counterField(_ label: String, value: Binding<Int>) -> some View {
        VStack(spacing: 2) {
            Text(label).font(.caption2).foregroundColor(.secondary)
            HStack(spacing: 6) {
                Button { if value.wrappedValue > 0 { value.wrappedValue -= 1 } } label: {
                    Image(systemName: "minus.circle").foregroundColor(DRFCTheme.navy)
                }
                Text("\(value.wrappedValue)").font(.subheadline).fontWeight(.bold).frame(minWidth: 20)
                Button { value.wrappedValue += 1 } label: {
                    Image(systemName: "plus.circle").foregroundColor(DRFCTheme.navy)
                }
            }
        }
    }
}

// MARK: - Player picker sheet

struct PlayerPickerSheet: View {
    let players: [Player]
    let alreadyPicked: Set<String>
    let onSelect: (Player) -> Void
    @State private var search = ""
    @Environment(\.dismiss) var dismiss

    var filtered: [Player] {
        let available = players.filter { !alreadyPicked.contains($0.id ?? "") }
        return search.isEmpty ? available : available.filter { $0.name.localizedCaseInsensitiveContains(search) || ($0.nickname ?? "").localizedCaseInsensitiveContains(search) }
    }

    var body: some View {
        NavigationStack {
            List(filtered) { player in
                Button {
                    onSelect(player)
                    dismiss()
                } label: {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(players.disambiguatedName(for: player)).foregroundColor(.primary)
                            Text(player.position).font(.caption).foregroundColor(.secondary)
                        }
                        Spacer()
                        if player.isRegistered {
                            Image(systemName: "checkmark.seal.fill").foregroundColor(.green).font(.caption)
                        }
                    }
                }
            }
            .searchable(text: $search, prompt: "Search players")
            .navigationTitle("Select Player")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Score summary helper

func scoreSummary(_ p: PlayerPerformance) -> String {
    var parts: [String] = []
    if p.tries > 0 { parts.append("\(p.tries)T") }
    if p.conversions > 0 { parts.append("\(p.conversions)C") }
    if p.penalties > 0 { parts.append("\(p.penalties)P") }
    if p.dropGoals > 0 { parts.append("\(p.dropGoals)DG") }
    if let pct = p.kickingPercentage { parts.append(String(format: "%.0f%%", pct)) }
    return parts.joined(separator: " · ")
}
