import SwiftUI
import FirebaseAuth

// MARK: - HomeView
/// The primary view of the MyFitPlate app, serving as the main dashboard where users can track their daily nutrition,
/// view their food diary, and add new food entries. This view leverages Firebase for data management and integrates
/// with GoalSettings and DailyLogService for real-time updates. The navigation and branding are controlled by MainTabView.
struct HomeView: View {
    // MARK: - Environment and Bindings
    /// Provides access to user-defined nutritional goals (e.g., calories, protein, fats, carbs) and chart preferences.
    @EnvironmentObject var goalSettings: GoalSettings
    /// Handles all interactions with Firebase Firestore, including fetching and updating daily logs.
    @EnvironmentObject var dailyLogService: DailyLogService
    /// Detects the current color scheme (light or dark) to adapt UI elements.
    @Environment(\.colorScheme) var colorScheme

    /// A binding to trigger navigation to the UserProfileView, managed by the parent MainTabView.
    @Binding var navigateToProfile: Bool
    /// A binding to toggle the visibility of the SettingsView as a sheet, managed by MainTabView.
    @Binding var showSettings: Bool

    // MARK: - State Variables
    /// Controls the visibility of the add food options menu (search, barcode, image, manual).
    @State private var showingAddFoodOptions = false
    /// Triggers the presentation of the sheet for manually adding a food item.
    @State private var showingAddFoodView = false
    /// Triggers the presentation of the sheet for searching food items.
    @State private var showingSearchView = false
    /// Triggers the presentation of the sheet for scanning a barcode to identify food.
    @State private var showingBarcodeScanner = false
    /// Triggers the presentation of the sheet for capturing an image for AI-based food recognition.
    @State private var showingImagePicker = false
    /// Stores the name of a food item detected via barcode or image scanning for further processing.
    @State private var scannedFoodName: String?
    /// Holds the AI-predicted food name from image recognition, displayed in the UI.
    @State private var foodPrediction: String = ""
    /// Tracks a selected food item for potential navigation to a detail view (currently unused).
    @State private var selectedFoodItem: FoodItem?
    /// Represents the currently selected date for the log, defaulting to the current date.
    @State private var selectedDate: Date = Date()
    /// Stores the list of food items for the selected date, updated reactively with daily log changes.
    @State private var foodItems: [FoodItem] = []
    /// Temporary state to force UI refresh after deletion
    @State private var refreshToggle = false

    // MARK: - Private Properties
    /// An instance of the machine learning model used to classify food from images.
    private let mlModel = MLImageModel()

