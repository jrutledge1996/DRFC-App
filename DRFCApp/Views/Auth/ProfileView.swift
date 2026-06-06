import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authVM: AuthViewModel

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.07, green: 0.09, blue: 0.18).ignoresSafeArea()

                List {
                    Section {
                        HStack(spacing: 16) {
                            Image(systemName: "person.circle.fill")
                                .resizable().frame(width: 52, height: 52)
                                .foregroundColor(DRFCTheme.lightBlue)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(authVM.currentUser?.displayName ?? "—")
                                    .font(.headline).foregroundColor(.white)
                                Text(authVM.currentUser?.email ?? "—")
                                    .font(.caption).foregroundColor(.white.opacity(0.6))
                            }
                        }
                        .padding(.vertical, 6)
                        .listRowBackground(Color(red: 0.10, green: 0.13, blue: 0.25))
                    }

                    Section("Access Level") {
                        HStack {
                            Text("Role").foregroundColor(.white)
                            Spacer()
                            Text((authVM.currentUser?.role.rawValue ?? "fan").capitalized)
                                .foregroundColor(DRFCTheme.lightBlue).fontWeight(.semibold)
                        }
                        .listRowBackground(Color(red: 0.10, green: 0.13, blue: 0.25))
                    }

                    Section {
                        Button("Sign Out", role: .destructive) { authVM.signOut() }
                            .listRowBackground(Color(red: 0.10, green: 0.13, blue: 0.25))
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Profile")
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}
