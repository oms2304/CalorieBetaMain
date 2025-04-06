import SwiftUI
import FirebaseFirestore

// This view displays a log of meals and their associated food items, showing nutritional details.
// It is designed to be reusable and is typically used to present a summary of consumed food.
struct FoodLogView: View {
    // An array of Meal objects passed to the view to display their food items.
    var meals: [Meal]

    // The main body of the view, organized as a List for a scrollable meal summary.
    var body: some View {
        List {
            // Loops through each meal in the meals array to create a section.
            ForEach(meals) { meal in
                Section(header: Text(meal.name)) {
                    // Loops through each food item in the meal, using the name as a unique identifier.
                    ForEach(meal.foodItems, id: \.name) { item in
                        HStack {
                            // Vertical stack to align food details on the left.
                            VStack(alignment: .leading) {
                                Text(item.name) // Displays the name of the food item.
                                    .font(.headline) // Bold, larger font for emphasis.
                                Text("\(item.calories, specifier: "%.1f") kcal") // Shows calorie count with one decimal.
                                    .font(.subheadline) // Smaller font for secondary info.
                                    .foregroundColor(.gray) // Gray color for contrast.
                            }
                            Spacer() // Pushes the nutritional info to the right.
                            // Displays protein, fats, and carbs in a horizontal layout.
                            Text("Protein: \(String(format: "%.1f", item.protein))g") // Protein in grams.
                            Text("Fats: \(String(format: "%.1f", item.fats))g") // Fats in grams.
                            Text("Carbs: \(String(format: "%.1f", item.carbs))g") // Carbs in grams.
                        }
                    }
                }
            }
        }
        .listStyle(InsetGroupedListStyle()) // Applies a styled list appearance with inset grouping.
    }
}
