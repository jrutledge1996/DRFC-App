import SwiftUI

struct FixturesView: View {
    @EnvironmentObject var fixtureVM: FixtureViewModel

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                DRFCHeader(title: "Fixtures", subtitle: fixtureVM.selectedSeason)

                if fixtureVM.seasons.count > 1 {
                    Picker("Season", selection: $fixtureVM.selectedSeason) {
                        ForEach(fixtureVM.seasons, id: \.self) { Text($0).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }

                if fixtureVM.upcoming.isEmpty {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "calendar.badge.exclamationmark")
                            .font(.system(size: 44))
                            .foregroundColor(DRFCTheme.lightBlue)
                        Text("No upcoming fixtures")
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                } else {
                    List(fixtureVM.upcoming) { fixture in
                        FixtureRow(fixture: fixture)
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    }
                    .listStyle(.plain)
                }
            }
            .navigationBarHidden(true)
        }
    }
}

struct FixtureRow: View {
    let fixture: Fixture

    private var dateString: String {
        fixture.date.formatted(date: .abbreviated, time: .shortened)
    }

    var body: some View {
        HStack(spacing: 12) {
            // Home/Away indicator
            VStack(spacing: 4) {
                Text(fixture.isHome ? "H" : "A")
                    .font(.caption).fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(width: 28, height: 28)
                    .background(fixture.isHome ? DRFCTheme.navy : DRFCTheme.lightBlue)
                    .clipShape(Circle())
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(fixture.opponent)
                    .font(.headline)
                    .foregroundColor(DRFCTheme.navy)
                Text(fixture.competition)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(dateString)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(DRFCTheme.navy)
                Text(fixture.venue)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 6)
    }
}
