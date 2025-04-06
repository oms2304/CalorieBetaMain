import SwiftUI

import FirebaseAuth



// This is the main home screen of the "CalorieBeta" app, displaying daily nutrition progress,

// food items, and providing options to add food via search, barcode, or image.

struct HomeView: View {

    // Environment object to access the user's goal settings (e.g., calorie goals).

    @EnvironmentObject var goalSettings: GoalSettings

    // Environment object to manage daily log data and Firebase interactions.

    @EnvironmentObject var dailyLogService: DailyLogService



    // State variables to control various UI interactions and data:

    @State private var showingAddFoodOptions = false // Toggles the add food options menu.

    @State private var showingAddFoodView = false // Shows the manual food addition sheet.

    @State private var showingSearchView = false // Shows the food search view.

    @State private var showingBarcodeScanner = false // Shows the barcode scanner.

    @State private var showingImagePicker = false // Shows the camera for image-based food detection.

    @State private var scannedFoodName: String? // Stores the name of food scanned via barcode or image.

    @State private var foodPrediction: String = "" // Holds the AI-predicted food name from an image.

    @State private var selectedFoodItem: FoodItem? // Tracks the selected food item for navigation.

    @State private var navigateToProfile = false // Controls navigation to the profile view.

    @State private var showSettings = false // Controls the settings sheet.

    @State private var isTabBarHidden = false



    // An instance of the ML model to classify food from images.

    private let mlModel = MLImageModel()



    // Computed property to format the current date with a custom suffix (e.g., "1st", "2nd").

    private var currentDateString: String {

        let date = Date() // Gets the current date.

        let formatter = DateFormatter() // Creates a date formatter.

        formatter.dateFormat = "MMMM d" // Sets initial format (e.g., "March 7").

        let day = Calendar.current.component(.day, from: date) // Extracts the day number.

        let suffix: String // Determines the correct ordinal suffix.

        switch day {

        case 1, 21, 31: suffix = "st"

        case 2, 22: suffix = "nd"

        case 3, 23: suffix = "rd"

        default: suffix = "th"

        }

        formatter.dateFormat = "MMMM d'\(suffix)', yyyy" // Adds suffix and full year (e.g., "March 7th, 2025").

        return formatter.string(from: date) // Returns the formatted string.

    }



    // The main body of the view, wrapped in a NavigationView for title and navigation.

