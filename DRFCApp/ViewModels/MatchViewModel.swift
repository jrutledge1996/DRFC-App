import Foundation
import Combine
import FirebaseFirestore

class MatchViewModel: ObservableObject {
    @Published var matches: [Match] = []
    @Published var selectedSeason: String = ""
    @Published var selectedTeam: String = "All Teams"
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
        matches.filter { m in
            (selectedSeason.isEmpty || m.season == selectedSeason) &&
            (selectedTeam == "All Teams" || m.team == selectedTeam)
        }
    }

    func addMatch(_ match: Match) {
        // Save match
        let ref = db.collection("matches").document()
        var saved = match
        saved.id = ref.documentID
        try? ref.setData(from: saved)

    }

    func updateMatch(_ match: Match, oldPerformances: [PlayerPerformance] = []) {
        guard let id = match.id else { return }
        try? db.collection("matches").document(id).setData(from: match)

    }

    func deleteMatch(_ match: Match) {
        guard let id = match.id else { return }
        db.collection("matches").document(id).delete()
    }

}
