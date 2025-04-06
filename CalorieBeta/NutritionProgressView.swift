import SwiftUI
import Charts

// This view displays the user's nutritional progress (calories and macros) compared to their goals.
// It offers two visualization modes: bubbles and a horizontal bar chart, toggleable via swipe gestures.
struct NutritionProgressView: View {
    // The daily log containing the user's food intake data.
    var dailyLog: DailyLog
    // Observed object to access and react to changes in the user's goal settings.
    @ObservedObject var goal: GoalSettings

    // State variables to manage the view's behavior:
    @GestureState private var dragOffset: CGFloat = 0 // Tracks the horizontal offset during swipe gestures.
    private let swipeThreshold: CGFloat = 50 // Minimum swipe distance required to toggle views.

    // The main body of the view, using a ZStack to layer the visualization options.
    var body: some View {
        // Calculates total consumed values and percentages relative to goals.
        let totalCalories = max(0, dailyLog.totalCalories()) // Ensures non-negative calorie total.
        let totalMacros = dailyLog.totalMacros() // Retrieves total macros from the log.
        let protein = max(0, totalMacros.protein) // Ensures non-negative protein.
        let fats = max(0, totalMacros.fats) // Ensures non-negative fats.
        let carbs = max(0, totalMacros.carbs) // Ensures non-negative carbs.

        let caloriesGoal = goal.calories ?? 0 // Goal calories, defaults to 0 if nil.
        let proteinGoal = goal.protein // Goal protein in grams.
        let fatsGoal = goal.fats // Goal fats in grams.
        let carbsGoal = goal.carbs // Goal carbs in grams.

        // Calculates the progress percentage for each nutrient, capped at 100%.
        let caloriesPercentage = (caloriesGoal > 0) ? min(totalCalories / max(caloriesGoal, 1), 1.0) : 0
        let proteinPercentage = (proteinGoal > 0) ? min(protein / max(proteinGoal, 1), 1.0) : 0
        let fatsPercentage = (fatsGoal > 0) ? min(fats / max(fatsGoal, 1), 1.0) : 0
        let carbsPercentage = (carbsGoal > 0) ? min(carbs / max(carbsGoal, 1), 1.0) : 0

        ZStack {
            // Displays either the bubbles view or bar chart based on the state.
            if goal.showingBubbles {
                bubblesView(
                    calories: totalCalories, caloriesGoal: caloriesGoal, caloriesPercentage: caloriesPercentage,
                    protein: protein, proteinGoal: proteinGoal, proteinPercentage: proteinPercentage,
                    fats: fats, fatsGoal: fatsGoal, fatsPercentage: fatsPercentage,
                    carbs: carbs, carbsGoal: carbsGoal, carbsPercentage: carbsPercentage
                )
            } else {
                HorizontalBarChartView(dailyLog: dailyLog, goal: goal) // Assumed custom chart view.
            }
        }
        .frame(maxHeight: 250) // Limits the maximum height of the view.
        .padding() // Adds padding around the content.
        .offset(x: dragOffset) // Applies the swipe offset for animation.
        .gesture(
            // Handles swipe gestures to toggle between views.
            DragGesture()
                .updating($dragOffset) { value, state, _ in
                    state = value.translation.width // Updates the offset as the user drags.
                }
                .onEnded { value in
                    if abs(value.translation.width) > swipeThreshold { // Checks if swipe exceeds threshold.
                        withAnimation(.easeInOut(duration: 0.3)) { // Animates the transition.
                            goal.showingBubbles.toggle() // Switches between bubbles and bar chart.
                        }
                    }
                }
        )
    }

    // A view builder to create the bubbles visualization for nutritional progress.
    @ViewBuilder
    private func bubblesView(
        calories: Double, caloriesGoal: Double, caloriesPercentage: Double,
        protein: Double, proteinGoal: Double, proteinPercentage: Double,
        fats: Double, fatsGoal: Double, fatsPercentage: Double,
        carbs: Double, carbsGoal: Double, carbsPercentage: Double
    ) -> some View {
        HStack(spacing: 20) { // Horizontal stack with spacing between bubbles.
            ProgressBubble(
                value: calories,
                goal: caloriesGoal,
                percentage: caloriesPercentage,
                label: "Calories",
                unit: "kcal",
                color: .red
            )

            ProgressBubble(
                value: protein,
                goal: proteinGoal,
                percentage: proteinPercentage,
                label: "Protein",
                unit: "g",
                color: .blue
            )

            ProgressBubble(
                value: fats,
                goal: fatsGoal,
                percentage: fatsPercentage,
                label: "Fats",
                unit: "g",
                color: .green
            )

            ProgressBubble(
                value: carbs,
                goal: carbsGoal,
                percentage: carbsPercentage,
                label: "Carbs",
                unit: "g",
                color: .orange
            )
        }
    }
}

// A custom view to display a single progress bubble for a nutrient.
struct ProgressBubble: View {
    // Parameters to define the bubble's content and appearance.
    let value: Double // Current value of the nutrient.
    let goal: Double // Target goal for the nutrient.
    let percentage: Double // Progress as a fraction (0 to 1).
    let label: String // Label for the nutrient (e.g., "Calories").
    let unit: String // Unit of measurement (e.g., "kcal", "g").
    let color: Color // Color to represent the nutrient.

    var body: some View {
        VStack { // Vertical stack to align the circle and label.
            ZStack { // Layers the circle and text for the progress display.
                Circle() // Outer circle for the background.
                    .stroke(lineWidth: 8) // Thick stroke for visibility.
                    .opacity(0.2) // Faint background.
                    .foregroundColor(color) // Matches the nutrient color.

                Circle() // Inner circle to show progress.
                    .trim(from: 0, to: CGFloat(percentage)) // Fills based on percentage.
                    .stroke(lineWidth: 8) // Thick stroke.
                    .foregroundColor(color) // Matches the nutrient color.
                    .rotationEffect(.degrees(-90)) // Starts the fill from the top.

                VStack { // Centers the text inside the circle.
                    Text("\(String(format: "%.0f", value))") // Displays the current value.
                        .font(.headline) // Bold, larger font.
                    Text("/ \(String(format: "%.0f", goal)) \(unit)") // Shows goal with unit.
                        .font(.caption) // Smaller font.
                        .foregroundColor(.gray) // Gray for contrast.
                }
            }
            .frame(width: 80, height: 80) // Fixed size for the circle.

            Text(label) // Label below the circle.
                .font(.caption) // Smaller font.
                .foregroundColor(.primary) // Default text color.
        }
    }
}
