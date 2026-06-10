import Foundation
import Combine
import FirebaseFirestore

class PlayerViewModel: ObservableObject {
    @Published var players: [Player] = []

    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?

    init() { subscribe() }
    deinit { listener?.remove() }

    func subscribe() {
        listener = db.collection("players")
            .order(by: "name")
            .addSnapshotListener { [weak self] snapshot, _ in
                guard let docs = snapshot?.documents else { return }
                DispatchQueue.main.async {
                    self?.players = docs.compactMap { try? $0.data(as: Player.self) }
                }
            }
    }

    func addPlayer(_ player: Player) {
        try? db.collection("players").addDocument(from: player)
    }

    func updatePlayer(_ player: Player) {
        guard let id = player.id else { return }
        try? db.collection("players").document(id).setData(from: player)
    }

    func deletePlayer(_ player: Player) {
        guard let id = player.id else { return }
        db.collection("players").document(id).delete()
    }
}
