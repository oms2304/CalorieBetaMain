import SwiftUI
import Firebase
import FirebaseAuth

// The main application entry point, defining the app structure and initializing services.
@main
struct CalorieBetaApp: App {
    // State objects to manage app-wide data, shared across views via environment.
    @StateObject var goalSettings = GoalSettings() // Manages user nutritional goals.
    @StateObject var dailyLogService = DailyLogService() // Handles daily food log operations.
    @StateObject var appState = AppState() // Tracks user authentication state.
    @StateObject var groupService = GroupService() // Manages community group data.

    // Initializes Firebase services when the app starts.
    init() {
        FirebaseApp.configure() // Sets up Firebase with the default configuration.
    }

    // Defines the app's window scene with the root content view.
    var body: some Scene {
        WindowGroup {
            ContentView() // The main content view of the app.
                .environmentObject(goalSettings) // Injects goal settings into the view hierarchy.
                .environmentObject(dailyLogService) // Injects daily log service.
                .environmentObject(appState) // Injects app state for authentication.
                .environmentObject(groupService) // Injects group service for community features.
        }
    }
}

// The root view of the app, controlling navigation based on authentication and loading state.
struct ContentView: View {
    // Environment objects to access shared state and services.
    @EnvironmentObject var appState: AppState // Accesses the app's authentication state.
    @EnvironmentObject var goalSettings: GoalSettings // Accesses user goals.
    @EnvironmentObject var dailyLogService: DailyLogService // Accesses daily log data.

    // State variables to manage UI and navigation.
    @State private var isLoading = true // Tracks if initial data is being loaded.
    @State private var scannedFoodItem: FoodItem? // Stores the food item detected by the scanner.
    @State private var showScanner = false // Controls visibility of the barcode scanner.
    @State private var showFoodDetail = false // Controls visibility of the food detail view.

    // The main body of the view, using a Group to conditionally render content.
    var body: some View {
        Group { // Allows conditional rendering of different views.
            if isLoading { // Shows loading state while data is fetched.
                LandingPageView() // Displays a landing page during initial load.
                    .onAppear {
                        loadInitialData() // Loads data when the view appears.
                    }
            } else if appState.isUserLoggedIn { // Shows main app content for logged-in users.
                MainTabView() // Displays the main tabbed interface.
                    .onAppear(perform: loadUserData) // Refreshes user data on appearance.
            } else { // G3: Shows WelcomeView instead of LoginView for unauthenticated users.
                WelcomeView() // G3: Displays the new welcome screen with login and sign-up options.
                    .onAppear(perform: checkLoginStatus) // Checks login status on appearance.
            }
        }
        .sheet(isPresented: $showScanner) { // Presents the barcode scanner as a sheet.
            BarcodeScannerView { foodItem in // Passes detected food item to the closure.
                DispatchQueue.main.async {
                    scannedFoodItem = foodItem // Stores the scanned food item.
                    showScanner = false // Closes the scanner.
                    showFoodDetail = true // Opens the food detail view.
                }
            }
        }
        .background( // Uses a hidden NavigationLink for programmatic navigation.
            NavigationLink(
                destination: scannedFoodItem.map { FoodDetailView(foodItem: $0, dailyLog: .constant(nil), onLogUpdated: { _ in }) }, // Navigates to food detail view with the scanned item.
                isActive: $showFoodDetail // Controls navigation activation.
            ) {
                EmptyView() // Placeholder to hide the link.
            }
            .hidden() // Hides the link from the UI.
        )
    }

    // Checks the current authentication status when the view appears.
    private func checkLoginStatus() {
        if let currentUser = Auth.auth().currentUser { // Checks if a user is already logged in.
            print("✅ User is already logged in: \(currentUser.uid)") // Logs successful check.
            appState.isUserLoggedIn = true // Updates app state.
            isLoading = false // Ends loading state.
        } else { // Handles unauthenticated state.
            print("❌ No user logged in") // Logs unauthenticated state.
            appState.isUserLoggedIn = false // Updates app state.
            isLoading = false // Ends loading state.
        }
    }

    // Loads initial data when the app starts, running on a background thread if needed.
    private func loadInitialData() {
        if appState.isUserLoggedIn { // Only loads data if a user is logged in.
            DispatchQueue.global(qos: .background).async { // Runs on a background thread.
                loadUserData() // Fetches user-specific data.
            }
        } else {
            isLoading = false // Ends loading if no user is logged in.
        }
    }

    // Loads user data (goals and daily log) from Firestore.
    private func loadUserData() {
        guard let userID = Auth.auth().currentUser?.uid else { // Ensures a user ID is available.
            print("No user ID found, user not logged in") // Logs error if no user.
            isLoading = false // Ends loading state.
            return
        }
        print("📥 Fetching data for User ID: \(userID) at \(Date())") // Logs data fetch start.

        goalSettings.loadUserGoals(userID: userID) // Loads user goals from Firestore.
        dailyLogService.fetchOrCreateTodayLog(for: userID) { result in // Fetches or creates today's log.
            DispatchQueue.main.async { // Ensures UI updates on the main thread.
                switch result {
                case .success(let log): // Handles successful log retrieval.
                    print("✅ Loaded today's log: \(log) at \(Date())") // Logs success.
                    dailyLogService.currentDailyLog = log // Updates the service with the log.
                    isLoading = false // Ends loading state.
                case .failure(let error): // Handles errors.
                    print("❌ Error loading user logs: \(error.localizedDescription) at \(Date())") // Logs error.
                    isLoading = false // Ends loading state.
                }
            }
        }
    }
}
