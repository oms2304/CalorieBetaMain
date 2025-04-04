import SwiftUI
<<<<<<< HEAD
import FirebaseAuth

struct SettingsView: View {
    @EnvironmentObject var goalSettings: GoalSettings
    @EnvironmentObject var appState: AppState
    @Environment(\.presentationMode) var presentationMode // Added for dismissal
=======
import FirebaseFirestore

struct SettingsView: View {
    @EnvironmentObject var goalSettings: GoalSettings
>>>>>>> d3d7eb3 (Initial commit)

    var body: some View {
        NavigationView {
            List {
<<<<<<< HEAD
                NavigationLink(destination: CaloricCalculatorView()) {
                    Text("Calculate Caloric Intake")
                }

                NavigationLink(destination: CurrentWeightView().environmentObject(goalSettings)) {
                    Text("Set Current Weight (lbs)")
                }

                NavigationLink(destination: SetHeightView().environmentObject(goalSettings)) {
                    Text("Set Height (cm)")
                }

                Section {
                    Button("Log Out") {
                        logOutUser()
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Settings")
            .navigationBarBackButtonHidden(true) // Hide the default back button
            .navigationBarItems(leading: // Custom back button
                Button(action: {
                    // Pop back to HomeView using SwiftUI presentation mode
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "chevron.left")
                    Text("Home")
                }
                .foregroundColor(.blue)
            )
        }
    }

    private func logOutUser() {
        do {
            try Auth.auth().signOut()
            appState.setUserLoggedIn(false) // Update the app state to indicate user is logged out
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
    }
}
=======
                NavigationLink(destination: DailyGoalsView()) {
                    Text("Set Daily Goals")
                }

                // Pass goalSettings to CurrentWeightView
                NavigationLink(destination: CurrentWeightView(goalSettings: goalSettings)) {
                    Text("Set Current Weight (lbs)")
                }

                NavigationLink(destination: Text("Future Settings Placeholder")) {
                    Text("Another Setting Option")
                }
            }
            .navigationTitle("Settings")
        }
    }
}

>>>>>>> d3d7eb3 (Initial commit)
