import SwiftUI

struct AddFixtureView: View {
    @EnvironmentObject var fixtureVM: FixtureViewModel
    @Environment(\.dismiss) var dismiss

    var existingFixture: Fixture? = nil

    @State private var opponent = ""
    @State private var date = Date()
    @State private var isHome = true
    @State private var venue = ""
    @State private var competition = ""
    @State private var season = ""
    @State private var selectedTeam = Team.firsts.rawValue
    @State private var isFriendly = false

    var body: some View {
        Form {
            Section("Opponent") {
                TextField("Opponent name", text: $opponent)
                TextField("Competition", text: $competition)
            }
            Section("Date & Venue") {
                DatePicker("Date & Time", selection: $date)
                TextField("Venue", text: $venue)
                Toggle("Home Game", isOn: $isHome)
            }
            Section("Season & Team") {
                Toggle("Friendly (excluded from stats)", isOn: $isFriendly)
                TextField("Season (e.g. 2025/26)", text: $season)
                Picker("Team", selection: $selectedTeam) {
                    ForEach(Team.allCases) { t in Text(t.rawValue).tag(t.rawValue) }
                }
            }
            Section {
                Button(existingFixture == nil ? "Save Fixture" : "Update Fixture") {
                    guard !opponent.isEmpty, !season.isEmpty else { return }
                    var fixture = Fixture(
                        opponent: opponent, date: date, isHome: isHome,
                        venue: venue, competition: competition,
                        season: season, team: selectedTeam, isFriendly: isFriendly, resultId: nil
                    )
                    if let existing = existingFixture {
                        fixture.id = existing.id
                        fixture.resultId = existing.resultId
                        fixtureVM.updateFixture(fixture)
                    } else {
                        fixtureVM.addFixture(fixture)
                    }
                    dismiss()
                }
                .foregroundColor(DRFCTheme.navy)
                .fontWeight(.bold)
            }
        }
        .navigationTitle(existingFixture == nil ? "Add Fixture" : "Edit Fixture")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if let f = existingFixture {
                opponent = f.opponent; date = f.date; isHome = f.isHome
                venue = f.venue; competition = f.competition
                season = f.season; selectedTeam = f.team; isFriendly = f.isFriendly
            }
        }
    }
}
