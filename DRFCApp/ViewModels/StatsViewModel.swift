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
    var kicksAttempted: Int
    var kicksMade: Int

    var points: Int { (tries * 5) + (conversions * 2) + (penalties * 3) + (dropGoals * 3) }

    var kickingPercentage: Double? {
        guard kicksAttempted > 0 else { return nil }
        return Double(kicksMade) / Double(kicksAttempted) * 100
    }
}

struct PlayerBackfill {
    var name: String
    var appearancesByTeam: [String: Int]  // team -> count
}

class StatsViewModel: ObservableObject {
    @Published var playerStats: [PlayerStat] = []
    @Published var selectedSeason: String = "All Time"
    @Published var selectedTeam: String = "All Teams"
    @Published var seasons: [String] = ["All Time"]

    private var allMatches: [Match] = []
    private var backfillMap: [String: PlayerBackfill] = [:] // playerId -> backfill
    private let db = Firestore.firestore()
    private var matchListener: ListenerRegistration?
    private var playerListener: ListenerRegistration?

    init() { subscribe() }

    deinit {
        matchListener?.remove()
        playerListener?.remove()
    }

    func subscribe() {
        matchListener = db.collection("matches")
            .addSnapshotListener { [weak self] snapshot, _ in
                guard let docs = snapshot?.documents else { return }
                let matches = docs.compactMap { try? $0.data(as: Match.self) }
                DispatchQueue.main.async {
                    self?.allMatches = matches
                    let s = Array(Set(matches.map { $0.season })).sorted().reversed()
                    self?.seasons = ["All Time"] + Array(s)
                    self?.recompute()
                }
            }

        playerListener = db.collection("players")
            .addSnapshotListener { [weak self] snapshot, _ in
                guard let docs = snapshot?.documents else { return }
                var map: [String: PlayerBackfill] = [:]
                for doc in docs {
                    let data = doc.data()
                    let name = data["name"] as? String ?? ""
                    var byTeam = data["backfilledAppearancesByTeam"] as? [String: Int] ?? [:]
                    // Fall back to legacy single-team backfill fields if the new map is absent.
                    if byTeam.isEmpty, let legacy = data["backfilledAppearances"] as? Int, legacy > 0 {
                        let team = data["backfilledTeam"] as? String ?? Team.firsts.rawValue
                        byTeam = [team: legacy]
                    }
                    if !byTeam.isEmpty && !name.isEmpty {
                        map[doc.documentID] = PlayerBackfill(name: name, appearancesByTeam: byTeam)
                    }
                }
                DispatchQueue.main.async {
                    self?.backfillMap = map
                    self?.recompute()
                }
            }
    }

    func recompute() {
        var filtered = allMatches.filter { !$0.isFriendly }
        if selectedSeason != "All Time" {
            filtered = filtered.filter { $0.season == selectedSeason }
        }
        if selectedTeam != "All Teams" {
            filtered = filtered.filter { $0.team == selectedTeam }
        }
        computeStats(from: filtered)
    }

    func computeStats(from matches: [Match]) {
        var statsMap: [String: PlayerStat] = [:]

        // Seed backfilled appearances for All Time view
        if selectedSeason == "All Time" {
            for (playerId, backfill) in backfillMap {
                let apps: Int
                if selectedTeam == "All Teams" {
                    apps = backfill.appearancesByTeam.values.reduce(0, +)
                } else {
                    apps = backfill.appearancesByTeam[selectedTeam] ?? 0
                }
                if apps > 0 {
                    statsMap[playerId] = PlayerStat(
                        id: playerId, name: backfill.name,
                        appearances: apps,
                        tries: 0, conversions: 0, penalties: 0, dropGoals: 0,
                        kicksAttempted: 0, kicksMade: 0
                    )
                }
            }
        }

        for match in matches {
            for perf in match.playerPerformances where perf.played {
                var stat = statsMap[perf.playerId] ?? PlayerStat(
                    id: perf.playerId, name: perf.playerName,
                    appearances: 0, tries: 0, conversions: 0, penalties: 0, dropGoals: 0,
                    kicksAttempted: 0, kicksMade: 0
                )
                if stat.name.isEmpty { stat.name = perf.playerName }
                stat.appearances    += 1
                stat.tries          += perf.tries
                stat.conversions    += perf.conversions
                stat.penalties      += perf.penalties
                stat.dropGoals      += perf.dropGoals
                stat.kicksAttempted += perf.kicksAttempted
                stat.kicksMade      += perf.kicksMade
                statsMap[perf.playerId] = stat
            }
        }

        playerStats = statsMap.values.filter { !$0.name.isEmpty }
            .sorted { $0.appearances > $1.appearances }
    }

    var topAppearances:  [PlayerStat] { playerStats.sorted { $0.appearances > $1.appearances } }
    var topTryScorers:   [PlayerStat] { playerStats.filter { $0.tries > 0 }.sorted { $0.tries > $1.tries } }
    var topPointScorers: [PlayerStat] { playerStats.filter { $0.points > 0 }.sorted { $0.points > $1.points } }
    var topKickers:      [PlayerStat] { playerStats.filter { $0.kicksAttempted > 0 }.sorted { ($0.kickingPercentage ?? 0) > ($1.kickingPercentage ?? 0) } }
}
