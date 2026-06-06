import SwiftUI
import Combine
import FirebaseFirestore

class UserViewModel: ObservableObject {
    @Published var users: [AppUser] = []
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?

    init() { subscribe() }
    deinit { listener?.remove() }

    func subscribe() {
        listener = db.collection("users")
            .addSnapshotListener { [weak self] snapshot, _ in
                guard let docs = snapshot?.documents else { return }
                DispatchQueue.main.async {
                    self?.users = docs.compactMap { try? $0.data(as: AppUser.self) }
                        .sorted { $0.displayName < $1.displayName }
                }
            }
    }

    func updateRole(for user: AppUser, role: UserRole) {
        guard let id = user.id else { return }
        db.collection("users").document(id).updateData(["role": role.rawValue])
    }
}

struct ManageUsersView: View {
    @StateObject private var userVM = UserViewModel()

    var body: some View {
        List {
            ForEach(userVM.users) { user in
                UserRoleRow(user: user) { newRole in
                    userVM.updateRole(for: user, role: newRole)
                }
                .listRowBackground(Color(red: 0.10, green: 0.13, blue: 0.25))
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color(red: 0.07, green: 0.09, blue: 0.18))
        .navigationTitle("Manage Users")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

struct UserRoleRow: View {
    let user: AppUser
    let onRoleChange: (UserRole) -> Void

    var roleColour: Color {
        switch user.role {
        case .admin:  return .red
        case .player: return DRFCTheme.lightBlue
        case .fan:    return .gray
        }
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(user.displayName)
                    .font(.headline).foregroundColor(.white)
                Text(user.email)
                    .font(.caption).foregroundColor(.white.opacity(0.6))
            }

            Spacer()

            Menu {
                ForEach([UserRole.fan, .player, .admin], id: \.rawValue) { role in
                    Button {
                        onRoleChange(role)
                    } label: {
                        HStack {
                            Text(role.rawValue.capitalized)
                            if user.role == role {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                Text(user.role.rawValue.capitalized)
                    .font(.caption).fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(roleColour)
                    .cornerRadius(8)
            }
        }
        .padding(.vertical, 4)
    }
}
