import SwiftUI

struct ManagePlayersView: View {
    @EnvironmentObject var playerVM: PlayerViewModel
    @EnvironmentObject var authVM: AuthViewModel
    @State private var showAdd = false
    @State private var editPlayer: Player? = nil
    @State private var filterRegistered = false
    @State private var searchText = ""

    var displayedPlayers: [Player] {
        var result = filterRegistered ? playerVM.players.filter { $0.isRegistered } : playerVM.players
        let query = searchText.trimmingCharacters(in: .whitespaces)
        if !query.isEmpty {
            result = result.filter {
                $0.name.localizedCaseInsensitiveContains(query) ||
                ($0.nickname ?? "").localizedCaseInsensitiveContains(query) ||
                $0.position.localizedCaseInsensitiveContains(query)
            }
        }
        return result
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Toggle("Registered only", isOn: $filterRegistered)
                    .font(.subheadline).padding(.horizontal).padding(.vertical, 8)
            }
            .background(Color(UIColor.secondarySystemBackground))

            List {
                ForEach(displayedPlayers) { player in
                    PlayerRow(player: player, allPlayers: playerVM.players)
                        .swipeActions(edge: .trailing) {
                            if authVM.currentUser?.role == .admin {
                                Button { editPlayer = player } label: {
                                    Label("Edit", systemImage: "pencil")
                                }.tint(.orange)
                                Button(role: .destructive) {
                                    playerVM.deletePlayer(player)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                        .swipeActions(edge: .leading) {
                            if authVM.currentUser?.role == .admin {
                                Button {
                                    var updated = player
                                    updated.isRegistered.toggle()
                                    playerVM.updatePlayer(updated)
                                } label: {
                                    Label(player.isRegistered ? "Unregister" : "Register",
                                          systemImage: player.isRegistered ? "xmark.seal" : "checkmark.seal")
                                }.tint(player.isRegistered ? .gray : .green)
                            }
                        }
                }
            }
        }
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search players")
        .navigationTitle("Squad (\(playerVM.players.count))")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                if authVM.currentUser?.role == .admin {
                    Button { showAdd = true } label: { Image(systemName: "plus") }
                }
            }
        }
        .sheet(isPresented: $showAdd) {
            AddPlayerView().environmentObject(playerVM)
        }
        .sheet(item: $editPlayer) { player in
            EditPlayerView(player: player).environmentObject(playerVM)
        }
    }
}

// MARK: - Player row

struct PlayerRow: View {
    let player: Player
    var allPlayers: [Player] = []

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "person.fill")
                .foregroundColor(.white.opacity(0.6))
                .frame(width: 44, height: 44)
                .background(DRFCTheme.navy)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(allPlayers.disambiguatedName(for: player)).font(.headline)
                    if player.isRegistered {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.caption).foregroundColor(.green)
                    }
                }
                if player.nickname?.isEmpty == false {
                        Text(player.name).font(.caption2).foregroundColor(.secondary)
                    }
                Text(player.position).font(.caption).foregroundColor(.secondary)
                if player.totalBackfilledAppearances > 0 {
                    Text("\(player.totalBackfilledAppearances) backfilled (\(player.backfilledSummary))")
                        .font(.caption2).foregroundColor(.orange)
                }
            }

            Spacer()

            if let num = player.number {
                Text("#\(num)").font(.headline).foregroundColor(DRFCTheme.lightBlue)
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Add player

struct AddPlayerView: View {
    @EnvironmentObject var playerVM: PlayerViewModel
    @Environment(\.dismiss) var dismiss

    @State private var name = ""
    @State private var nickname = ""
    @State private var position = ""
    @State private var number = ""
    @State private var yearOfBirth = ""
    @State private var isRegistered = false
    @State private var showBackfill = false
    @State private var backfillByTeam: [String: String] = [:]

    /// Parsed { team -> count }, dropping blanks and zeros
    private var parsedBackfill: [String: Int] {
        backfillByTeam.reduce(into: [String: Int]()) { result, pair in
            if let n = Int(pair.value), n > 0 { result[pair.key] = n }
        }
    }
    private var backfillTotal: Int { parsedBackfill.values.reduce(0, +) }

    var body: some View {
        NavigationStack {
            Form {
                Section("Player Details") {
                    TextField("Full Name", text: $name)
                    TextField("Nickname (optional)", text: $nickname)
                    TextField("Position (e.g. Fly-half)", text: $position)
                    TextField("Squad number (optional)", text: $number).keyboardType(.numberPad)
                    TextField("Year of birth (e.g. 1998)", text: $yearOfBirth).keyboardType(.numberPad)
                    Text("Used to tell players with the same name apart.")
                        .font(.caption).foregroundColor(.secondary)
                    Toggle("Registered", isOn: $isRegistered)
                }

                Section("Historical Data") {
                    Toggle("Backfill previous appearances", isOn: $showBackfill)
                    if showBackfill {
                        BackfillTeamEditor(backfillByTeam: $backfillByTeam)
                        if backfillTotal > 0 {
                            Text("Total: \(backfillTotal) appearances")
                                .font(.caption).fontWeight(.semibold).foregroundColor(DRFCTheme.adaptiveAccent)
                        }
                        Text("Enter appearances per team made before this app was set up.")
                            .font(.caption).foregroundColor(.secondary)
                    }
                }

                Section {
                    Button("Add Player") {
                        guard !name.isEmpty else { return }
                        var p = Player(name: name, position: position,
                                       number: Int(number), isActive: true)
                        p.isRegistered = isRegistered
                        p.nickname = nickname.isEmpty ? nil : nickname
                        p.yearOfBirth = Int(yearOfBirth)
                        p.backfilledAppearancesByTeam = showBackfill ? parsedBackfill : [:]
                        playerVM.addPlayer(p)
                        dismiss()
                    }
                    .foregroundColor(DRFCTheme.adaptiveAccent).fontWeight(.bold)
                }
            }
            .navigationTitle("Add Player")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            }
        }
    }
}

