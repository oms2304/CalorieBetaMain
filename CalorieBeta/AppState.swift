import SwiftUI
import FirebaseAuth

// This class manages the application's global state, particularly the user's authentication status,
// and notifies views of changes using the ObservableObject protocol.
class AppState: ObservableObject {
    // Published property to track whether a user is logged in, triggering UI updates in SwiftUI.
    @Published var isUserLoggedIn: Bool = false

    // Initializes the AppState and sets up authentication state listening.
    init() {
        // Adds a listener to detect changes in the Firebase Authentication state.
        Auth.auth().addStateDidChangeListener { auth, user in
            // Ensures UI updates occur on the main thread.
            DispatchQueue.main.async {
                if let user = user { // Checks if a user is authenticated.
                    print("✅ Firebase Auth State Changed: User logged in: \(user.uid)") // Logs successful login.
                    self.isUserLoggedIn = true // Updates the state to reflect login.
                } else { // Handles the case where no user is authenticated.
                    print("❌ Firebase Auth State Changed: No user logged in") // Logs logout.
                    self.isUserLoggedIn = false // Updates the state to reflect logout.
                }
            }
        }
    }

    /// Manually sets the login state, useful for testing or manual state changes.
    func setUserLoggedIn(_ loggedIn: Bool) {
        // Ensures the state update occurs on the main thread to avoid UI issues.
        DispatchQueue.main.async {
            self.isUserLoggedIn = loggedIn // Updates the published property.
        }
    }
}