    // MARK: - Computed Properties
    /// Formats the selected date as "March 18, 2025" for display in the date navigation section.
    private var selectedDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy" // Full date format including the year, matching the screenshot.
        return formatter.string(from: selectedDate)
    }

    /// Determines if the selected date is today, used to disable navigation to future dates.
    private var isToday: Bool {
        Calendar.current.isDateInToday(selectedDate)
    }

    // MARK: - Body
    var body: some View {
        NavigationView { // Local NavigationView to manage toolbar and navigation within this view.
            ZStack {
                // Main content area wrapped in a ScrollView to handle overflow content.
                ScrollView {
                    VStack(spacing: 16) {
                        // Date Navigation Section: Allows users to navigate through previous and future dates.
                        HStack {
                            // Button to navigate to the previous day, triggering a log fetch.
                            Button(action: {
                                selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate)!
                                fetchLogForSelectedDate()
                            }) {
                                Image(systemName: "chevron.left")
                                    .foregroundColor(.gray)
                            }
                            
                            Spacer() // Pushes the date text to the center.
                            
                            // Displays the selected date, styled to match the screenshot.
                            Text(selectedDateString)
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(colorScheme == .dark ? .white : .black) // Dynamic text color.
                            
                            Spacer() // Pushes the next day button to the right.
                            
                            // Button to navigate to the next day, disabled if the current date is today.
                            Button(action: {
                                selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate)!
                                fetchLogForSelectedDate()
                            }) {
                                Image(systemName: "chevron.right")
                                    .foregroundColor(isToday ? .gray.opacity(0.3) : .gray)
                            }
                            .disabled(isToday)
                        }
                        .padding(.horizontal)
                        .padding(.top)

                        // Nutrition Progress Section: Displays progress towards daily nutritional goals.
                        if let currentDailyLog = dailyLogService.currentDailyLog {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Nutrition Progress")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(colorScheme == .dark ? .white : .black) // Dynamic text color.
                                    .padding(.horizontal)
                                // NutritionProgressView renders circular progress indicators for various nutrients.
                                NutritionProgressView(dailyLog: currentDailyLog, goal: goalSettings)
                                    .frame(height: 180)
                                    .id(refreshToggle) // Force re-render on toggle
                            }
                            .padding()
                            .background(colorScheme == .dark ? Color(.secondarySystemBackground) : Color(red: 245/255, green: 245/255, blue: 245/255)) // Dynamic background.
                            .cornerRadius(15)
                            .shadow(radius: 2)
                        } else {
                            // Placeholder text when no daily log data is available.
                            Text("No data available for the graph.")
                                .foregroundColor(.gray)
                                .font(.caption)
                                .padding()
                                .background(colorScheme == .dark ? Color(.secondarySystemBackground) : Color(red: 245/255, green: 245/255, blue: 245/255)) // Dynamic background.
                                .cornerRadius(15)
                                .shadow(radius: 2)
                        }

                        // Dot indicator for toggling between bubble and bar chart views.
                        HStack(spacing: 8) {
                            DotIndicator(
                                isActive: goalSettings.calories != nil,
                                activeIndex: goalSettings.showingBubbles ? 0 : 1
                            )
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    goalSettings.showingBubbles.toggle()
                                }
                            }
                        }
                        .padding(.top, 8)

                        // Food Diary Section: Lists all food items logged for the selected date.
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Food Diary")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(colorScheme == .dark ? .white : .black) // Dynamic text color.
                                .padding(.horizontal)
                            foodItemsList(foodItems: $foodItems) // Passes a binding to the food items list.
                        }
                        .padding()
                        .background(colorScheme == .dark ? Color(.secondarySystemBackground) : Color(red: 245/255, green: 245/255, blue: 245/255)) // Dynamic background.
                        .cornerRadius(15)
                        .shadow(radius: 2)

                        // AI Prediction Section: Shows the result of AI-based food recognition from images.
                        if !foodPrediction.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("AI Prediction")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .foregroundColor(colorScheme == .dark ? .white : .black) // Dynamic text color.
                                Text(foodPrediction)
                                    .font(.body)
                                    .foregroundColor(colorScheme == .dark ? .white : .black) // Dynamic text color.
                                    .padding(.horizontal)
                            }
                            .padding()
                            .background(colorScheme == .dark ? Color(.secondarySystemBackground) : Color(red: 245/255, green: 245/255, blue: 245/255)) // Dynamic background.
                            .cornerRadius(15)
                            .shadow(radius: 2)
                        }
                    }
                    .padding(.vertical)
                }
                .background(colorScheme == .dark ? Color(.systemBackground) : Color.white) // Dynamic background for the entire view.
                .onChange(of: dailyLogService.currentDailyLog) { _ in
                    print("🔄 currentDailyLog changed, triggering refresh")
                }

                // Floating Action Button: Allows users to add new food entries, positioned at bottom-right.
                VStack {
                    Spacer() // Pushes the button to the bottom.
                    HStack {
                        Spacer() // Pushes the button to the right.
                        Button(action: {
                            showingAddFoodOptions.toggle()
                        }) {
                            Image(systemName: "plus")
                                .resizable()
                                .frame(width: 60, height: 60)
                                .foregroundColor(.white)
                                .background(Color(red: 67/255, green: 173/255, blue: 111/255))
                                .clipShape(Circle())
                                .shadow(radius: 4)
                        }
                        .padding()
                    }
                }
                .zIndex(1)

                // Add Food Options Menu: Appears when the floating button is tapped, offering multiple input methods.
                if showingAddFoodOptions {
                    // Dimmed overlay to dismiss the menu when tapped outside.
                    Color.black.opacity(0.5)
                        .edgesIgnoringSafeArea(.all)
                        .onTapGesture {
                            showingAddFoodOptions = false
                        }

                    // Menu containing options for adding food (search, barcode, image, manual).
                    VStack(spacing: 16) {
                        Button(action: {
                            showingSearchView = true
                            scannedFoodName = nil
                        }) {
                            ActionButtonLabel(title: "Search Food", icon: "magnifyingglass")
                        }
                        Button(action: {
                            showingBarcodeScanner = true
                        }) {
                            ActionButtonLabel(title: "Scan Barcode", icon: "barcode.viewfinder")
                        }
                        Button(action: {
                            showingImagePicker = true
                        }) {
                            ActionButtonLabel(title: "Scan Food Image", icon: "camera")
                        }
                        Button(action: {
                            showingAddFoodView = true
                        }) {
                            ActionButtonLabel(title: "Add Food Manually", icon: "plus.circle")
                        }
                    }
                    .padding()
                    .background(colorScheme == .dark ? Color(.secondarySystemBackground) : Color(red: 245/255, green: 245/255, blue: 245/255)) // Dynamic background.
                    .cornerRadius(16)
                    .shadow(radius: 10)
                    .zIndex(2)
                }
            }
            .navigationBarTitleDisplayMode(.inline) // Ensures the title is inline, avoiding large title behavior.
            .toolbar {
                // Leading Toolbar Item: Displays the app branding.
                ToolbarItem(placement: .navigationBarLeading) {
                    Text("MyFitPlate")
                        .font(.headline)
                        .foregroundColor(.primary.opacity(0.5))
                        .padding(.leading, 5)
                }
                // Trailing Toolbar Item: Contains the hamburger menu for profile and settings navigation.
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: {
                            print("🔍 Hamburger menu: Navigating to Profile, navigateToProfile before: \(navigateToProfile)")
                            navigateToProfile = true
                            print("🔍 Hamburger menu: Navigating to Profile, navigateToProfile after: \(navigateToProfile)")
                        }) {
                            Label("Profile", systemImage: "person")
                        }
                        Button(action: {
                            print("🔍 Hamburger menu: Opening Settings, showSettings before: \(showSettings)")
                            showSettings = true
                            print("🔍 Hamburger menu: Opening Settings, showSettings after: \(showSettings)")
                        }) {
                            Label("Settings", systemImage: "gearshape")
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal")
                            .font(.title2)
                            .foregroundColor(.gray)
                            .onAppear {
                                print("🔍 Hamburger menu button appeared in toolbar")
                            }
                    }
                }
            }
            .background(
                NavigationLink(
                    destination: UserProfileView()
                        .environmentObject(dailyLogService)
                        .environmentObject(goalSettings),
                    isActive: $navigateToProfile
                ) {
                    EmptyView()
                }
                .hidden()
            )
        }
        .sheet(isPresented: $showingAddFoodView, onDismiss: {
            showingAddFoodOptions = false
            fetchLogForSelectedDate()
        }) {
            AddFoodView { newFood in
                if let userID = Auth.auth().currentUser?.uid {
                    dailyLogService.addFoodToCurrentLog(for: userID, foodItem: newFood, date: selectedDate)
                    print("Added food manually: \(newFood)")
                }
            }
        }
        .sheet(isPresented: $showingSearchView, onDismiss: {
            showingAddFoodOptions = false
            scannedFoodName = nil
            fetchLogForSelectedDate()
        }) {
            if let currentLog = dailyLogService.currentDailyLog {
                FoodSearchView(
                    dailyLog: .constant(currentLog),
                    onLogUpdated: { updatedLog in
                        dailyLogService.currentDailyLog = updatedLog
                        print("Log updated in HomeView: \(updatedLog)")
                        fetchLogForSelectedDate()
                    },
                    initialSearchQuery: scannedFoodName ?? ""
                )
            } else {
                Text("Loading...")
            }
        }
        .sheet(isPresented: $showingBarcodeScanner) {
            BarcodeScannerView { foodItem in
                DispatchQueue.main.async {
                    print("✅ Scanned Food: \(foodItem.name)")
                    scannedFoodName = foodItem.name
                    showingBarcodeScanner = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        showingSearchView = true
                    }
                }
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(sourceType: .camera) { image in
                DispatchQueue.main.async {
                    mlModel.classifyImage(image: image) { result in
                        switch result {
                        case .success(let foodName):
                            self.foodPrediction = "Predicted: \(foodName)"
                            self.scannedFoodName = foodName
                            self.showingImagePicker = false
                            self.showingSearchView = true
                        case .failure(let error):
                            self.foodPrediction = "No food recognized: \(error.localizedDescription)"
                            self.showingImagePicker = false
                        }
                    }
                }
            }
        }
        .onAppear {
            if !goalSettings.isUpdatingGoal, let userID = Auth.auth().currentUser?.uid {
                fetchInitialData(for: userID)
            }
        }
    }
    
    // MARK: - Food Items List
    /// Renders a list of food items for the selected date, supporting swipe-to-delete functionality.
    @ViewBuilder
    private func foodItemsList(foodItems: Binding<[FoodItem]>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if foodItems.wrappedValue.isEmpty {
                Text("No food items logged yet.")
                    .foregroundColor(.gray)
                    .font(.body)
                    .padding()
            } else {
                ForEach(foodItems.wrappedValue, id: \.id) { foodItem in
                    SwipeableFoodItemView(
                        foodItem: foodItem,
                        index: foodItems.wrappedValue.firstIndex(of: foodItem) ?? 0,
                        dailyLog: $dailyLogService.currentDailyLog,
                        onDelete: { index in
                            deleteFood(at: IndexSet(integer: index))
                            foodItems.wrappedValue.remove(at: index) // Force immediate UI update
                        },
                        onLogUpdated: { updatedLog in
                            dailyLogService.currentDailyLog = updatedLog
                            print("Food detail updated log: \(updatedLog)")
                            fetchLogForSelectedDate()
                        },
                        date: selectedDate
                    )
                }
            }
        }
        .onAppear {
            print("🔍 foodItemsList onAppear - currentDailyLog: \(String(describing: dailyLogService.currentDailyLog))")
            if let meals = dailyLogService.currentDailyLog?.meals {
                print("🔍 Number of meals: \(meals.count)")
                let allFoodItems = meals.flatMap { $0.foodItems }
                print("🔍 Total food items: \(allFoodItems.count)")
                for item in allFoodItems {
                    print("🔍 Food item: \(item.name), Calories: \(item.calories), ID: \(item.id)")
                }
            } else {
                print("🔍 No meals or daily log available in foodItemsList.")
            }
            foodItems.wrappedValue = dailyLogService.currentDailyLog?.meals.flatMap { $0.foodItems } ?? []
        }
        .onChange(of: dailyLogService.currentDailyLog) { newLog in
            print("🔍 currentDailyLog changed, updating foodItems")
            foodItems.wrappedValue = newLog?.meals.flatMap { $0.foodItems } ?? []
        }
    }
    
    // MARK: - SwipeableFoodItemView
    /// A custom view for each food item, supporting swipe-to-delete and navigation to a detail view.
    struct SwipeableFoodItemView: View {
        let foodItem: FoodItem
        let index: Int
        @Binding var dailyLog: DailyLog?
        let onDelete: (Int) -> Void
        let onLogUpdated: (DailyLog) -> Void
        let date: Date
        @Environment(\.colorScheme) var colorScheme

        @State private var offset: CGFloat = 0
        @State private var isSwiped: Bool = false

        var body: some View {
            ZStack(alignment: .trailing) {
                if isSwiped {
                    Button(action: {
                        print("🔥 Delete button clicked for item at index: \(index), isSwiped: \(isSwiped)")
                        onDelete(index)
                        DispatchQueue.main.async {
                            withAnimation {
                                offset = 0
                                isSwiped = false
                                print("🔍 State reset: offset = \(offset), isSwiped = \(isSwiped)")
                            }
                        }
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(.white)
                            .frame(width: 50, height: 40)
                            .background(Color.red)
                            .cornerRadius(8)
                    }
                    .transition(.opacity)
                    .padding(.trailing, 8)
                }
                
                HStack {
                    NavigationLink(
                        destination: FoodDetailView(
                            foodItem: foodItem,
                            dailyLog: $dailyLog,
                            date: date,
                            onLogUpdated: onLogUpdated
                        )
                    ) {
                        Text(FoodEmojiMapper.getEmoji(for: foodItem.name) + " " + foodItem.name)
                            .lineLimit(1)
                            .foregroundColor(colorScheme == .dark ? .white : .black) // Dynamic text color.
                    }
                    Spacer()
                    NavigationLink(
                        destination: FoodDetailView(
                            foodItem: foodItem,
                            dailyLog: $dailyLog,
                            date: date,
                            onLogUpdated: onLogUpdated
                        )
                    ) {
                        Text("\(Int(foodItem.calories)) kcal")
                            .foregroundColor(.gray)
                    }
                }
                .padding(.vertical, 8)
                .padding(.horizontal)
                .background(colorScheme == .dark ? Color(.tertiarySystemBackground) : Color(red: 245/255, green: 245/255, blue: 245/255).opacity(0.5)) // Dynamic background.
                .cornerRadius(8)
                .offset(x: offset)
                .highPriorityGesture(
                    DragGesture()
                        .onChanged { value in
                            print("🔍 Gesture onChanged - translation: \(value.translation.width)")
                            if value.translation.width < 0 {
                                let newOffset = max(value.translation.width, -60)
                                offset = newOffset
                                isSwiped = newOffset < -30
                                print("🔍 Offset: \(offset), isSwiped: \(isSwiped)")
                            } else {
                                offset = 0
                                isSwiped = false
                                print("🔍 Reset offset to 0, isSwiped: false")
                            }
                        }
                        .onEnded { value in
                            print("🔍 Gesture onEnded - translation: \(value.translation.width)")
                            withAnimation {
                                if value.translation.width < -30 {
                                    offset = -60
                                    isSwiped = true
                                    print("🔍 Locked offset at -60, isSwiped: true")
                                } else {
                                    offset = 0
                                    isSwiped = false
                                    print("🔍 Reset offset to 0, isSwiped: false")
                                }
                            }
                        }
                )
            }
        }
    }

    // MARK: - Helper Methods
    private func fetchInitialData(for userID: String) {
        goalSettings.loadUserGoals(userID: userID)
        fetchLogForSelectedDate()
    }

    private func fetchLogForSelectedDate() {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        dailyLogService.fetchLog(for: userID, date: selectedDate) { result in
            switch result {
            case .success(let log):
                DispatchQueue.main.async {
                    dailyLogService.currentDailyLog = log
                    print("✅ Loaded log for \(self.selectedDateString): \(log)")
                    print("🔍 Log details - Meals: \(log.meals.count), Food Items: \(log.meals.flatMap { $0.foodItems }.count)")
                }
            case .failure(let error):
                print("❌ Error fetching log for \(self.selectedDateString): \(error.localizedDescription)")
                DispatchQueue.main.async {
                    dailyLogService.currentDailyLog = nil
                }
            }
        }
    }

    private func deleteFood(at offsets: IndexSet) {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        let foodItems = dailyLogService.currentDailyLog?.meals.flatMap { $0.foodItems } ?? []

        offsets.forEach { index in
            let foodItem = foodItems[index]
            print("🔥 Deleting food item at index: \(index), ID: \(foodItem.id)")
            dailyLogService.deleteFoodFromCurrentLog(for: userID, foodItemID: foodItem.id, date: selectedDate)
            DispatchQueue.main.async {
                fetchLogForSelectedDate()
                print("🔍 Deletion processed, log refreshed")
                self.refreshToggle.toggle()
                print("🔍 Refresh toggle set to: \(self.refreshToggle)")
            }
        }
    }
}

