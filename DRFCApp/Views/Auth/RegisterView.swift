import SwiftUI

struct RegisterView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @Environment(\.dismiss) var dismiss

    @State private var displayName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var localError: String?

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

                if let err = localError ?? authVM.errorMessage {
                    Section {
                        Text(err).foregroundColor(.red).font(.caption)
                    }
                }

                Section {
                    Button("Create Account") {
                        guard password == confirmPassword else {
                            localError = "Passwords do not match."
                            return
                        }
                        authVM.register(email: email, password: password, displayName: displayName, role: .fan)
                    }
                    .foregroundColor(DRFCTheme.navy)
                    .fontWeight(.bold)
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
