import SwiftUI
import FirebaseAuth

struct MealPlannerView: View {
    @EnvironmentObject var mealPlannerService: MealPlannerService
    @EnvironmentObject var goalSettings: GoalSettings
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var spotlightManager: SpotlightManager
<<<<<<< HEAD
    @Environment(\.colorScheme) var colorScheme
=======
>>>>>>> 5424a6b (Recreated the reports page with more polished UI)
    
    @State private var selectedDate: Date = Calendar.current.startOfDay(for: Date())
    @State private var planForSelectedDate: MealPlanDay?
    @State private var isLoading = false
    @State private var showingGroceryList = false
    @State private var showingMealPlanSurvey = false
    
    @State private var tourSpotlightIDs: [String] = []
    @State private var currentSpotlightIndex: Int = 0
    @State private var showingSpotlightTour = false
<<<<<<< HEAD

    @Namespace private var animationNamespace
//    let today = calendar.startOfDay(for: Date())
    let calendar = Calendar.current
    var dates: [Date] {
        let today = calendar.startOfDay(for: Date())
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: today) }
        
    }

    
    
=======
>>>>>>> 5424a6b (Recreated the reports page with more polished UI)
    
    private let spotlightOrder = ["weekView", "planContent", "toolbarActions"]
    private let spotlightContent: [String: (title: String, text: String)] = [
        "weekView": ("Select a Day", "Tap any day of the week to view or manage your meal plan for that specific date."),
        "planContent": ("Your Daily Plan", "Once a meal plan is generated, your meals for the selected day will appear here."),
        "toolbarActions": ("Meal Plan Tools", "Use the toolbar buttons to manage your plan. Tap ✨ to generate a new 7-day plan, or tap 📋 to see your grocery list.")
    ]

<<<<<<< HEAD

=======
>>>>>>> 5424a6b (Recreated the reports page with more polished UI)
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                WeekView(selectedDate: $selectedDate)
                    .padding(.vertical, 10)
<<<<<<< HEAD
//
                    .background(colorScheme == .dark ? Color(UIColor.systemGray).opacity(0.2) : Color(UIColor.systemGray6))
//                    .padding()
                    .cornerRadius(20)
                    .padding(.horizontal, 15)
               
                    .padding(.vertical, 15)
                    .featureSpotlight(isActive: isSpotlightActive(for: "weekView"))
                    .id("weekView")
                    .onChange(of: selectedDate) {
                        for date in dates {
                            fetchWeekPlan(for: date)
                        }
                    }
