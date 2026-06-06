import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore

class AuthViewModel: ObservableObject {
    @Published var currentUser: AppUser?
    @Published var isLoggedIn = false
    @Published var isLoading = true   // true until Firebase resolves auth state
    @Published var errorMessage: String?

    private let db = Firestore.firestore()
    private var handle: AuthStateDidChangeListenerHandle?

    init() {
        handle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            if let user = user {
                self?.fetchUserProfile(uid: user.uid)
            } else {
                DispatchQueue.main.async {
                    self?.currentUser = nil
                    self?.isLoggedIn = false
                    self?.isLoading = false   // auth resolved — not logged in
                }
            }
        }
    }

    deinit {
        if let handle { Auth.auth().removeStateDidChangeListener(handle) }
    }

    func fetchUserProfile(uid: String) {
        db.collection("users").document(uid).getDocument { [weak self] snapshot, _ in
            DispatchQueue.main.async {
                if let data = try? snapshot?.data(as: AppUser.self) {
                    self?.currentUser = data
                    self?.isLoggedIn = true
                } else {
                    // User exists in Auth but not Firestore yet — still logged in
                    self?.isLoggedIn = true
                }
                self?.isLoading = false   // auth resolved
            }
        }
    }

    func login(email: String, password: String) {
        errorMessage = nil
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] _, error in
            if let error {
                DispatchQueue.main.async { self?.errorMessage = error.localizedDescription }
            }
        }
    }

    func register(email: String, password: String, displayName: String, role: UserRole = .fan) {
        errorMessage = nil
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