    var body: some View {

        NavigationView {

            ZStack {

                // Main vertical stack for content.

                VStack {

                    // Displays a nutrition progress view if a daily log exists.

                    if let currentDailyLog = dailyLogService.currentDailyLog {

                        NutritionProgressView(dailyLog: currentDailyLog, goal: goalSettings)

                            .frame(height: 250) // Fixed height to ensure consistent layout.

                        // Dot indicator for switching between chart types.

                        // Only shows when calorie goal is set and meals are present.

                        HStack(spacing: 8) {

                            DotIndicator(

                                isActive: goalSettings.calories != nil, // Simplified condition to ensure dots appear when goals are loaded.

                                activeIndex: goalSettings.showingBubbles ? 0 : 1 // 0 for bubbles, 1 for bar chart.

                            )

                            .onTapGesture {

                                withAnimation(.easeInOut(duration: 0.3)) { // Animates the chart transition.

                                    goalSettings.showingBubbles.toggle() // Toggles between bubble and bar chart.

                                }

                            }

                        }

                        .padding(.top, 8) // Adds spacing between the chart and dots.

                        // New title for the food diary section, placed beneath the dot indicator.

                        Text("Food Diary") // Clear title for the food log section.

                            .font(.headline) // Bold, prominent font for the title.

                            .foregroundColor(.primary) // Default text color for visibility.

                            .padding(.top, 8) // Adds spacing between the dots and the title.

                    } else {

                        // Shows a placeholder if no log data is available.

                        Text("No data available for the graph.")

                            .foregroundColor(.gray)

                            .font(.caption)

                    }



                    // A custom view to list food items from the daily log.

                    foodItemsList()



                    // Displays the AI food prediction if available.

                    if !foodPrediction.isEmpty {

                        Text(foodPrediction)

                            .font(.headline)

                            .padding()

                    }

                }

                .navigationTitle(currentDateString) // Sets the dynamic date as the title.

                .toolbar {

                    // Adds a menu in the navigation bar for profile and settings, now with "MyFitPlate" text instead of the logo.

                    ToolbarItem(placement: .navigationBarLeading) {

                        // G3: Replaced the "mfp logo" image with "MyFitPlate" text as per the updated design decision.

                        Text("MyFitPlate")

                            .font(.headline) // G3: Using a bold headline font for prominence.

                            .foregroundColor(.primary.opacity(0.5)) // G3: Matches the original logo opacity (0.5) for consistency.

                            .padding(.leading, 5) // G3: Kept the original padding for alignment with the previous logo.

                    }

                    ToolbarItem(placement: .navigationBarTrailing) {

                        Menu {

                            Button(action: { navigateToProfile = true }) {

                                Label("Profile", systemImage: "person") // Profile option.

                            }

                            Button(action: { showSettings = true }) {

                                Label("Settings", systemImage: "gearshape") // Settings option.

                            }

                        } label: {

                            Image(systemName: "line.3.horizontal") // Three-line menu icon.

                                .font(.title2)

                                .foregroundColor(.primary)

                        }

                    }

                }

                .background(

                    // Hidden NavigationLink to navigate to the profile view.

                    NavigationLink(

                        destination: UserProfileView(),

                        isActive: $navigateToProfile

                    ) {

                        EmptyView()

                    }

                    .hidden()

                )

                .sheet(isPresented: $showSettings) {

                    // Presents the settings view in a navigation context.

                    NavigationView { // Wraps SettingsView for its internal navigation.

                        SettingsView(showSettings: $showSettings)

                            .navigationViewStyle(StackNavigationViewStyle()) // Ensures proper stacking.

                    }

                }

                .onAppear {

                    // Loads initial data if the goal settings aren't being updated.

                    if !goalSettings.isUpdatingGoal {

                        loadInitialData()

                    }

                }



                // Floating plus button and options menu at the bottom right.

                



                // Overlay for the add food options menu.

                if showingAddFoodOptions {

                    Color.black.opacity(0.4) // Dark overlay to dim the background.

                        .edgesIgnoringSafeArea(.all) // Covers the entire screen.

                        .onTapGesture { showingAddFoodOptions = false } // Closes the menu on tap.



                    // Vertical stack of action buttons for adding food.

                    VStack(spacing: 16) {

                        Button(action: {

                            showingSearchView = true // Opens the food search view.

                            scannedFoodName = nil // Clears any previous scan.

                        }) {

                            ActionButtonLabel(title: "Search Food", icon: "magnifyingglass")

                        }

                        Button(action: { showingBarcodeScanner = true }) {

                            ActionButtonLabel(title: "Scan Barcode", icon: "barcode.viewfinder")

                        }

                        Button(action: {

                            showingImagePicker = true // Opens the camera for image scanning.

                        }) {

                            ActionButtonLabel(title: "Scan Food Image", icon: "camera")

                        }

                        Button(action: { showingAddFoodView = true }) {

                            ActionButtonLabel(title: "Add Food Manually", icon: "plus.circle")

                        }

                    }

                    .padding() // Adds padding around the menu.

                    .background(Color.white) // White background for the menu.

                    .cornerRadius(16) // Rounded corners.

                    .shadow(radius: 10) // Shadow for a floating effect.

                }

//                if !isTabBarHidden {

//                    VStack {

//                        Spacer() // Pushes the button to the bottom.

//                        HStack {

//                            Spacer() // Pushes the button to the right.

//                            Button(action: { showingAddFoodOptions.toggle() }) {

//                                Image(systemName: "plus") // Plus icon for adding food.

//                                    .resizable()

//                                    .frame(width: 60, height: 60)

//                                    .foregroundColor(.white)

//                                    .background(Color.green)

//                                    .clipShape(Circle()) // Circular shape.

//                                    .shadow(radius: 4) // Subtle shadow for depth.

//                            }

//                            .padding() // Adds padding around the button.

//                        }

//                    }

//                }

            }

            // Sheets for various add food options.

            .sheet(isPresented: $showingAddFoodView, onDismiss: {

                showingAddFoodOptions = false // Closes the options menu when done.

            }) {

                // Manual food addition view with a callback to add the food.

                AddFoodView { newFood in

                    if let userID = Auth.auth().currentUser?.uid {

                        dailyLogService.addFoodToCurrentLog(for: userID, foodItem: newFood)

                    }

                }

            }

            .sheet(isPresented: $showingSearchView, onDismiss: {

                showingAddFoodOptions = false // Closes the options menu.

                scannedFoodName = nil // Clears the scanned name.

            }) {

                // Food search view with the current log and scanned food name.

                if let currentLog = dailyLogService.currentDailyLog {

                    FoodSearchView(

                        dailyLog: .constant(currentLog),

                        onLogUpdated: { updatedLog in

                            dailyLogService.currentDailyLog = updatedLog // Updates the log.

                        },

                        initialSearchQuery: scannedFoodName ?? ""

                    )

                } else {

                    Text("Loading...") // Placeholder if the log isn’t ready.

                }

            }

            .sheet(isPresented: $showingBarcodeScanner) {

                // Barcode scanner view with a callback for the scanned food.

                BarcodeScannerView { foodItem in

                    DispatchQueue.main.async {

                        print("✅ Scanned Food: \(foodItem.name)") // Logs the scan.

                        scannedFoodName = foodItem.name // Stores the food name.

                        showingBarcodeScanner = false // Closes the scanner.

                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {

                            showingSearchView = true // Opens the search view after a delay.

                        }

                    }

                }

            }

            .sheet(isPresented: $showingImagePicker) {

                // Image picker for food detection with a callback for the image.

                ImagePicker(sourceType: .camera) { image in

                    DispatchQueue.main.async {

                        // Classifies the image using the ML model.

                        mlModel.classifyImage(image: image) { result in

                            switch result {

                            case .success(let foodName):

                                self.foodPrediction = "Predicted: \(foodName)" // Updates the prediction.

                                self.scannedFoodName = foodName // Stores the predicted name.

                                self.showingImagePicker = false // Closes the picker.

                                self.showingSearchView = true // Opens the search view.

                            case .failure(let error):

                                self.foodPrediction = "No food recognized: \(error.localizedDescription)" // Shows error.

                                self.showingImagePicker = false // Closes the picker.

                            }

                        }

                    }

                }

            }

        }

    }