//                    .onAppear { fetchWeekPlan(for: dates) }
//
                
                TabView(selection: $selectedDate){
                    
                    ForEach(dates, id: \.self) { date in
                        VStack{
                               if isLoading {
                                   Spacer()
                                   ProgressView("Loading Plan...")
                                   Spacer()
                               } else if let plan = planForSelectedDate, !plan.meals.isEmpty {
                                   List {
                                       ForEach(plan.meals) { meal in
                                           mealSection(for: meal)
                                       }
                                   }
                                   .listStyle(InsetGroupedListStyle())
                                   .featureSpotlight(isActive: isSpotlightActive(for: "planContent"))
//                                   .id("planContent")
                               } else {
                                   Spacer()
                                   Text("No plan found for this day.").appFont(size: 17)
                                       .foregroundColor(Color(UIColor.secondaryLabel))
                                   Button("Generate New Meal Plan") {
                                       showingMealPlanSurvey = true
                                   }
                                   .buttonStyle(PrimaryButtonStyle())
                                   .padding()
                                   Spacer()
                                   .featureSpotlight(isActive: isSpotlightActive(for: "planContent"))
//                                   .id("planContent")
                               }
                           }
                        .tag(date)
                    }
//                    .tabItem(item)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            
            .background(Color.backgroundPrimary)
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("Meal Plan")
//            .tint(colorScheme == .dark ? Color.black.opacity(0.4) : Color(UIColor.systemGray6))
=======
                    .background(Color.backgroundSecondary)
                    .featureSpotlight(isActive: isSpotlightActive(for: "weekView"))
                    .id("weekView")
                    .onChange(of: selectedDate) { _ in fetchPlan() }

                if isLoading {
                    Spacer()
                    ProgressView("Loading Plan...")
                    Spacer()
                } else if let plan = planForSelectedDate, !plan.meals.isEmpty {
                    List {
                        Text("Plan for \(selectedDate, formatter: DateFormatter.longDate)")
                            .appFont(size: 17, weight: .semibold)
                            .listRowBackground(Color.clear)
                            .padding(.bottom, 5)

                        ForEach(plan.meals) { meal in
                            mealSection(for: meal)
                        }
                    }
                    .listStyle(InsetGroupedListStyle())
                    .featureSpotlight(isActive: isSpotlightActive(for: "planContent"))
                    .id("planContent")
                } else {
                    Spacer()
                    Text("No plan found for this day.").appFont(size: 17)
                        .foregroundColor(Color(UIColor.secondaryLabel))
                    Button("Generate New Meal Plan") {
                        showingMealPlanSurvey = true
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .padding()
                    Spacer()
                    .featureSpotlight(isActive: isSpotlightActive(for: "planContent"))
                    .id("planContent")
                }
            }
            .background(Color.backgroundPrimary)
            .navigationTitle("Meal Plan")
            .tint(.brandPrimary)
>>>>>>> 5424a6b (Recreated the reports page with more polished UI)
            .sheet(isPresented: $showingGroceryList) {
                NavigationView {
                    GroceryListView()
                }
            }
            .sheet(isPresented: $showingMealPlanSurvey) {
                MealPlanSurveyView()
            }
            .onAppear(perform: onMealPlanAppear)
            
            if showingSpotlightTour {
                Color.black.opacity(0.5).ignoresSafeArea()
                    .onTapGesture(perform: advanceTour)
                    .transition(.opacity)

                if !tourSpotlightIDs.isEmpty && currentSpotlightIndex < tourSpotlightIDs.count {
                    let currentID = tourSpotlightIDs[currentSpotlightIndex]
                    if let content = spotlightContent[currentID] {
                        SpotlightTextView(
                            content: content,
                            currentIndex: currentSpotlightIndex,
                            total: tourSpotlightIDs.count,
                            position: .bottom,
                            onNext: advanceTour
                        )
                    }
                }
            }
        }
      
<<<<<<< HEAD
=======

