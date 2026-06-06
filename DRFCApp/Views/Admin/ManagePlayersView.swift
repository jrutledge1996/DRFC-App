import SwiftUI
import FirebaseStorage
import PhotosUI

struct ManagePlayersView: View {
    @EnvironmentObject var playerVM: PlayerViewModel
    @EnvironmentObject var authVM: AuthViewModel
    @State private var showAdd = false
    @State private var editPlayer: Player? = nil
    @State private var filterRegistered = false

    var displayedPlayers: [Player] {
        filterRegistered ? playerVM.players.filter { $0.isRegistered } : playerVM.players
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
            // Photo or placeholder
            Group {
                if let url = player.photoURL, let imageURL = URL(string: url) {
                    AsyncImage(url: imageURL) { img in
                        img.resizable().scaledToFill()
                    } placeholder: {
                        Image(systemName: "person.fill")
                            .foregroundColor(.white.opacity(0.6))
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(DRFCTheme.navy)
                    }
                } else {
                    Image(systemName: "person.fill")
                        .foregroundColor(.white.opacity(0.6))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(DRFCTheme.navy)
                }
            }
            .frame(width: 44, height: 44)
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
    @State private var selectedPhoto: PhotosPickerItem? = nil
    @State private var photoData: Data? = nil
    @State private var isUploading = false

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

                Section("Player Photo") {
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        HStack {
                            if let data = photoData, let uiImage = UIImage(data: data) {
                                Image(uiImage: uiImage)
                                    .resizable().scaledToFill()
                                    .frame(width: 48, height: 48).clipShape(Circle())
                            } else {
                                Image(systemName: "person.crop.circle.badge.plus")
                                    .font(.title2).foregroundColor(DRFCTheme.navy)
                            }
                            Text(photoData == nil ? "Add Photo" : "Change Photo")
                                .foregroundColor(DRFCTheme.navy)
                        }
                    }
                    .onChange(of: selectedPhoto) { _, item in
                        Task {
                            photoData = try? await item?.loadTransferable(type: Data.self)
                        }
                    }
                }

                Section("Historical Data") {
                    Toggle("Backfill previous appearances", isOn: $showBackfill)
                    if showBackfill {
                        BackfillTeamEditor(backfillByTeam: $backfillByTeam)
                        if backfillTotal > 0 {
                            Text("Total: \(backfillTotal) appearances")
                                .font(.caption).fontWeight(.semibold).foregroundColor(DRFCTheme.navy)
                        }
                        Text("Enter appearances per team made before this app was set up.")
                            .font(.caption).foregroundColor(.secondary)
                    }
                }

                Section {
                    Button(isUploading ? "Saving..." : "Add Player") {
                        guard !name.isEmpty, !isUploading else { return }
                        isUploading = true
                        var p = Player(name: name, position: position,
                                       number: Int(number), isActive: true)
                        p.isRegistered = isRegistered
                        p.nickname = nickname.isEmpty ? nil : nickname
                        p.yearOfBirth = Int(yearOfBirth)
                        p.backfilledAppearancesByTeam = showBackfill ? parsedBackfill : [:]

                        if let data = photoData {
                            playerVM.uploadPhotoAndAdd(player: p, imageData: data) { dismiss() }
                        } else {
                            playerVM.addPlayer(p)
                            dismiss()
                        }
                    }
                    .foregroundColor(DRFCTheme.navy).fontWeight(.bold).disabled(isUploading)
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
    @State private var selectedPhoto: PhotosPickerItem? = nil
    @State private var photoData: Data? = nil
    @State private var isUploading = false

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

                Section("Player Photo") {
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        HStack {
                            Group {
                                if let data = photoData, let uiImage = UIImage(data: data) {
                                    Image(uiImage: uiImage).resizable().scaledToFill()
                                } else if let url = player.photoURL, let imageURL = URL(string: url) {
                                    AsyncImage(url: imageURL) { img in img.resizable().scaledToFill() }
                                    placeholder: { Image(systemName: "person.fill").foregroundColor(.gray) }
                                } else {
                                    Image(systemName: "person.crop.circle.badge.plus")
                                        .font(.title2).foregroundColor(DRFCTheme.navy)
                                        .frame(width: 48, height: 48)
                                }
                            }
                            .frame(width: 48, height: 48).clipShape(Circle())
                            Text("Change Photo").foregroundColor(DRFCTheme.navy)
                        }
                    }
                    .onChange(of: selectedPhoto) { _, item in
                        Task { photoData = try? await item?.loadTransferable(type: Data.self) }
                    }
                }

                Section("Historical Appearances") {
                    BackfillTeamEditor(backfillByTeam: $backfillByTeam)
                    if backfillTotal > 0 {
                        Text("Total: \(backfillTotal) appearances")
                            .font(.caption).fontWeight(.semibold).foregroundColor(DRFCTheme.navy)
                    }
                    Text("Count appearances per team made before this app was set up.")
                        .font(.caption).foregroundColor(.secondary)
                }

                Section {
                    Button(isUploading ? "Saving..." : "Save Changes") {
                        guard !isUploading else { return }
                        isUploading = true
                        var updated = player
                        updated.name = name
                        updated.position = position
                        updated.number = Int(number)
                        updated.nickname = nickname.isEmpty ? nil : nickname
                        updated.yearOfBirth = Int(yearOfBirth)
                        updated.isRegistered = isRegistered
                        updated.isActive = isActive
                        updated.backfilledAppearancesByTeam = parsedBackfill

                        if let data = photoData {
                            playerVM.uploadPhotoAndUpdate(player: updated, imageData: data) { dismiss() }
                        } else {
                            playerVM.updatePlayer(updated)
                            dismiss()
                        }
                    }
                    .foregroundColor(DRFCTheme.navy).fontWeight(.bold).disabled(isUploading)
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
