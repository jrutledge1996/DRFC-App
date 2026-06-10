import Foundation
import Combine
import FirebaseFirestore

class FixtureViewModel: ObservableObject {
    @Published var fixtures: [Fixture] = []
    @Published var selectedSeason: String = ""
    @Published var selectedTeam: String = "All Teams"
    @Published var seasons: [String] = []

    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?

    init() { subscribe() }
    deinit { listener?.remove() }

    func subscribe() {
        listener = db.collection("fixtures")
            .order(by: "date")
            .addSnapshotListener { [weak self] snapshot, _ in
                guard let docs = snapshot?.documents else { return }
                let all = docs.compactMap { try? $0.data(as: Fixture.self) }
                DispatchQueue.main.async {
                    self?.fixtures = all
                    let s = Array(Set(all.map { $0.season })).sorted().reversed()
                    self?.seasons = Array(s)
                    if self?.selectedSeason.isEmpty == true {
                        self?.selectedSeason = self?.seasons.first ?? ""
                    }
                }
            }
    }

    var filtered: [Fixture] {
        fixtures.filter { f in
            (selectedSeason.isEmpty || f.season == selectedSeason) &&
            (selectedTeam == "All Teams" || f.team == selectedTeam)
        }
    }

    var upcoming: [Fixture] {
        filtered.filter { !$0.isPlayed && $0.date >= Date() }
    }

    /// Fixtures that have already been played or whose date has passed,
    /// most recent first.
    var previous: [Fixture] {
        filtered.filter { $0.isPlayed || $0.date < Date() }
            .sorted { $0.date > $1.date }
    }

    func addFixture(_ fixture: Fixture) {
        try? db.collection("fixtures").addDocument(from: fixture)
    }

    func updateFixture(_ fixture: Fixture) {
        guard let id = fixture.id else { return }
        try? db.collection("fixtures").document(id).setData(from: fixture)
    }

    func deleteFixture(_ fixture: Fixture) {
        guard let id = fixture.id else { return }
        db.collection("fixtures").document(id).delete()
    }
}