// MARK: - Dot Indicator
struct DotIndicator: View {
    let isActive: Bool
    let activeIndex: Int
    let totalDots: Int = 2

    var body: some View {
        if isActive {
            HStack(spacing: 8) {
                ForEach(0..<totalDots, id: \.self) { index in
                    Circle()
                        .frame(width: index == activeIndex ? 10 : 6, height: index == activeIndex ? 10 : 6)
                        .foregroundColor(index == activeIndex ? Color(red: 144/255, green: 190/255, blue: 109/255) : Color(red: 117/255, green: 117/255, blue: 117/255).opacity(0.5))
                }
            }
        } else {
            EmptyView()
        }
    }
}

// MARK: - Action Button Label
struct ActionButtonLabel: View {
    let title: String
    let icon: String
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(Color(red: 144/255, green: 190/255, blue: 109/255))
                .frame(width: 24, height: 24)
            Text(title)
                .foregroundColor(colorScheme == .dark ? .white : .black) // Dynamic text color.
                .font(.headline)
            Spacer()
        }
        .padding()
        .background(colorScheme == .dark ? Color(.tertiarySystemBackground) : Color(red: 245/255, green: 245/255, blue: 245/255).opacity(0.5)) // Dynamic background.
        .cornerRadius(12)
    }
}

