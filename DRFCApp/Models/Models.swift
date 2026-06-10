import Foundation
import FirebaseFirestore

// MARK: - User Role

enum UserRole: String, Codable {
    case admin = "admin"
    case player = "player"
    case fan = "fan"
}

// MARK: - Team

enum Team: String, Codable, CaseIterable, Identifiable {
    case firsts  = "1sts"
    case seconds = "2nds"
    case thirds  = "3rds"
    case youth   = "Youth"

    var id: String { rawValue }
}

// MARK: - AppUser

struct AppUser: Identifiable, Codable {
    @DocumentID var id: String?
    var email: String
    var displayName: String
    var role: UserRole
    var playerId: String?

    enum CodingKeys: String, CodingKey {
        case id, email, displayName, role, playerId
    }
}

// MARK: - AppUser resilient decoding

extension AppUser {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        _id = try c.decode(DocumentID<String>.self, forKey: .id)
        email = try c.decodeIfPresent(String.self, forKey: .email) ?? ""
        displayName = try c.decodeIfPresent(String.self, forKey: .displayName) ?? ""
        role = try c.decodeIfPresent(UserRole.self, forKey: .role) ?? .fan
        playerId = try c.decodeIfPresent(String.self, forKey: .playerId)
    }
}

// MARK: - Player

struct Player: Identifiable, Codable {
    @DocumentID var id: String?
    var name: String
    var position: String
    var number: Int?
    var isActive: Bool
    var isRegistered: Bool = false
    var nickname: String? = nil
    var yearOfBirth: Int? = nil

    var displayName: String { nickname?.isEmpty == false ? nickname! : name }

    // Pre-app backfilled appearances per team — e.g. ["1sts": 30, "2nds": 10]
    var backfilledAppearancesByTeam: [String: Int] = [:]

    /// Total backfilled appearances across all teams
    var totalBackfilledAppearances: Int { backfilledAppearancesByTeam.values.reduce(0, +) }

    /// Readable per-team breakdown, e.g. "1sts: 30, 2nds: 10" (team order follows Team enum)
    var backfilledSummary: String {
        Team.allCases
            .compactMap { team -> String? in
                guard let count = backfilledAppearancesByTeam[team.rawValue], count > 0 else { return nil }
                return "\(team.rawValue): \(count)"
            }
            .joined(separator: ", ")
    }

    enum CodingKeys: String, CodingKey {
        case id, name, position, number, isActive, isRegistered, nickname
        case backfilledAppearancesByTeam, yearOfBirth
    }
}

// MARK: - Player resilient decoding
//
// Older player documents in Firestore may be missing fields that were added
// later (e.g. `backfilledAppearancesByTeam`, `yearOfBirth`), or may still use
// the legacy single-team fields `backfilledAppearances` / `backfilledTeam`.
// Swift's auto-generated decoding throws on any missing non-optional field,
// which previously made those whole records silently fail to load. This
// initializer decodes every field tolerantly so existing players keep showing
// up, and migrates the old backfill fields into the new per-team map.
extension Player {
    private enum LegacyKeys: String, CodingKey {
        case backfilledAppearances, backfilledTeam
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        _id = try c.decode(DocumentID<String>.self, forKey: .id)
        name = try c.decodeIfPresent(String.self, forKey: .name) ?? ""
        position = try c.decodeIfPresent(String.self, forKey: .position) ?? ""
        number = try c.decodeIfPresent(Int.self, forKey: .number)
        isActive = try c.decodeIfPresent(Bool.self, forKey: .isActive) ?? true
        isRegistered = try c.decodeIfPresent(Bool.self, forKey: .isRegistered) ?? false
        nickname = try c.decodeIfPresent(String.self, forKey: .nickname)
        yearOfBirth = try c.decodeIfPresent(Int.self, forKey: .yearOfBirth)

        // New per-team map, or migrate from the legacy single-team fields.
        var byTeam = try c.decodeIfPresent([String: Int].self, forKey: .backfilledAppearancesByTeam) ?? [:]
        if byTeam.isEmpty {
            let legacy = try decoder.container(keyedBy: LegacyKeys.self)
            if let count = try legacy.decodeIfPresent(Int.self, forKey: .backfilledAppearances), count > 0 {
                let team = (try legacy.decodeIfPresent(String.self, forKey: .backfilledTeam)) ?? Team.firsts.rawValue
                byTeam = [team: count]
            }
        }
        backfilledAppearancesByTeam = byTeam
    }
}

// MARK: - Name disambiguation

extension Array where Element == Player {
    /// Returns the player's display name, appending year of birth in brackets
    /// only when another player in the list shares the same display name.
    /// e.g. two "John Smith"s become "John Smith (1998)" and "John Smith (2003)".
    func disambiguatedName(for player: Player) -> String {
        let sameName = filter { $0.displayName == player.displayName }
        guard sameName.count > 1, let yob = player.yearOfBirth else {
            return player.displayName
        }
        return "\(player.displayName) (\(yob))"
    }
}

// MARK: - Fixture

struct Fixture: Identifiable, Codable {
    @DocumentID var id: String?
    var opponent: String
    var date: Date
    var isHome: Bool
    var venue: String
    var competition: String
    var season: String
    var team: String = Team.firsts.rawValue
    var isFriendly: Bool = false
    var resultId: String?

    var isPlayed: Bool { resultId != nil }

