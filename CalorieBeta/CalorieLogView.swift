import SwiftUI
import FirebaseFirestore

// This view displays a log of the user's daily calorie intake, including meals and food items.
// It allows adding new food items and shows a total calorie count.
struct CalorieLogView: View {
    // State to manage the daily log data, initialized with today's date and an empty meal list.
    @State private var dailyLog = DailyLog(
        date: Date(), // Sets the log date to the current date.
        meals: [], // Starts with no meals.
        totalCaloriesOverride: nil // No manual override for total calories initially.
    )
    
    // State to control the visibility of the sheet for adding new food items.
    @State private var showAddFoodSheet = false

    // The main body of the view, wrapped in a NavigationView for title and navigation.
    var body: some View {
        NavigationView {
            VStack {
                // Displays the total calorie count for the day, calculated by the dailyLog.
                Text("Total Calories: \(dailyLog.totalCalories()) kcal")
                    .font(.title) // Large, bold font for emphasis.
                    .padding() // Adds space around the text.

                // A list to display all meals and their food items in sections.
                List {
                    ForEach(dailyLog.meals) { meal in
                        // Each meal is a section with a header showing the meal name.
                        Section(header: Text(meal.name)) {
                            ForEach(meal.foodItems) { food in
                                // Vertical stack to display food item details.
                                VStack(alignment: .leading) {
                                    Text(food.name) // The name of the food item.
                                        .font(.headline) // Bold font for the food name.
                                    
                                    // Detailed nutritional info for the food item.
                                    Text("\(food.calories, specifier: "%.1f") kcal • Protein: \(food.protein, specifier: "%.1f")g • Carbs: \(food.carbs, specifier: "%.1f")g • Fats: \(food.fats, specifier: "%.1f")g")
                                        .font(.subheadline) // Smaller font for details.
                                        .foregroundColor(.gray) // Gray color for secondary text.
                                }
                            }
                        }
                    }
                }

                Spacer() // Pushes the button to the bottom of the screen.

                // Button to trigger the addition of a new food item.
                Button(action: {
                    showAddFoodSheet = true // Shows the sheet when tapped.
                }) {
                    Text("Add Food")
                        .font(.title2) // Slightly larger font for the button text.
                        .frame(maxWidth: .infinity) // Expands the button to full width.
                        .padding() // Adds internal padding.
                        .background(Color.green) // Green background for visibility.
                        .foregroundColor(.white) // White text for contrast.
                        .cornerRadius(10) // Rounded corners for a modern look.
                        .padding(.horizontal) // Horizontal padding from screen edges.
                }
                // Presents a sheet with the AddFoodView when showAddFoodSheet is true.
                .sheet(isPresented: $showAddFoodSheet) {
                    AddFoodView { newFood in
                        // Callback to add the new food item to the log.
                        addFoodToLog(newFood)
                    }
                }
            }
            .navigationTitle("Calorie Log") // Sets the title displayed at the top.
        }
    }

    // Function to add a new food item to the daily log.
    private func addFoodToLog(_ newFood: FoodItem) {
        // Check if there’s an existing meal with food items to append to.
        if let firstMealIndex = dailyLog.meals.firstIndex(where: { !$0.foodItems.isEmpty }) {
            // If found, append the new food to the first non-empty meal.
            dailyLog.meals[firstMealIndex].foodItems.append(newFood)
        } else {
            // If no meal exists, create a new meal with the food item.
            let newMeal = Meal(id: UUID().uuidString, name: "All Meals", foodItems: [newFood])
            dailyLog.meals.append(newMeal)
        }
    }
}
