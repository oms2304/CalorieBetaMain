import SwiftUI
import FirebaseAuth

// This view provides a settings interface for users to manage their profile data and log out,
// presented as a sheet with navigation links to related views, integrated with Firebase.
struct SettingsView: View {
    // Environment objects to access shared state and services.
    @EnvironmentObject var goalSettings: GoalSettings // Manages user goals and profile data.
    @EnvironmentObject var appState: AppState // Manages the app's authentication state.
    // Binding to control the visibility of the settings sheet.
    @Binding var showSettings: Bool // Allows the parent view to dismiss this sheet.

    // The main body of the view, using a List for a settings menu.
    var body: some View {
        List { // Creates a list-style layout for settings options.
            // Navigation link to calculate caloric intake.
            NavigationLink(destination: CaloricCalculatorView()) {
                Text("Calculate Caloric Intake") // Label for the navigation link.
            }

            // Navigation link to set current weight.
            NavigationLink(destination: CurrentWeightView().environmentObject(goalSettings)) {
                Text("Set Current Weight (lbs)") // Label for the navigation link.
            }

            // Navigation link to set height.
            NavigationLink(destination: SetHeightView().environmentObject(goalSettings)) {
                Text("Set Height (cm)") // Label for the navigation link.
            }

            Section { // Section for logout action.
                Button("Log Out") { // Button to initiate logout.
                    logOutUser() // Calls the logout function.
                }
                .foregroundColor(.red) // Red color to indicate a critical action.
            }
        }
        .navigationTitle("Settings") // Sets the navigation bar title.
        .navigationBarBackButtonHidden(true) // Hides the default back button.
        .navigationBarItems(leading: // Adds a custom "Home" button.
            Button(action: {
                showSettings = false // Dismisses the settings sheet.
            }) {
                Image(systemName: "chevron.left") // Left arrow icon.
                Text("Home") // Label for the button.
            }
            .foregroundColor(.blue) // Blue color for visibility.
        )
    }

    // Logs out the user from Firebase and updates the app state.
    private func logOutUser() {
        do {
            try Auth.auth().signOut() // Attempts to sign out the user from Firebase.
            appState.setUserLoggedIn(false) // Updates the app state to reflect logout.
        } catch { // Handles any errors during sign-out.
            print("Error signing out: \(error.localizedDescription)") // Logs the error for debugging.
        }
    }
}
