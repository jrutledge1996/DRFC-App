import SwiftUI

struct AdminDashboardView: View {
    @StateObject private var playerVM = PlayerViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.07, green: 0.09, blue: 0.18).ignoresSafeArea()

                VStack(spacing: 0) {
                    DRFCHeader(title: "Admin", subtitle: "DRFC Management")

                    List {
                        Section("Matches") {
                            NavigationLink(destination: AddMatchView().environmentObject(playerVM)) {
                                Label("Record Match Result", systemImage: "plus.circle.fill")
                                    .foregroundColor(.white)
                            }
                            .listRowBackground(Color(red: 0.10, green: 0.13, blue: 0.25))
                        }

                        Section("Fixtures") {
                            NavigationLink(destination: AddFixtureView()) {
                                Label("Add Fixture", systemImage: "calendar.badge.plus")
                                    .foregroundColor(.white)
                            }
                            .listRowBackground(Color(red: 0.10, green: 0.13, blue: 0.25))
                        }

                        Section("Squad") {
                            NavigationLink(destination: ManagePlayersView().environmentObject(playerVM)) {
                                Label("Manage Players", systemImage: "person.2.fill")
                                    .foregroundColor(.white)
                            }
                            .listRowBackground(Color(red: 0.10, green: 0.13, blue: 0.25))
                        }

                        Section("Users") {
                            NavigationLink(destination: ManageUsersView()) {
                                Label("Manage User Roles", systemImage: "person.badge.key.fill")
                                    .foregroundColor(.white)
                            }
                            .listRowBackground(Color(red: 0.10, green: 0.13, blue: 0.25))

                            NavigationLink(destination: ManageJoinCodeView()) {
                                Label("Set Join Code", systemImage: "lock.shield.fill")
                                    .foregroundColor(.white)
                            }
                            .listRowBackground(Color(red: 0.10, green: 0.13, blue: 0.25))
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .listStyle(.insetGrouped)
                }
            }
            .navigationBarHidden(true)
        }
    }
}
