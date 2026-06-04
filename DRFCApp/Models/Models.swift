import Foundation
import FirebaseFirestore

// MARK: - User Role

enum UserRole: String, Codable {
    case admin = "admin"
    case player = "player"
    case fan = "fan"
}

// MARK: - AppUser

struct AppUser: Identifiable, Codable {
    @DocumentID var id: String?
    var email: String
    var displayName: String
    var role: UserRole
    var playerId: String? // links admin/player account to a Player record

    enum CodingKeys: String, CodingKey {
        case id, email, displayName, role, playerId
    }
}

// MARK: - Player

struct Player: Identifiable, Codable {
    @DocumentID var id: String?
    var name: String
    var position: String
    var number: Int?
    var isActive: Bool

    // Computed stats (derived from matches, not stored directly)
    var appearances: Int = 0
    var tries: Int = 0
    var conversions: Int = 0
    var penalties: Int = 0
    var dropGoals: Int = 0

    var points: Int {
        (tries * 5) + (conversions * 2) + (penalties * 3) + (dropGoals * 3)
    }

    enum CodingKeys: String, CodingKey {
        case id, name, position, number, isActive,
             appearances, tries, conversions, penalties, dropGoals
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
    var resultId: String? // populated once match is played

    var isPlayed: Bool { resultId != nil }
}

// MARK: - Match (played result)

struct Match: Identifiable, Codable {
    @DocumentID var id: String?
    var fixtureId: String
    var opponent: String
    var date: Date
    var isHome: Bool
    var venue: String
    var competition: String
    var season: String

    var drfcScore: Int
    var opponentScore: Int

    var playerPerformances: [PlayerPerformance]

    var result: MatchResult {
        if drfcScore > opponentScore { return .win }
        if drfcScore < opponentScore { return .loss }
        return .draw
    }
}

enum MatchResult: String, Codable {
    case win, loss, draw
}

// MARK: - PlayerPerformance (who played / scored in a match)

struct PlayerPerformance: Identifiable, Codable {
    var id: String = UUID().uuidString
    var playerId: String
    var playerName: String
    var played: Bool
    var tries: Int
    var conversions: Int
    var penalties: Int
    var dropGoals: Int

    var points: Int {
        (tries * 5) + (conversions * 2) + (penalties * 3) + (dropGoals * 3)
    }
}