// MARK: - FoodEmojiMapper
struct FoodEmojiMapper {
    static let foodEmojiMap: [String: String] = [
        "hotdog": "🌭", "hot dog": "🌭",
        "burger": "🍔", "hamburger": "🍔",
        "cheeseburger": "🍔",
        "pizza": "🍕",
        "taco": "🌮",
        "burrito": "🌯",
        "fries": "🍟",
        "sandwich": "🥪",
        "wrap": "🌯",
        "nachos": "🌮",
        "steak": "🥩",
        "chicken": "🍗",
        "fish": "🐟",
        "shrimp": "🍤",
        "prawn": "🍤",
        "egg": "🥚",
        "bacon": "🥓",
        "sausage": "🌭",
        "ham": "🥓",
        "pork": "🥓",
        "beef": "🥩",
        "lamb": "🍖",
        "turkey": "🍗",
        "oyster": "🐚",
        "caviar": "🐟",
        "rice": "🍚",
        "pasta": "🍝",
        "bread": "🍞",
        "noodles": "🍜",
        "bagel": "🥯",
        "croissant": "🥐",
        "pretzel": "🥨",
        "bun": "🥐",
        "roll": "🥐",
        "apple": "🍎",
        "banana": "🍌",
        "orange": "🍊",
        "grape": "🍇",
        "strawberry": "🍓",
        "watermelon": "🍉",
        "pear": "🍐",
        "cherry": "🍒",
        "mango": "🥭",
        "pineapple": "🍍",
        "peach": "🍑",
        "kiwi": "🥝",
        "lemon": "🍋",
        "lime": "🍋",
        "blueberry": "🫐",
        "raspberry": "🫐",
        "carrot": "🥕",
        "broccoli": "🥦",
        "tomato": "🍅",
        "potato": "🥔",
        "corn": "🌽",
        "lettuce": "🥬",
        "cucumber": "🥒",
        "onion": "🧅",
        "garlic": "🧄",
        "pepper": "🌶️",
        "mushroom": "🍄",
        "spinach": "🥬",
        "cabbage": "🥬",
        "zucchini": "🥒",
        "eggplant": "🍆",
        "cake": "🍰",
        "cookie": "🍪",
        "ice cream": "🍦",
        "donut": "🍩",
        "chocolate": "🍫",
        "candy": "🍬",
        "cupcake": "🧁",
        "pie": "🥧",
        "pudding": "🍮",
        "waffle": "🧇",
        "pancake": "🥞",
        "coffee": "☕",
        "tea": "🍵",
        "juice": "🍹",
        "beer": "🍺",
        "wine": "🍷",
        "milk": "🥛",
        "cocktail": "🍸",
        "soda": "🥤",
        "water": "💧",
        "sushi": "🍣",
        "sushi roll": "🍣",
        "ramen": "🍜",
        "curry": "🍛",
        "dumpling": "🥟",
        "egg roll": "🥟",
        "falafel": "🧆",
        "pad thai": "🍜",
        "paella": "🍲",
        "gyoza": "🥟",
        "spring roll": "🥟",
        "tempura": "🍤",
        "cheese": "🧀",
        "peanut": "🥜",
        "popcorn": "🍿",
        "lollipop": "🍭",
        "honey": "🍯",
        "jam": "🍇",
        "butter": "🧈",
        "oil": "🛢️",
        "soup": "🥣",
        "salad": "🥗",
        "stew": "🍲",
        "casserole": "🍲",
        "quesadilla": "🌮"
    ]

    static func getEmoji(for foodName: String) -> String {
        let lowercasedName = foodName.lowercased()
        if let exactMatch = foodEmojiMap[lowercasedName] {
            return exactMatch
        }
        let words = lowercasedName.split(separator: " ").map { String($0) }
        if let firstWordMatch = words.first, let match = foodEmojiMap[firstWordMatch] {
            return match
        }
        return foodEmojiMap.first { lowercasedName.contains($0.key) }?.value ?? "🍽️"
    }
}
