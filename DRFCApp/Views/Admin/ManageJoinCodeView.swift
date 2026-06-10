import SwiftUI
import Combine
import FirebaseFirestore

class JoinCodeViewModel: ObservableObject {
    @Published var currentCode: String = ""
    @Published var isLoading = true
    @Published var saveError: String?
    @Published var didSave = false

    private let db = Firestore.firestore()
    private let docPath = "config/joinCode"
    private var listener: ListenerRegistration?

    init() { subscribe() }
    deinit { listener?.remove() }

    /// Live listener so the displayed code always reflects what's actually
    /// stored in Firestore — and so a successful save is confirmed on screen.
    func subscribe() {
        listener = db.document(docPath).addSnapshotListener { [weak self] snap, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let error = error {
                    self?.saveError = "Couldn't load join code: \(error.localizedDescription)"
                    return
                }
                self?.currentCode = snap?.data()?["code"] as? String ?? ""
            }
        }
    }

    func save(code: String) {
        let trimmed = code.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        saveError = nil
        didSave = false
        db.document(docPath).setData(["code": trimmed]) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    // Most commonly a permissions error — see Firestore rules in README.
                    self?.saveError = "Save failed: \(error.localizedDescription)"
                } else {
                    self?.didSave = true   // currentCode updates via the listener
                }
            }
        }
    }

    func verify(code: String, completion: @escaping (Bool) -> Void) {
        let trimmed = code.trimmingCharacters(in: .whitespacesAndNewlines)
        db.document(docPath).getDocument { snap, _ in
            let stored = (snap?.data()?["code"] as? String ?? "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            completion(!stored.isEmpty && stored.lowercased() == trimmed.lowercased())
        }
    }
}

struct ManageJoinCodeView: View {
    @StateObject private var vm = JoinCodeViewModel()
    @State private var newCode = ""

    private let rowBackground = Color(red: 0.10, green: 0.13, blue: 0.25)

    var body: some View {
        Form {
            Section {
                if vm.isLoading {
                    ProgressView().tint(.white)
                } else {
                    Text(vm.currentCode.isEmpty ? "No code set" : vm.currentCode)
                        .font(.title2).fontWeight(.bold)
                        .foregroundColor(.white)
                }
            } header: {
                Text("Current Join Code").foregroundColor(.white.opacity(0.7))
            }
            .listRowBackground(rowBackground)

            Section {
                TextField("", text: $newCode, prompt: Text("New join code").foregroundColor(.white.opacity(0.4)))
                    .foregroundColor(.white)
                    .tint(.white)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                Button("Save Code") {
                    guard !newCode.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                    vm.save(code: newCode)
                    newCode = ""
                }
                .foregroundColor(.white).fontWeight(.bold)

                if vm.didSave {
                    Label("Saved", systemImage: "checkmark.circle.fill")
                        .font(.caption).foregroundColor(.green)
                }
                if let err = vm.saveError {
                    Text(err).font(.caption).foregroundColor(.red)
                }
            } header: {
                Text("Update Code").foregroundColor(.white.opacity(0.7))
            }
            .listRowBackground(rowBackground)

            Section {
                Text("New users must enter this code when registering. Share it only with people you want to join the app.")
                    .font(.caption).foregroundColor(.white.opacity(0.7))
            }
            .listRowBackground(rowBackground)
        }
        .scrollContentBackground(.hidden)
        .background(Color(red: 0.07, green: 0.09, blue: 0.18).ignoresSafeArea())
        .navigationTitle("Join Code")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}
