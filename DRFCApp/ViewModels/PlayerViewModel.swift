import Foundation
import Combine
import FirebaseFirestore
import FirebaseStorage

class PlayerViewModel: ObservableObject {
    @Published var players: [Player] = []

    private let db = Firestore.firestore()
    private let storage = Storage.storage()
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
        // Also delete photo if exists
        if let url = player.photoURL {
            let ref = storage.reference(forURL: url)
            ref.delete(completion: nil)
        }
    }

    // MARK: - Photo upload

    func uploadPhotoAndAdd(player: Player, imageData: Data, completion: @escaping () -> Void) {
        let ref = storage.reference().child("playerPhotos/\(UUID().uuidString).jpg")
        ref.putData(imageData, metadata: nil) { [weak self] _, error in
            guard error == nil else { completion(); return }
            ref.downloadURL { url, _ in
                var updated = player
                updated.photoURL = url?.absoluteString
                self?.addPlayer(updated)
                DispatchQueue.main.async { completion() }
            }
        }
    }

    func uploadPhotoAndUpdate(player: Player, imageData: Data, completion: @escaping () -> Void) {
        let ref = storage.reference().child("playerPhotos/\(UUID().uuidString).jpg")
        ref.putData(imageData, metadata: nil) { [weak self] _, error in
            guard error == nil else { completion(); return }
            ref.downloadURL { url, _ in
                var updated = player
                updated.photoURL = url?.absoluteString
                self?.updatePlayer(updated)
                DispatchQueue.main.async { completion() }
            }
        }
    }
}
