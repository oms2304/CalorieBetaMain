import SwiftUI
<<<<<<< HEAD
import FirebaseAuth
=======
>>>>>>> d3d7eb3 (Initial commit)

struct MainTabView: View {
    @EnvironmentObject var goalSettings: GoalSettings
    @EnvironmentObject var dailyLogService: DailyLogService

    var body: some View {
        TabView {
<<<<<<< HEAD
            HomeView()
=======
            HomeView() 
>>>>>>> d3d7eb3 (Initial commit)
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }

<<<<<<< HEAD
=======
            CalorieHistoryView()
                .tabItem {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                    Text("History")
                }

>>>>>>> d3d7eb3 (Initial commit)
            AIChatbotView()
                .tabItem {
                    Image(systemName: "message.fill")
                    Text("AI Recipe Bot")
                }

<<<<<<< HEAD
=======
            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("Settings")
                }

>>>>>>> d3d7eb3 (Initial commit)
            WeightTrackingView()
                .tabItem {
                    Image(systemName: "scalemass.fill")
                    Text("Weight Tracker")
                }
        }
    }
}
<<<<<<< HEAD

=======
>>>>>>> d3d7eb3 (Initial commit)