>>>>>>> 5424a6b (Recreated the reports page with more polished UI)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { showingGroceryList = true }) {
                    Image(systemName: "list.bullet.clipboard")
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingMealPlanSurvey = true }) {
                    Image(systemName: "wand.and.stars") 
                }
            }
        }
    }
    
    private func onMealPlanAppear() {
        fetchPlan()
        
        let needed = spotlightOrder.filter { !spotlightManager.isShown(id: $0) }
        if !needed.isEmpty {
            self.tourSpotlightIDs = needed
            self.currentSpotlightIndex = 0
            withAnimation {
                self.showingSpotlightTour = true
            }
        }
    }
    
    private func isSpotlightActive(for id: String) -> Bool {
        guard showingSpotlightTour, !tourSpotlightIDs.isEmpty, currentSpotlightIndex < tourSpotlightIDs.count else {
             return false
        }
        return tourSpotlightIDs[currentSpotlightIndex] == id
    }
    
    private func advanceTour() {
        if currentSpotlightIndex < tourSpotlightIDs.count - 1 {
            withAnimation {
                currentSpotlightIndex += 1
            }
        } else {
            finishTour()
        }
    }
    
    private func finishTour() {
        withAnimation {
            showingSpotlightTour = false
        }
        tourSpotlightIDs.forEach { spotlightManager.markAsShown(id: $0) }
    }
    
    @ViewBuilder
    private func mealSection(for meal: PlannedMeal) -> some View {
<<<<<<< HEAD
        Section(header: HStack {
            Text(meal.mealType)
            Spacer()
            Text("Calories: \(Int(meal.foodItem!.calories))")
                .appFont(size:14, weight:.semibold)
                .foregroundColor(Color.brandPrimary)
        }) {
            VStack{
                Text(meal.foodItem?.name ?? "Unnamed Meal").appFont(size: 17, weight: .semibold)
//                    .padding(.leading, -15)/
              
            }
            
                
            if let ingredients = meal.ingredients, !ingredients.isEmpty, let instructions = meal.instructions, !instructions.isEmpty {
                DisclosureGroup("Recipe") {
                    ForEach(ingredients, id: \.self) { ingredient in
                        Text("\(ingredient)").appFont(size: 15)
                    }
                    
                    Text(instructions).appFont(size: 15)
                }
            }
//            if let ingredients = meal.ingredients, !ingredients.isEmpty {
//                
//            }
//            
//            if let instructions = meal.instructions, !instructions.isEmpty {
//                DisclosureGroup("Instructions") {
//                    
//                }
//            }
=======
        Section(header: Text(meal.mealType)) {
            Text(meal.foodItem?.name ?? "Unnamed Meal").appFont(size: 17, weight: .semibold)
            
            if let ingredients = meal.ingredients, !ingredients.isEmpty {
                ForEach(ingredients, id: \.self) { ingredient in
                    Text("• \(ingredient)").appFont(size: 15)
                }
            }
            
            if let instructions = meal.instructions, !instructions.isEmpty {
                DisclosureGroup("Instructions") {
                    Text(instructions).appFont(size: 15)
                }
            }
>>>>>>> 5424a6b (Recreated the reports page with more polished UI)
            
            Button(action: { log(meal: meal) }) {
                Label("Log with AI Assistant", systemImage: "plus.bubble.fill")
            }
            .buttonStyle(.borderless)
            .foregroundColor(.brandPrimary)
        }
    }
    
<<<<<<< HEAD
    private func fetchWeekPlan(for date: Date) {
        isLoading = true
        guard let userID = Auth.auth().currentUser?.uid else { isLoading = false; return }
        Task {
                self.planForSelectedDate = await mealPlannerService.fetchPlan(for: date, userID: userID)
                self.isLoading = false
        }
    }
    
    private func fetchPlan()  {
=======
    private func fetchPlan() {
>>>>>>> 5424a6b (Recreated the reports page with more polished UI)
        isLoading = true
        guard let userID = Auth.auth().currentUser?.uid else { isLoading = false; return }
        Task {
            self.planForSelectedDate = await mealPlannerService.fetchPlan(for: selectedDate, userID: userID)
            self.isLoading = false
        }
<<<<<<< HEAD
      
=======
>>>>>>> 5424a6b (Recreated the reports page with more polished UI)
    }
    
    private func log(meal: PlannedMeal) {
        guard let ingredients = meal.ingredients, !ingredients.isEmpty else { return }
        
        let ingredientListString = ingredients.joined(separator: "\n- ")
        let prompt = """
        Calculate the nutritional breakdown for a recipe with these ingredients. Do not ask for confirmation; provide the breakdown directly in the specified format.

        Ingredients:
        - \(ingredientListString)
        
        Your response MUST be in the following format:
        ---Nutritional Breakdown---
        Calories: [Number]
        Protein: [Number]g
        Carbs: [Number]g
        Fats: [Number]g
        """
        
        appState.pendingChatPrompt = prompt
        appState.selectedTab = 1
    }
}

struct WeekView: View {
    @Binding var selectedDate: Date
    @Namespace private var animationNamespace
    let calendar = Calendar.current
    var body: some View {
        let today = calendar.startOfDay(for: Date())
        let dates = (0..<7).map { calendar.date(byAdding: .day, value: $0, to: today)! }
<<<<<<< HEAD
        
        let now = Date()
//        let calendar = Calendar.current
        let day = String(Calendar.current.component(.day, from: now))
    
        HStack {
            ForEach(dates, id: \.self) { date in
                VStack {
                    VStack(spacing: 8) {
                        if (dayOfMonth(for: date) == day) {
                            Text(dayOfWeek(for: date)).appFont(size: 12).foregroundColor(calendar.isDate(date, inSameDayAs: selectedDate) ? .brandPrimary : Color(UIColor.secondaryLabel))
//                                .padding(.bottom, 10)
                            
                        } else {
                            Text(dayOfWeek(for: date)).appFont(size: 12).foregroundColor(calendar.isDate(date, inSameDayAs: selectedDate) ? .brandPrimary : Color(UIColor.secondaryLabel))                        }
                            
//                        Spacer(minLength: 10)
            
                        if (dayOfMonth(for: date) == day) {
                            Text(dayOfMonth(for: date)).appFont(size: 17, weight: .semibold).padding(10)
                                .background( Group { if calendar.isDate(date, inSameDayAs: selectedDate) { Circle().fill(Color.brandPrimary).matchedGeometryEffect(id: "selectedDay", in: animationNamespace) } else { Circle().fill(Color.clear) } } )
                                .foregroundColor(calendar.isDate(date, inSameDayAs: selectedDate) ? .white : .textPrimary)
                                .padding(.top, -1)
                                .padding(.bottom, -5)
                            
                        } else {
                            Text(dayOfMonth(for: date)).appFont(size: 17, weight: .semibold).padding(10)
                                .background( Group { if calendar.isDate(date, inSameDayAs: selectedDate) { Circle().fill(Color.brandPrimary).matchedGeometryEffect(id: "selectedDay", in: animationNamespace) } else { Circle().fill(Color.clear) } } )
                                .foregroundColor(calendar.isDate(date, inSameDayAs: selectedDate) ? .white : .textPrimary)
                                .padding(.bottom, 3)
                        }
  
                    }
                    .frame(maxWidth: .infinity, maxHeight: 70)
                    .onTapGesture { withAnimation(.spring()) { selectedDate = date } }
                    
                    
                    if (dayOfMonth(for: date) == day) {
                       Circle()
                            .frame(width: 5, height: 5)
                            .foregroundColor(.green)
                            .padding(.bottom, -5)
                            .padding(.top, -5)
                    }
                }
=======
        HStack {
            ForEach(dates, id: \.self) { date in
                VStack(spacing: 8) {
                    Text(dayOfWeek(for: date)).appFont(size: 12).foregroundColor(calendar.isDate(date, inSameDayAs: selectedDate) ? .brandPrimary : Color(UIColor.secondaryLabel))
                    Text(dayOfMonth(for: date)).appFont(size: 17, weight: .semibold).padding(10)
                        .background( Group { if calendar.isDate(date, inSameDayAs: selectedDate) { Circle().fill(Color.brandPrimary).matchedGeometryEffect(id: "selectedDay", in: animationNamespace) } else { Circle().fill(Color.clear) } } )
                        .foregroundColor(calendar.isDate(date, inSameDayAs: selectedDate) ? .white : .textPrimary)
                }
                .frame(maxWidth: .infinity)
                .onTapGesture { withAnimation(.spring()) { selectedDate = date } }
>>>>>>> 5424a6b (Recreated the reports page with more polished UI)
            }
        }
        .padding(.horizontal)
    }
    private func dayOfWeek(for date: Date) -> String { let formatter = DateFormatter(); formatter.dateFormat = "EEE"; return formatter.string(from: date) }
    private func dayOfMonth(for date: Date) -> String { let formatter = DateFormatter(); formatter.dateFormat = "d"; return formatter.string(from: date) }
}

fileprivate extension DateFormatter {
    static var longDate: DateFormatter { let formatter = DateFormatter(); formatter.dateStyle = .long; return formatter }
}
<<<<<<< HEAD

#Preview {
    NavigationView {
        MealPlannerView()
            .environmentObject(MealPlannerService(recipeService: RecipeService()))
            .environmentObject(GoalSettings())
            .environmentObject(AppState())
            .environmentObject(SpotlightManager())
    }
}
=======
>>>>>>> 5424a6b (Recreated the reports page with more polished UI)
