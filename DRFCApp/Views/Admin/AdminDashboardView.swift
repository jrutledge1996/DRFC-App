import SwiftUI

struct AdminDashboardView: View {
    @StateObject private var playerVM = PlayerViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                DRFCHeader(title: "Admin", subtitle: "DRFC Management")

                List {
                    Section("Matches") {
                        NavigationLink(destination: AddMatchView().environmentObject(playerVM)) {
                            Label("Record Match Result", systemImage: "plus.circle.fill")
                                .foregroundColor(DRFCTheme.navy)
                        }
                    }

                    Section("Fixtures") {
                        NavigationLink(destination: AddFixtureView()) {
                            Label("Add Fixture", systemImage: "calendar.badge.plus")
                                .foregroundColor(DRFCTheme.navy)
                        }
                    }

                    Section("Squad") {
                        NavigationLink(destination: ManagePlayersView().environmentObject(playerVM)) {
                            Label("Manage Players", systemImage: "person.2.fill")
                                .foregroundColor(DRFCTheme.navy)
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
            .navigationBarHidden(true)
        }
    }
}
