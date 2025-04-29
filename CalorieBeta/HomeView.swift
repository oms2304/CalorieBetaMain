import SwiftUI
import FirebaseAuth

// MARK: - HomeView
struct HomeView: View {
    // MARK: - Environment and Bindings
    @EnvironmentObject var goalSettings: GoalSettings
    @EnvironmentObject var dailyLogService: DailyLogService
    @Environment(\.colorScheme) var colorScheme
    @Binding var navigateToProfile: Bool
    @Binding var showSettings: Bool

    // MARK: - State Variables
    @State private var showingAddFoodOptions = false
    @State private var showingAddFoodView = false
    @State private var showingSearchView = false
    @State private var showingBarcodeScanner = false
    @State private var showingImagePicker = false
    @State private var scannedFoodName: String?
    @State private var foodPrediction: String = ""
    @State private var selectedFoodItem: FoodItem?
    @State private var selectedDate: Date = Date()
    @State private var refreshToggle = false

    // MARK: - Private Properties
    private let mlModel = MLImageModel()

    // MARK: - Computed Properties
    // *** CORRECTED dateFormat ***
    private var selectedDateString: String {
        let formatter = DateFormatter()
        // Use "MMMM d, yyyy" for format like "April 17, 2025"
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: selectedDate)
    }
    private var isToday: Bool { Calendar.current.isDateInToday(selectedDate) }

    // MARK: - Body
    var body: some View {
        NavigationView {
            ZStack {
                ScrollView {
                    VStack(spacing: 16) {

                        // Date Navigation Section
                        HStack {
                            Button(action: {
                                selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate)!
                                fetchLogForSelectedDate()
                            }) { Image(systemName: "chevron.left").foregroundColor(.gray) }
                            Spacer()
                            // This Text view uses the corrected computed property
                            Text(selectedDateString)
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                            Spacer()
                            Button(action: {
                                selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate)!
                                fetchLogForSelectedDate()
                            }) { Image(systemName: "chevron.right").foregroundColor(isToday ? .gray.opacity(0.3) : .gray) }
                            .disabled(isToday)
                        }
                        .padding(.horizontal)
                        .padding(.top)

                        // Nutrition Progress Section
                        if let currentDailyLog = dailyLogService.currentDailyLog {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Nutrition Progress")
                                    .font(.title2).fontWeight(.bold)
                                    .foregroundColor(colorScheme == .dark ? .white : .black)
                                    .padding(.horizontal)
                                NutritionProgressView(dailyLog: currentDailyLog, goal: goalSettings)
                                    .id(refreshToggle)
                            }
                            .padding()
                            .background(colorScheme == .dark ? Color(.secondarySystemBackground) : Color(red: 245/255, green: 245/255, blue: 245/255))
                            .cornerRadius(15).shadow(radius: 2)
                        } else {
                             Text("Loading Nutrition Data...")
                                 .foregroundColor(.gray).font(.caption)
                                 .padding().frame(maxWidth: .infinity, minHeight: 180)
                                 .background(colorScheme == .dark ? Color(.secondarySystemBackground) : Color(red: 245/255, green: 245/255, blue: 245/255))
                                 .cornerRadius(15).shadow(radius: 2)
                        }

                        // Dot indicator
                        HStack(spacing: 8) {
                            DotIndicator(isActive: goalSettings.calories != nil, activeIndex: goalSettings.showingBubbles ? 0 : 1)
                                .onTapGesture { withAnimation(.easeInOut(duration: 0.3)) { goalSettings.showingBubbles.toggle() } }
                        }
                        .padding(.top, 8)

                        // Food Diary Section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Food Diary")
                                .font(.title3).fontWeight(.semibold)
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                                .padding(.horizontal)
                            foodItemsList(items: dailyLogService.currentDailyLog?.meals.flatMap { $0.foodItems } ?? [])
                        }
                        .padding()
                        .background(colorScheme == .dark ? Color(.secondarySystemBackground) : Color(red: 245/255, green: 245/255, blue: 245/255))
                        .cornerRadius(15).shadow(radius: 2)

                        // AI Prediction Section
                        if !foodPrediction.isEmpty {
                             VStack(alignment: .leading, spacing: 8) {
                                 Text("AI Prediction").font(.title3).fontWeight(.semibold)
                                     .foregroundColor(colorScheme == .dark ? .white : .black)
                                 Text(foodPrediction).font(.body)
                                     .foregroundColor(colorScheme == .dark ? .white : .black)
                                     .padding(.horizontal)
                             }
                             .padding()
                             .background(colorScheme == .dark ? Color(.secondarySystemBackground) : Color(red: 245/255, green: 245/255, blue: 245/255))
                             .cornerRadius(15).shadow(radius: 2)
                         }
                    }
                    .padding(.vertical)
                }
                .background(colorScheme == .dark ? Color(.systemBackground) : Color.white)

                // Floating Action Button
                 VStack {
                     Spacer()
                     HStack {
                         Spacer()
                         Button(action: { showingAddFoodOptions.toggle() }) {
                             Image(systemName: "plus").resizable().frame(width: 60, height: 60)
                                 .foregroundColor(.white)
                                 .background(Color(red: 67/255, green: 173/255, blue: 111/255))
                                 .clipShape(Circle()).shadow(radius: 4)
                         }
                         .padding()
                     }
                 }
                 .zIndex(1)


                // Add Food Options Menu
                if showingAddFoodOptions {
                     Color.black.opacity(0.5)
                         .edgesIgnoringSafeArea(.all)
                         .onTapGesture { showingAddFoodOptions = false }

                     VStack(spacing: 16) {
                         Button(action: { showingSearchView = true; scannedFoodName = nil }) { ActionButtonLabel(title: "Search Food", icon: "magnifyingglass") }
                         Button(action: { showingBarcodeScanner = true }) { ActionButtonLabel(title: "Scan Barcode", icon: "barcode.viewfinder") }
                         Button(action: { showingImagePicker = true }) { ActionButtonLabel(title: "Scan Food Image", icon: "camera") }
                         Button(action: { showingAddFoodView = true }) { ActionButtonLabel(title: "Add Food Manually", icon: "plus.circle") }
                     }
                     .padding()
                     .background(colorScheme == .dark ? Color(.secondarySystemBackground) : Color(red: 245/255, green: 245/255, blue: 245/255))
                     .cornerRadius(16).shadow(radius: 10)
                     .zIndex(2)
                 }

            } // <-- End of ZStack
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                 ToolbarItem(placement: .navigationBarLeading) { Text("MyFitPlate").font(.headline).foregroundColor(.primary.opacity(0.5)).padding(.leading, 5) }
                 ToolbarItem(placement: .navigationBarTrailing) {
                     Menu {
                         Button(action: { navigateToProfile = true }) { Label("Profile", systemImage: "person") }
                         Button(action: { showSettings = true }) { Label("Settings", systemImage: "gearshape") }
                     } label: { Image(systemName: "line.3.horizontal").font(.title2).foregroundColor(.gray) }
                 }
             }
             .background(
                 NavigationLink(destination: UserProfileView().environmentObject(dailyLogService).environmentObject(goalSettings), isActive: $navigateToProfile) { EmptyView() }.hidden()
             )
        } // <-- End of NavigationView
        .sheet(isPresented: $showingAddFoodView, onDismiss: {
             showingAddFoodOptions = false; fetchLogForSelectedDate()
         }) { AddFoodView { newFood in if let userID = Auth.auth().currentUser?.uid { dailyLogService.addFoodToCurrentLog(for: userID, foodItem: newFood, date: selectedDate) } } }
         .sheet(isPresented: $showingSearchView, onDismiss: {
             showingAddFoodOptions = false; scannedFoodName = nil; fetchLogForSelectedDate()
         }) {
             if let currentLog = dailyLogService.currentDailyLog {
                 FoodSearchView(dailyLog: .constant(currentLog), onLogUpdated: { updatedLog in dailyLogService.currentDailyLog = updatedLog; fetchLogForSelectedDate() }, initialSearchQuery: scannedFoodName ?? "")
             } else { ProgressView("Loading Log...").onAppear { fetchLogForSelectedDate() } }
         }
         .sheet(isPresented: $showingBarcodeScanner) { BarcodeScannerView { foodItem in DispatchQueue.main.async { scannedFoodName = foodItem.name; showingBarcodeScanner = false; DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { showingSearchView = true } } } }
         .sheet(isPresented: $showingImagePicker) { ImagePicker(sourceType: .camera) { image in DispatchQueue.main.async { mlModel.classifyImage(image: image) { result in switch result { case .success(let foodName): self.foodPrediction = "Predicted: \(foodName)"; self.scannedFoodName = foodName case .failure(let error): self.foodPrediction = "No food recognized: \(error.localizedDescription)"; self.scannedFoodName = nil }; self.showingImagePicker = false; if self.scannedFoodName != nil { self.showingSearchView = true } } } } }
        .onAppear { if !goalSettings.isUpdatingGoal, let userID = Auth.auth().currentUser?.uid { fetchInitialData(for: userID) } }
    } // <-- End of body

    // MARK: - Food Items List
    @ViewBuilder
    private func foodItemsList(items: [FoodItem]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if items.isEmpty { Text("No food items logged yet.").foregroundColor(.gray).font(.body).padding() }
            else {
                ForEach(items) { foodItem in
                    let index = items.firstIndex(of: foodItem) ?? 0
                    SwipeableFoodItemView(
                        foodItem: foodItem, index: index,
                        dailyLog: $dailyLogService.currentDailyLog,
                        onDelete: { idx in deleteFood(at: IndexSet(integer: idx), from: items) },
                        onLogUpdated: { updatedLog in dailyLogService.currentDailyLog = updatedLog },
                        date: selectedDate
                    )
                }
            }
        }
    }

    // MARK: - SwipeableFoodItemView
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
        @State private var showDetailView = false

        var body: some View {
            ZStack(alignment: .trailing) {
                 NavigationLink(destination: FoodDetailView(foodItem: foodItem, dailyLog: $dailyLog, date: date, onLogUpdated: onLogUpdated), isActive: $showDetailView)
                     { EmptyView() }.opacity(0)

                if isSwiped {
                    Button(action: { onDelete(index) }) {
                        Image(systemName: "trash").foregroundColor(.white).frame(width: 50, height: 40)
                            .background(Color.red).cornerRadius(8)
                    }
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                    .padding(.trailing, 8)
                }

                HStack {
                    Text(FoodEmojiMapper.getEmoji(for: foodItem.name) + " " + foodItem.name).lineLimit(1)
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                    Spacer()
                    Text("\(Int(foodItem.calories)) kcal").foregroundColor(.gray)
                }
                .padding(.vertical, 8).padding(.horizontal)
                .background(colorScheme == .dark ? Color(.tertiarySystemBackground) : Color(red: 245/255, green: 245/255, blue: 245/255).opacity(0.5))
                .cornerRadius(8).offset(x: offset)
                .onTapGesture { if !isSwiped { showDetailView = true } else { withAnimation { offset = 0; isSwiped = false } } }
                .gesture( DragGesture()
                        .onChanged { value in if value.translation.width < -5 { offset = max(value.translation.width, -70); isSwiped = offset <= -30 } else if value.translation.width > 5 && isSwiped { offset = -70 + value.translation.width } }
                        .onEnded { value in withAnimation(.easeInOut) { if value.translation.width < -50 { offset = -60; isSwiped = true } else { offset = 0; isSwiped = false } } }
                )
            }
            .contentShape(Rectangle())
        }
    }


    // MARK: - Helper Methods
    private func fetchInitialData(for userID: String) { goalSettings.loadUserGoals(userID: userID); fetchLogForSelectedDate() }
    private func fetchLogForSelectedDate() { guard let userID = Auth.auth().currentUser?.uid else { return }; dailyLogService.fetchLog(for: userID, date: selectedDate) { result in switch result { case .success(_): print("✅ Loaded log for \(self.selectedDateString)") case .failure(let error): print("❌ Error fetching log for \(self.selectedDateString): \(error.localizedDescription)") } } }
    private func deleteFood(at offsets: IndexSet, from currentItems: [FoodItem]) { guard let userID = Auth.auth().currentUser?.uid else { return }; offsets.forEach { index in guard index < currentItems.count else { print("⚠️ Delete index out of bounds"); return }; let foodItemToDelete = currentItems[index]; print("🔥 Deleting food item at index: \(index), ID: \(foodItemToDelete.id)"); dailyLogService.deleteFoodFromCurrentLog(for: userID, foodItemID: foodItemToDelete.id, date: selectedDate); DispatchQueue.main.async { self.refreshToggle.toggle(); print("🔍 Deletion processed for \(foodItemToDelete.id). Service will update log.") } } }
}

