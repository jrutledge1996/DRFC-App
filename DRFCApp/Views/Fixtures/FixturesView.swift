import SwiftUI

struct FixturesView: View {
    @EnvironmentObject var fixtureVM: FixtureViewModel
    @EnvironmentObject var authVM: AuthViewModel
    @State private var editFixture: Fixture? = nil
    @State private var showPrevious = false

    let teamOptions = ["All Teams"] + Team.allCases.map { $0.rawValue }

    var displayedFixtures: [Fixture] {
        showPrevious ? fixtureVM.previous : fixtureVM.upcoming
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.07, green: 0.09, blue: 0.18).ignoresSafeArea()

                VStack(spacing: 0) {
                    DRFCHeader(title: "Fixtures", subtitle: fixtureVM.selectedSeason)

                    // Season picker
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(fixtureVM.seasons, id: \.self) { s in
                                Button(s) { fixtureVM.selectedSeason = s }
                                    .padding(.horizontal, 12).padding(.vertical, 6)
                                    .background(fixtureVM.selectedSeason == s ? Color.white : Color.white.opacity(0.15))
                                    .foregroundColor(fixtureVM.selectedSeason == s ? DRFCTheme.navy : .white)
                                    .cornerRadius(16).font(.caption).fontWeight(.semibold)
                            }
                        }
                        .padding(.horizontal).padding(.vertical, 8)
                    }

                    // Team picker
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(teamOptions, id: \.self) { t in
                                Button(t) { fixtureVM.selectedTeam = t }
                                    .padding(.horizontal, 12).padding(.vertical, 6)
                                    .background(fixtureVM.selectedTeam == t ? DRFCTheme.lightBlue : Color.white.opacity(0.10))
                                    .foregroundColor(.white)
                                    .cornerRadius(16).font(.caption).fontWeight(.semibold)
                            }
                        }
                        .padding(.horizontal).padding(.bottom, 8)
                    }

                    // Upcoming / Previous toggle
                    HStack(spacing: 8) {
                        ForEach([false, true], id: \.self) { previous in
                            Button(previous ? "Previous" : "Upcoming") { showPrevious = previous }
                                .padding(.horizontal, 14).padding(.vertical, 6)
                                .background(showPrevious == previous ? Color.white : Color.white.opacity(0.15))
                                .foregroundColor(showPrevious == previous ? DRFCTheme.navy : .white)
                                .cornerRadius(16).font(.caption).fontWeight(.semibold)
                        }
                        Spacer()
                    }
                    .padding(.horizontal).padding(.bottom, 8)

                    if displayedFixtures.isEmpty {
                        Spacer()
                        VStack(spacing: 8) {
                            Image(systemName: "calendar.badge.exclamationmark")
                                .font(.system(size: 44)).foregroundColor(DRFCTheme.lightBlue)
                            Text(showPrevious ? "No previous fixtures" : "No upcoming fixtures")
                                .foregroundColor(.white.opacity(0.6))
                        }
                        Spacer()
                    } else {
                        List(displayedFixtures) { fixture in
                            FixtureRow(fixture: fixture)
                                .listRowBackground(Color(red: 0.10, green: 0.13, blue: 0.25))
                                .swipeActions(edge: .trailing) {
                                    if authVM.currentUser?.role == .admin {
                                        Button { editFixture = fixture } label: {
                                            Label("Edit", systemImage: "pencil")
                                        }.tint(.orange)
                                        Button(role: .destructive) {
                                            fixtureVM.deleteFixture(fixture)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                }
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(item: $editFixture) { fixture in
                NavigationStack {
                    AddFixtureView(existingFixture: fixture)
                        .environmentObject(fixtureVM)
                }
            }
        }
    }
}

struct FixtureRow: View {
    let fixture: Fixture

    var body: some View {
        HStack(spacing: 12) {
            VStack(spacing: 4) {
                Text(fixture.isHome ? "H" : "A")
                    .font(.caption).fontWeight(.bold).foregroundColor(.white)
                    .frame(width: 28, height: 28)
                    .background(fixture.isHome ? DRFCTheme.navy : DRFCTheme.lightBlue)
                    .clipShape(Circle())
                Text(fixture.team).font(.caption2).foregroundColor(.white.opacity(0.5))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(fixture.opponent).font(.headline).foregroundColor(.white)
                Text(fixture.competition).font(.caption).foregroundColor(.white.opacity(0.6))
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(fixture.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption).fontWeight(.medium).foregroundColor(.white)
                Text(fixture.venue).font(.caption2).foregroundColor(.white.opacity(0.6))
            }
        }
        .padding(.vertical, 6)
    }
}
