import SwiftUI
import FirebaseCore
import FirebaseFirestore
import FirebaseAuth

@main
struct DRFCApp: App {
    @StateObject private var authVM = AuthViewModel()

    init() {
        FirebaseApp.configure()

        // Offline persistence — all Firestore data cached on device
        let settings = FirestoreSettings()
        settings.cacheSettings = PersistentCacheSettings()
        Firestore.firestore().settings = settings
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if authVM.isLoading {
                    // Hold on splash while Firebase restores auth session
                    SplashView()
                } else if authVM.isLoggedIn {
                    MainTabView()
                        .environmentObject(authVM)
                } else {
                    LoginView()
                        .environmentObject(authVM)
                }
            }
        }
    }
}

// MARK: - Splash screen shown while auth state resolves

struct SplashView: View {
    var body: some View {
        ZStack {
            DRFCTheme.navy.ignoresSafeArea()
            VStack(spacing: 12) {
                Image(systemName: "shield.fill")
                    .resizable().scaledToFit()
                    .frame(width: 72, height: 72)
                    .foregroundColor(DRFCTheme.lightBlue)
                Text("DRFC")
                    .font(.largeTitle).fontWeight(.black)
                    .foregroundColor(.white).tracking(6)
                ProgressView().tint(.white).padding(.top, 8)
            }
        }
    }
}