    // A view builder to create a list of food items from the daily log.

    @ViewBuilder

    private func foodItemsList() -> some View {

        List {

            // Loops through all food items in the daily log’s meals.

            ForEach(dailyLogService.currentDailyLog?.meals.flatMap { $0.foodItems } ?? []) { foodItem in

                NavigationLink(

                    destination: FoodDetailView(

                        foodItem: foodItem,

                        dailyLog: $dailyLogService.currentDailyLog, // Binding to update the log.

                        onLogUpdated: { updatedLog in

                            dailyLogService.currentDailyLog = updatedLog // Updates the log.

                        }

                    ),

                    tag: foodItem, // Tags the link with the food item.

                    selection: $selectedFoodItem // Tracks the selected item.

                ) {

                    HStack {

                        Text(foodItem.name) // Displays the food name.

                        Spacer() // Pushes the calories to the right.

                        Text("\(Int(foodItem.calories)) kcal") // Shows the calorie count.

                    }

                }

            }

            .onDelete(perform: deleteFood) // Enables swipe-to-delete functionality.

        }

        .listStyle(InsetGroupedListStyle()) // Applies a styled list appearance.

    }



    // Loads initial data (goals and daily log) when the view appears.

    private func loadInitialData() {

        guard let userID = Auth.auth().currentUser?.uid else { return } // Ensures a user is logged in.



        // Loads the user's goals from Firebase.

        goalSettings.loadUserGoals(userID: userID)

        // Fetches or creates the daily log for today.

        dailyLogService.fetchOrCreateTodayLog(for: userID) { result in

            switch result {

            case .success(let log):

                DispatchQueue.main.async {

                    dailyLogService.currentDailyLog = log // Updates the log on the main thread.

                    print("✅ Loaded currentDailyLog: \(log)") // Debug: Verify log is loaded.

                }

            case .failure(let error):

                print("Error fetching logs: \(error.localizedDescription)") // Logs any errors.

            }

        }

    }



    // Deletes a food item from the daily log when swiped to delete.

    private func deleteFood(at offsets: IndexSet) {

        guard let userID = Auth.auth().currentUser?.uid else { return } // Ensures a user is logged in.

        let foodItems = dailyLogService.currentDailyLog?.meals.flatMap { $0.foodItems } ?? [] // Gets all food items.



        // Removes each selected food item from the log.

        offsets.forEach { index in

            let foodItem = foodItems[index]

            dailyLogService.deleteFoodFromCurrentLog(for: userID, foodItemID: foodItem.id)

        }

    }

}



// Custom view for the dot indicator.

struct DotIndicator: View {

    let isActive: Bool // Determines if the indicator should be visible.

    let activeIndex: Int // Index of the active dot (0 for bubbles, 1 for bar chart).

    let totalDots: Int = 2 // Number of chart types (bubble and bar).



    var body: some View {

        // Debug log to verify the indicator is being evaluated.

        let _ = print("DotIndicator - isActive: \(isActive), activeIndex: \(activeIndex)")

        if isActive {

            HStack(spacing: 8) {

                ForEach(0..<totalDots, id: \.self) { index in

                    Circle()

                        .frame(width: index == activeIndex ? 10 : 6, height: index == activeIndex ? 10 : 6) // Active dot is larger.

                        .foregroundColor(index == activeIndex ? .blue : .gray.opacity(0.5)) // Active dot is blue, others are gray.

                }

            }

        } else {

            EmptyView() // Returns an empty view when inactive to avoid rendering issues.

        }

    }

}



// A custom view for the action buttons in the add food options menu.

