import SwiftUI

struct RegisterView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @Environment(\.dismiss) var dismiss

    @State private var displayName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var joinCode = ""
    @State private var localError: String?
    @State private var isChecking = false

    @StateObject private var codeVM = JoinCodeViewModel()

    var body: some View {
        NavigationStack {
            Form {
                Section("Your Details") {
                    TextField("Full Name", text: $displayName)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                }

                Section("Password") {
                    SecureField("Password", text: $password)
                    SecureField("Confirm Password", text: $confirmPassword)
                }

                Section("Club Access") {
                    TextField("Join Code", text: $joinCode)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                    Text("Enter the code provided by your club admin.")
                        .font(.caption).foregroundColor(.secondary)
                }

                if let err = localError ?? authVM.errorMessage {
                    Section {
                        Text(err).foregroundColor(.red).font(.caption)
                    }
                }

                Section {
                    Button(isChecking ? "Checking..." : "Create Account") {
                        guard !isChecking else { return }
                        guard password == confirmPassword else {
                            localError = "Passwords do not match."
                            return
                        }
                        guard !joinCode.isEmpty else {
                            localError = "Please enter the join code."
                            return
                        }
                        isChecking = true
                        codeVM.verify(code: joinCode) { valid in
                            DispatchQueue.main.async {
                                isChecking = false
                                if valid {
                                    authVM.register(email: email, password: password,
                                                    displayName: displayName, role: .fan)
                                } else {
                                    localError = "Incorrect join code. Please contact your admin."
                                }
                            }
                        }
                    }
                    .foregroundColor(DRFCTheme.adaptiveAccent).fontWeight(.bold)
                    .disabled(isChecking)
                }
            }
            .navigationTitle("Register")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