// MARK: - Dot Indicator
struct DotIndicator: View { /* ... remains the same ... */
    let isActive: Bool; let activeIndex: Int; let totalDots: Int = 2
    var body: some View { if isActive { HStack(spacing: 8) { ForEach(0..<totalDots, id: \.self) { index in Circle().frame(width: index == activeIndex ? 10 : 6, height: index == activeIndex ? 10 : 6).foregroundColor(index == activeIndex ? Color(red: 144/255, green: 190/255, blue: 109/255) : Color(red: 117/255, green: 117/255, blue: 117/255).opacity(0.5)) } } } else { EmptyView() } }
}

// MARK: - Action Button Label
struct ActionButtonLabel: View { /* ... remains the same ... */
    let title: String; let icon: String; @Environment(\.colorScheme) var colorScheme
    var body: some View { HStack { Image(systemName: icon).foregroundColor(Color(red: 144/255, green: 190/255, blue: 109/255)).frame(width: 24, height: 24); Text(title).foregroundColor(colorScheme == .dark ? .white : .black).font(.headline); Spacer() }.padding().background(colorScheme == .dark ? Color(.tertiarySystemBackground) : Color(red: 245/255, green: 245/255, blue: 245/255).opacity(0.5)).cornerRadius(12) }
}

// MARK: - FoodEmojiMapper
struct FoodEmojiMapper { /* ... remains the same ... */
    static let foodEmojiMap: [String: String] = [ "hotdog": "🌭", "hot dog": "🌭", "burger": "🍔", "hamburger": "🍔", "cheeseburger": "🍔", "pizza": "🍕", "taco": "🌮", "burrito": "🌯", "fries": "🍟", "sandwich": "🥪", "wrap": "🌯", "nachos": "🌮", "steak": "🥩", "chicken": "🍗", "fish": "🐟", "shrimp": "🍤", "prawn": "🍤", "egg": "🥚", "eggs": "🥚", "bacon": "🥓", "sausage": "🌭", "ham": "🥓", "pork": "🥓", "beef": "🥩", "lamb": "🍖", "turkey": "🍗", "oyster": "🐚", "caviar": "🐟", "rice": "🍚", "pasta": "🍝", "spaghetti": "🍝", "ravioli": "🍝", "bread": "🍞", "toast": "🍞", "noodles": "🍜", "ramen": "🍜", "pho": "🍜", "pad thai": "🍜", "bagel": "🥯", "croissant": "🥐", "pretzel": "🥨", "bun": "🥐", "roll": "🥐", "apple": "🍎", "banana": "🍌", "orange": "🍊", "grape": "🍇", "strawberry": "🍓", "watermelon": "🍉", "pear": "🍐", "cherry": "🍒", "mango": "🥭", "pineapple": "🍍", "peach": "🍑", "kiwi": "🥝", "lemon": "🍋", "lime": "🍋", "blueberry": "🫐", "raspberry": "🫐", "carrot": "🥕", "broccoli": "🥦", "tomato": "🍅", "potato": "🥔", "corn": "🌽", "lettuce": "🥬", "cucumber": "🥒", "onion": "🧅", "garlic": "🧄", "pepper": "🌶️", "mushroom": "🍄", "spinach": "🥬", "cabbage": "🥬", "zucchini": "🥒", "eggplant": "🍆", "cake": "🍰", "carrot cake": "🍰", "chocolate cake": "🍰", "red velvet cake": "🍰", "cheesecake": "🍰", "cookie": "🍪", "ice cream": "🍦", "donut": "🍩", "chocolate": "🍫", "candy": "🍬", "cupcake": "🧁", "pie": "🥧", "apple pie": "🥧", "pudding": "🍮", "bread pudding": "🍮", "panna cotta": "🍮", "waffle": "🧇", "pancake": "🥞", "coffee": "☕", "tea": "🍵", "juice": "🍹", "beer": "🍺", "wine": "🍷", "milk": "🥛", "cocktail": "🍸", "soda": "🥤", "water": "💧", "sushi": "🍣", "sashimi": "🍣", "sushi roll": "🍣", "curry": "🍛", "chicken curry": "🍛", "dumpling": "🥟", "gyoza": "🥟", "samosa": "🥟", "spring roll": "🥟", "egg roll": "🥟", "falafel": "🧆", "paella": "🍲", "tempura": "🍤", "cheese": "🧀", "grilled cheese": "🧀", "peanut": "🥜", "popcorn": "🍿", "lollipop": "🍭", "honey": "🍯", "jam": "🍇", "butter": "🧈", "oil": "🛢️", "soup": "🥣", "miso soup": "🥣", "french onion soup": "🥣", "hot and sour soup": "🥣", "clam chowder": "🥣", "lobster bisque": "🥣", "salad": "🥗", "greek salad": "🥗", "caesar salad": "🥗", "caprese salad": "🥗", "beet salad": "🥗", "fruit salad": "🥗", "stew": "🍲", "casserole": "🍲", "quesadilla": "🌮" ]
    static func getEmoji(for foodName: String) -> String { let lowercasedName = foodName.lowercased(); if let exactMatch = foodEmojiMap[lowercasedName] { return exactMatch }; if let containingMatch = foodEmojiMap.first(where: { lowercasedName.contains($0.key) }) { return containingMatch.value }; let words = lowercasedName.split(separator: " ").map { String($0) }; if let firstWord = words.first, let firstWordMatch = foodEmojiMap[firstWord] { return firstWordMatch }; return "🍽️" }
}

// MARK: - HomeView Preview
//struct HomeView_Previews: PreviewProvider {
//    @State static var navigateToProfile = false
//    @State static var showSettings = false
//
//    static var previews: some View {
//        HomeView(
//            navigateToProfile: $navigateToProfile,
//            showSettings: $showSettings
//        )
//        .environmentObject(GoalSettings())         // ✅ Provide dummy GoalSettings
//        .environmentObject(DailyLogService()) // ✅ Provide dummy DailyLogService
//    }
//}
