import SwiftUI
import Firebase
import FirebaseAuth

@main
struct CalorieBetaApp: App {
    @StateObject var goalSettings = GoalSettings()
    @StateObject var dailyLogService = DailyLogService()
    @StateObject var appState = AppState()
<<<<<<< HEAD
    @StateObject var groupService = GroupService()

    init() {
=======

    init() {
      
>>>>>>> d3d7eb3 (Initial commit)
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
<<<<<<< HEAD
                .environmentObject(goalSettings)
                .environmentObject(dailyLogService)
                .environmentObject(appState)
                .environmentObject(groupService)
=======
                .environmentObject(dailyLogService)
                .environmentObject(appState)
>>>>>>> d3d7eb3 (Initial commit)
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var goalSettings: GoalSettings
    @EnvironmentObject var dailyLogService: DailyLogService

<<<<<<< HEAD
    @State private var scannedFoodItem: FoodItem?
    @State private var showScanner = false
    @State private var showFoodDetail = false

    var body: some View {
        Group {
            if appState.isUserLoggedIn {
                MainTabView()
                    .onAppear(perform: loadUserData)
            } else {
                LoginView()
                    .onAppear(perform: checkLoginStatus)
            }
        }
        .sheet(isPresented: $showScanner) {
            BarcodeScannerView { foodItem in
                DispatchQueue.main.async {
                    scannedFoodItem = foodItem
                    showScanner = false
                    showFoodDetail = true
                }
            }
        }
        .background(
            NavigationLink(
                destination: scannedFoodItem.map { FoodDetailView(foodItem: $0, dailyLog: .constant(nil), onLogUpdated: { _ in }) },
                isActive: $showFoodDetail
            ) {
                EmptyView()
            }
            .hidden()
        )
    }

    private func checkLoginStatus() {
        if let currentUser = Auth.auth().currentUser {
            print("✅ User is already logged in: \(currentUser.uid)")
            appState.isUserLoggedIn = true
            loadUserData()
        } else {
            print("❌ No user logged in")
            appState.isUserLoggedIn = false
        }
    }

    private func loadUserData() {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("No user ID found, user not logged in")
            return
        }
        print("📥 Fetching data for User ID: \(userID)")

        goalSettings.loadUserGoals(userID: userID)

        dailyLogService.fetchOrCreateTodayLog(for: userID) { result in
            switch result {
            case .success(let log):
                DispatchQueue.main.async {
                    dailyLogService.currentDailyLog = log
                }
                print("✅ Loaded today's log: \(log)")
            case .failure(let error):
                print("❌ Error loading user logs: \(error.localizedDescription)")
=======
    var body: some View {
        Group {
            if appState.isUserLoggedIn {
              
                MainTabView()
                    .onAppear {
                        loadUserData()
                    }
            } else {
                
                LoginOrSignUpView()
            }
        }
    }

    private func loadUserData() {
        // Load user-specific data once logged in
        if let userID = Auth.auth().currentUser?.uid {
            print("Current User ID: \(userID)") // Debug line

          
            goalSettings.loadUserGoals(userID: userID)
            
       
            dailyLogService.fetchLogs(for: userID) { result in
                switch result {
                case .success(let logs):
                    if logs.isEmpty {
                        print("No logs found for user: \(userID)") // Debug line
                    } else {
                        print("Fetched logs: \(logs)") // Debug line
                    }
                    DispatchQueue.main.async {
                        dailyLogService.currentDailyLog = logs.first
                    }
                case .failure(let error):
                    print("Error loading user logs: \(error.localizedDescription)")
                }
            }
        } else {
            print("No user ID found, user not logged in") // Debug line
        }
    }
}

struct LoginOrSignUpView: View {
    @State private var isShowingSignUp = false

    var body: some View {
        VStack {
            LoginView()
            Button("Don't have an account? Sign Up") {
                isShowingSignUp.toggle()
            }
            .padding()
            .sheet(isPresented: $isShowingSignUp) {
                SignUpView()
>>>>>>> d3d7eb3 (Initial commit)
            }
        }
    }
}
