import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var showRegister = false

    var body: some View {
        NavigationStack {
            ZStack {
                DRFCTheme.navy.ignoresSafeArea()

                VStack(spacing: 28) {
                    // Crest area
                    VStack(spacing: 8) {
                        Image(systemName: "shield.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 72, height: 72)
                            .foregroundColor(DRFCTheme.lightBlue)
                        Text("DRFC")
                            .font(.largeTitle).fontWeight(.black)
                            .foregroundColor(.white)
                            .tracking(6)
                    }
                    .padding(.top, 48)

                    // Form card
                    VStack(spacing: 16) {
                        TextField("Email", text: $email)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)

                        SecureField("Password", text: $password)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)

                        if let err = authVM.errorMessage {
                            Text(err)
                                .font(.caption)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                        }

                        Button {
                            authVM.login(email: email, password: password)
                        } label: {
                            Text("Sign In")
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(DRFCTheme.lightBlue)
                                .cornerRadius(10)
                        }

                        Button("Don't have an account? Register") {
                            showRegister = true
                        }
                        .font(.footnote)
                        .foregroundColor(DRFCTheme.lightBlue.opacity(0.85))
                    }
                    .padding(24)
                    .background(Color(.systemBackground))
                    .cornerRadius(20)
                    .padding(.horizontal, 24)

                    Spacer()
                }
            }
            .sheet(isPresented: $showRegister) {
                RegisterView()
                    .environmentObject(authVM)
            }
        }
    }
}
