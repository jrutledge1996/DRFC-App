import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore

class AuthViewModel: ObservableObject {
    @Published var currentUser: AppUser?
    @Published var isLoggedIn = false
    @Published var errorMessage: String?

    private let db = Firestore.firestore()
    private var handle: AuthStateDidChangeListenerHandle?

    init() {
        handle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            if let user = user {
                self?.fetchUserProfile(uid: user.uid)
            } else {
                self?.currentUser = nil
                self?.isLoggedIn = false
            }
        }
    }

    deinit {
        if let handle { Auth.auth().removeStateDidChangeListener(handle) }
    }

    func fetchUserProfile(uid: String) {
        db.collection("users").document(uid).getDocument { [weak self] snapshot, error in
            if let data = try? snapshot?.data(as: AppUser.self) {
                DispatchQueue.main.async {
                    self?.currentUser = data
                    self?.isLoggedIn = true
                }
            }
        }
    }

    func login(email: String, password: String) {
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] _, error in
            if let error {
                DispatchQueue.main.async { self?.errorMessage = error.localizedDescription }
            }
        }
    }

    func register(email: String, password: String, displayName: String, role: UserRole = .fan) {
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            if let error {
                DispatchQueue.main.async { self?.errorMessage = error.localizedDescription }
                return
            }
            guard let uid = result?.user.uid else { return }
            let newUser = AppUser(id: uid, email: email, displayName: displayName, role: role, playerId: nil)
            try? self?.db.collection("users").document(uid).setData(from: newUser)
        }
    }

    func signOut() {
        try? Auth.auth().signOut()
    }
}
