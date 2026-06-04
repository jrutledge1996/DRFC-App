import Foundation
import Combine
import FirebaseFirestore

struct PlayerStat: Identifiable {
    var id: String
    var name: String
    var appearances: Int
    var tries: Int
    var conversions: Int
    var penalties: Int
    var dropGoals: Int
    var points: Int { (tries * 5) + (conversions * 2) + (penalties * 3) + (dropGoals * 3) }
}

class StatsViewModel: ObservableObject {
    @Published var playerStats: [PlayerStat] = []
    @Published var selectedSeason: String = ""
    @Published var seasons: [String] = []

    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?

    init() { subscribe() }
    deinit { listener?.remove() }

    func subscribe() {
        listener = db.collection("matches")
            .addSnapshotListener { [weak self] snapshot, _ in
                guard let docs = snapshot?.documents else { return }
                let matches = docs.compactMap { try? $0.data(as: Match.self) }
                DispatchQueue.main.async {
                    let s = Array(Set(matches.map { $0.season })).sorted().reversed()
                    self?.seasons = Array(s)
                    if self?.selectedSeason.isEmpty == true {
                        self?.selectedSeason = self?.seasons.first ?? ""
                    }
                    self?.computeStats(from: matches)
                }
            }
    }

    func computeStats(from matches: [Match]) {
        let filtered = selectedSeason.isEmpty ? matches : matches.filter { $0.season == selectedSeason }
        var statsMap: [String: PlayerStat] = [:]
        for match in filtered {
            for perf in match.playerPerformances where perf.played {
                var stat = statsMap[perf.playerId] ?? PlayerStat(
                    id: perf.playerId, name: perf.playerName,
                    appearances: 0, tries: 0, conversions: 0, penalties: 0, dropGoals: 0
                )
                stat.appearances += 1
                stat.tries       += perf.tries
                stat.conversions += perf.conversions
                stat.penalties   += perf.penalties
                stat.dropGoals   += perf.dropGoals
                statsMap[perf.playerId] = stat
            }
        }
        playerStats = statsMap.values.sorted { $0.appearances > $1.appearances }
    }

    var topAppearances: [PlayerStat] { playerStats.sorted { $0.appearances > $1.appearances } }
    var topTryScorers:  [PlayerStat] { playerStats.filter { $0.tries > 0 }.sorted { $0.tries > $1.tries } }
    var topPointScorers:[PlayerStat] { playerStats.filter { $0.points > 0 }.sorted { $0.points > $1.points } }
}