    enum CodingKeys: String, CodingKey {
        case id, opponent, date, isHome, venue, competition, season, team, isFriendly, resultId
    }
}

// MARK: - Fixture resilient decoding

extension Fixture {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        _id = try c.decode(DocumentID<String>.self, forKey: .id)
        opponent = try c.decodeIfPresent(String.self, forKey: .opponent) ?? ""
        date = try c.decodeIfPresent(Date.self, forKey: .date) ?? Date()
        isHome = try c.decodeIfPresent(Bool.self, forKey: .isHome) ?? true
        venue = try c.decodeIfPresent(String.self, forKey: .venue) ?? ""
        competition = try c.decodeIfPresent(String.self, forKey: .competition) ?? ""
        season = try c.decodeIfPresent(String.self, forKey: .season) ?? ""
        team = try c.decodeIfPresent(String.self, forKey: .team) ?? Team.firsts.rawValue
        isFriendly = try c.decodeIfPresent(Bool.self, forKey: .isFriendly) ?? false
        resultId = try c.decodeIfPresent(String.self, forKey: .resultId)
    }
}

// MARK: - Match

struct Match: Identifiable, Codable {
    @DocumentID var id: String?
    var fixtureId: String
    var opponent: String
    var date: Date
    var isHome: Bool
    var venue: String
    var competition: String
    var season: String
    var team: String = Team.firsts.rawValue
    var isFriendly: Bool = false

    var drfcScore: Int
    var opponentScore: Int

    var playerPerformances: [PlayerPerformance]

    var result: MatchResult {
        if drfcScore > opponentScore { return .win }
        if drfcScore < opponentScore { return .loss }
        return .draw
    }

    enum CodingKeys: String, CodingKey {
        case id, fixtureId, opponent, date, isHome, venue, competition, season
        case team, isFriendly, drfcScore, opponentScore, playerPerformances
    }
}

// MARK: - Match resilient decoding

extension Match {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        _id = try c.decode(DocumentID<String>.self, forKey: .id)
        fixtureId = try c.decodeIfPresent(String.self, forKey: .fixtureId) ?? ""
        opponent = try c.decodeIfPresent(String.self, forKey: .opponent) ?? ""
        date = try c.decodeIfPresent(Date.self, forKey: .date) ?? Date()
        isHome = try c.decodeIfPresent(Bool.self, forKey: .isHome) ?? true
        venue = try c.decodeIfPresent(String.self, forKey: .venue) ?? ""
        competition = try c.decodeIfPresent(String.self, forKey: .competition) ?? ""
        season = try c.decodeIfPresent(String.self, forKey: .season) ?? ""
        team = try c.decodeIfPresent(String.self, forKey: .team) ?? Team.firsts.rawValue
        isFriendly = try c.decodeIfPresent(Bool.self, forKey: .isFriendly) ?? false
        drfcScore = try c.decodeIfPresent(Int.self, forKey: .drfcScore) ?? 0
        opponentScore = try c.decodeIfPresent(Int.self, forKey: .opponentScore) ?? 0
        playerPerformances = try c.decodeIfPresent([PlayerPerformance].self, forKey: .playerPerformances) ?? []
    }
}

enum MatchResult: String, Codable {
    case win, loss, draw
}

// MARK: - PlayerPerformance

struct PlayerPerformance: Identifiable, Codable {
    var id: String = UUID().uuidString
    var playerId: String
    var playerName: String
    var played: Bool
    var positionNumber: Int?   // 1-15 for starters, nil for bench
    var isBench: Bool = false
    var tries: Int = 0
    var conversions: Int = 0
    var penalties: Int = 0
    var dropGoals: Int = 0
    var kicksAttempted: Int = 0
    var kicksMade: Int = 0

    var points: Int {
        (tries * 5) + (conversions * 2) + (penalties * 3) + (dropGoals * 3)
    }

    var kickingPercentage: Double? {
        guard kicksAttempted > 0 else { return nil }
        return Double(kicksMade) / Double(kicksAttempted) * 100
    }

    var positionLabel: String {
        if let n = positionNumber { return "\(n)" }
        return "Bench"
    }

    enum CodingKeys: String, CodingKey {
        case id, playerId, playerName, played, positionNumber, isBench
        case tries, conversions, penalties, dropGoals, kicksAttempted, kicksMade
    }
}

// MARK: - PlayerPerformance resilient decoding

extension PlayerPerformance {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
        playerId = try c.decodeIfPresent(String.self, forKey: .playerId) ?? ""
        playerName = try c.decodeIfPresent(String.self, forKey: .playerName) ?? ""
        played = try c.decodeIfPresent(Bool.self, forKey: .played) ?? false
        positionNumber = try c.decodeIfPresent(Int.self, forKey: .positionNumber)
        isBench = try c.decodeIfPresent(Bool.self, forKey: .isBench) ?? false
        tries = try c.decodeIfPresent(Int.self, forKey: .tries) ?? 0
        conversions = try c.decodeIfPresent(Int.self, forKey: .conversions) ?? 0
        penalties = try c.decodeIfPresent(Int.self, forKey: .penalties) ?? 0
        dropGoals = try c.decodeIfPresent(Int.self, forKey: .dropGoals) ?? 0
        kicksAttempted = try c.decodeIfPresent(Int.self, forKey: .kicksAttempted) ?? 0
        kicksMade = try c.decodeIfPresent(Int.self, forKey: .kicksMade) ?? 0
    }
}
