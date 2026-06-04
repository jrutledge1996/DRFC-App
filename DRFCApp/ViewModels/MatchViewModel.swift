import Foundation
import Combine
import FirebaseFirestore

class MatchViewModel: ObservableObject {
    @Published var matches: [Match] = []
    @Published var selectedSeason: String = ""
    @Published var seasons: [String] = []

    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?

    init() { subscribe() }

    deinit { listener?.remove() }

    func subscribe() {
        listener = db.collection("matches")
            .order(by: "date", descending: true)
            .addSnapshotListener { [weak self] snapshot, _ in
                guard let docs = snapshot?.documents else { return }
                let all = docs.compactMap { try? $0.data(as: Match.self) }
                DispatchQueue.main.async {
                    self?.matches = all
                    let s = Array(Set(all.map { $0.season })).sorted().reversed()
                    self?.seasons = Array(s)
                    if self?.selectedSeason.isEmpty == true {
                        self?.selectedSeason = self?.seasons.first ?? ""
                    }
                }
            }
    }

    var filteredMatches: [Match] {
        matches.filter { $0.season == selectedSeason }
    }

    func addMatch(_ match: Match) {
        try? db.collection("matches").addDocument(from: match)
    }
}
