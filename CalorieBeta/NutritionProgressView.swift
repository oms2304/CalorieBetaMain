import SwiftUI
import Charts

// Displays the user's nutritional progress (calories and macros) compared to their goals.
// Supports two views: bubbles and horizontal bar chart, toggleable via swipe or tap on the dot indicator.
struct NutritionProgressView: View {
    // Daily log containing the user's food intake data.
    var dailyLog: DailyLog
    // Observed object for accessing and updating goal settings (e.g., calorie goals).
    @ObservedObject var goal: GoalSettings
    // Detects the current color scheme (light or dark) to adapt UI elements.
    @Environment(\.colorScheme) var colorScheme

    // State for handling swipe gestures to toggle between views.
    @GestureState private var dragOffset: CGFloat = 0
    private let swipeThreshold: CGFloat = 50

    var body: some View {
        let totalCalories = max(0, dailyLog.totalCalories())
        let totalMacros = dailyLog.totalMacros()
        let protein = max(0, totalMacros.protein)
        let fats = max(0, totalMacros.fats)
        let carbs = max(0, totalMacros.carbs)

        let caloriesGoal = goal.calories ?? 0
        let proteinGoal = goal.protein
        let fatsGoal = goal.fats
        let carbsGoal = goal.carbs

        let caloriesPercentage = (caloriesGoal > 0) ? min(totalCalories / max(caloriesGoal, 1), 1.0) : 0
        let proteinPercentage = (proteinGoal > 0) ? min(protein / max(proteinGoal, 1), 1.0) : 0
        let fatsPercentage = (fatsGoal > 0) ? min(fats / max(fatsGoal, 1), 1.0) : 0
        let carbsPercentage = (carbsGoal > 0) ? min(carbs / max(carbsGoal, 1), 1.0) : 0

        ZStack {
            if goal.showingBubbles {
                bubblesView(
                    calories: totalCalories, caloriesGoal: caloriesGoal, caloriesPercentage: caloriesPercentage,
                    protein: protein, proteinGoal: proteinGoal, proteinPercentage: proteinPercentage,
                    fats: fats, fatsGoal: fatsGoal, fatsPercentage: fatsPercentage,
                    carbs: carbs, carbsGoal: carbsGoal, carbsPercentage: carbsPercentage
                )
            } else {
                HorizontalBarChartView(dailyLog: dailyLog, goal: goal)
            }
        }
        .frame(maxHeight: 180)
        .padding(.horizontal, 8)
        .offset(x: dragOffset)
        .gesture(
            DragGesture()
                .updating($dragOffset) { value, state, _ in
                    state = value.translation.width
                }
                .onEnded { value in
                    if abs(value.translation.width) > swipeThreshold {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            goal.showingBubbles.toggle()
                        }
                    }
                }
        )
    }

    @ViewBuilder
    private func bubblesView(
        calories: Double, caloriesGoal: Double, caloriesPercentage: Double,
        protein: Double, proteinGoal: Double, proteinPercentage: Double,
        fats: Double, fatsGoal: Double, fatsPercentage: Double,
        carbs: Double, carbsGoal: Double, carbsPercentage: Double
    ) -> some View {
        HStack(spacing: 15) {
            ProgressBubble(
                value: calories,
                goal: caloriesGoal,
                percentage: caloriesPercentage,
                label: "Calories",
                unit: "cal",
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
        .padding(.horizontal, 8)
    }
}

struct ProgressBubble: View {
    let value: Double
    let goal: Double
    let percentage: Double
    let label: String
    let unit: String
    let color: Color
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack {
            ZStack {
                Circle()
                    .stroke(lineWidth: 6)
                    .opacity(0.2)
                    .foregroundColor(color)

                Circle()
                    .trim(from: 0, to: CGFloat(percentage))
                    .stroke(lineWidth: 6)
                    .foregroundColor(color)
                    .rotationEffect(.degrees(-90))

                VStack {
                    Text("\(String(format: "%.0f", value))")
                        .font(.subheadline)
                        .foregroundColor(colorScheme == .dark ? .white : .black) // Dynamic text color.
                    Text("/ \(String(format: "%.0f", goal)) \(unit)")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
            .frame(width: 70, height: 70)

            Text(label)
                .font(.caption2)
                .foregroundColor(colorScheme == .dark ? .white : .black) // Dynamic text color.
        }
    }
}
