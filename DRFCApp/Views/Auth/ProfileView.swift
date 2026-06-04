import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authVM: AuthViewModel

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 16) {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .frame(width: 52, height: 52)
                            .foregroundColor(DRFCTheme.lightBlue)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(authVM.currentUser?.displayName ?? "—")
                                .font(.headline)
                            Text(authVM.currentUser?.email ?? "—")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 6)
                }

                Section("Access Level") {
                    HStack {
                        Text("Role")
                        Spacer()
                        Text((authVM.currentUser?.role.rawValue ?? "fan").capitalized)
                            .foregroundColor(DRFCTheme.navy)
                            .fontWeight(.semibold)
                    }
                }

                Section {
                    Button("Sign Out", role: .destructive) {
                        authVM.signOut()
                    }
                }
            }
            .navigationTitle("Profile")
        }
    }
}
