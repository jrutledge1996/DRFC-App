import SwiftUI

struct AddFixtureView: View {
    @EnvironmentObject var fixtureVM: FixtureViewModel
    @Environment(\.dismiss) var dismiss

    @State private var opponent = ""
    @State private var date = Date()
    @State private var isHome = true
    @State private var venue = ""
    @State private var competition = ""
    @State private var season = ""

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
            Section("Season") {
                TextField("Season (e.g. 2025/26)", text: $season)
            }
            Section {
                Button("Save Fixture") {
                    guard !opponent.isEmpty, !season.isEmpty else { return }
                    let fixture = Fixture(
                        opponent: opponent, date: date, isHome: isHome,
                        venue: venue, competition: competition, season: season, resultId: nil
                    )
                    fixtureVM.addFixture(fixture)
                    dismiss()
                }
                .foregroundColor(DRFCTheme.navy)
                .fontWeight(.bold)
            }
        }
        .navigationTitle("Add Fixture")
        .navigationBarTitleDisplayMode(.inline)
    }
}