// MARK: - Edit player

struct EditPlayerView: View {
    let player: Player
    @EnvironmentObject var playerVM: PlayerViewModel
    @Environment(\.dismiss) var dismiss

    @State private var name = ""
    @State private var nickname = ""
    @State private var position = ""
    @State private var number = ""
    @State private var yearOfBirth = ""
    @State private var isRegistered = false
    @State private var isActive = true
    @State private var backfillByTeam: [String: String] = [:]

    /// Parsed { team -> count }, dropping blanks and zeros
    private var parsedBackfill: [String: Int] {
        backfillByTeam.reduce(into: [String: Int]()) { result, pair in
            if let n = Int(pair.value), n > 0 { result[pair.key] = n }
        }
    }
    private var backfillTotal: Int { parsedBackfill.values.reduce(0, +) }

    var body: some View {
        NavigationStack {
            Form {
                Section("Player Details") {
                    TextField("Full Name", text: $name)
                    TextField("Nickname (optional)", text: $nickname)
                    TextField("Position", text: $position)
                    TextField("Squad number", text: $number).keyboardType(.numberPad)
                    TextField("Year of birth (e.g. 1998)", text: $yearOfBirth).keyboardType(.numberPad)
                    Toggle("Registered", isOn: $isRegistered)
                    Toggle("Active", isOn: $isActive)
                }

                Section("Historical Appearances") {
                    BackfillTeamEditor(backfillByTeam: $backfillByTeam)
                    if backfillTotal > 0 {
                        Text("Total: \(backfillTotal) appearances")
                            .font(.caption).fontWeight(.semibold).foregroundColor(DRFCTheme.adaptiveAccent)
                    }
                    Text("Count appearances per team made before this app was set up.")
                        .font(.caption).foregroundColor(.secondary)
                }

                Section {
                    Button("Save Changes") {
                        var updated = player
                        updated.name = name
                        updated.position = position
                        updated.number = Int(number)
                        updated.nickname = nickname.isEmpty ? nil : nickname
                        updated.yearOfBirth = Int(yearOfBirth)
                        updated.isRegistered = isRegistered
                        updated.isActive = isActive
                        updated.backfilledAppearancesByTeam = parsedBackfill
                        playerVM.updatePlayer(updated)
                        dismiss()
                    }
                    .foregroundColor(DRFCTheme.adaptiveAccent).fontWeight(.bold)
                }
            }
            .navigationTitle("Edit Player")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            }
            .onAppear {
                name = player.name; nickname = player.nickname ?? ""; position = player.position
                number = player.number.map { "\($0)" } ?? ""
                yearOfBirth = player.yearOfBirth.map { "\($0)" } ?? ""
                isRegistered = player.isRegistered; isActive = player.isActive
                backfillByTeam = player.backfilledAppearancesByTeam.mapValues { "\($0)" }
            }
        }
    }
}

// MARK: - Reusable per-team backfill editor

/// One number field per team, bound to a [teamRawValue: String] dictionary.
/// Used by both AddPlayerView and EditPlayerView so an admin can backfill
/// historical appearances across multiple teams at once.
struct BackfillTeamEditor: View {
    @Binding var backfillByTeam: [String: String]

    var body: some View {
        ForEach(Team.allCases) { team in
            HStack {
                Text(team.rawValue)
                Spacer()
                TextField("0", text: Binding(
                    get: { backfillByTeam[team.rawValue] ?? "" },
                    set: { backfillByTeam[team.rawValue] = $0 }
                ))
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 70)
            }
        }
    }
}
