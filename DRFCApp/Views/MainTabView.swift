import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var matchVM = MatchViewModel()
    @StateObject private var fixtureVM = FixtureViewModel()
    @StateObject private var statsVM = StatsViewModel()

    var body: some View {
        TabView {
            FixturesView()
                .tabItem { Label("Fixtures", systemImage: "calendar") }

            ResultsView()
                .tabItem { Label("Results", systemImage: "sportscourt") }

            StatsTabView()
                .tabItem { Label("Stats", systemImage: "chart.bar.fill") }

            if authVM.currentUser?.role == .admin {
                AdminDashboardView()
                    .tabItem { Label("Admin", systemImage: "shield.fill") }
            }

            ProfileView()
                .tabItem { Label("Me", systemImage: "person.fill") }
        }
        .accentColor(DRFCTheme.lightBlue)
        .environmentObject(matchVM)
        .environmentObject(fixtureVM)
        .environmentObject(statsVM)
    }
}
