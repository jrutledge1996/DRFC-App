import SwiftUI

struct ManagePlayersView: View {
    @EnvironmentObject var playerVM: PlayerViewModel
    @State private var showAdd = false

    var body: some View {
        List {
            ForEach(playerVM.players) { player in
                HStack {
                    VStack(alignment: .leading) {
                        Text(player.name).font(.headline)
                        Text(player.position).font(.caption).foregroundColor(.secondary)
                    }
                    Spacer()
                    if let num = player.number {
                        Text("#\(num)")
                            .font(.headline)
                            .foregroundColor(DRFCTheme.lightBlue)
                    }
                }
            }
            .onDelete { idx in
                idx.forEach { i in playerVM.deletePlayer(playerVM.players[i]) }
            }
        }
        .navigationTitle("Squad")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showAdd = true } label: { Image(systemName: "plus") }
            }
        }
        .sheet(isPresented: $showAdd) {
            AddPlayerView().environmentObject(playerVM)
        }
    }
}

struct AddPlayerView: View {
    @EnvironmentObject var playerVM: PlayerViewModel
    @Environment(\.dismiss) var dismiss

    @State private var name = ""
    @State private var position = ""
    @State private var number = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $name)
                    TextField("Position", text: $position)
                    TextField("Squad number (optional)", text: $number)
                        .keyboardType(.numberPad)
                }
                Section {
                    Button("Add Player") {
                        guard !name.isEmpty else { return }
                        let p = Player(name: name, position: position, number: Int(number), isActive: true)
                        playerVM.addPlayer(p)
                        dismiss()
                    }
                    .foregroundColor(DRFCTheme.navy)
                    .fontWeight(.bold)
                }
            }
            .navigationTitle("Add Player")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
