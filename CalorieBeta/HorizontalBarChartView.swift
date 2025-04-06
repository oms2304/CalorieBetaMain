import SwiftUI
import Charts

// This view displays a horizontal bar chart to visualize the user's nutritional progress
// (calories and macros) compared to their goals, using the Charts framework.
struct HorizontalBarChartView: View {
    // The daily log containing the user's food intake data.
    var dailyLog: DailyLog
    // Observed object to access and react to changes in the user's goal settings.
    @ObservedObject var goal: GoalSettings

    // The main body of the view, rendering a chart or a loading state.
    var body: some View {
        // Checks if the calorie goal is available before rendering the chart.
        if let caloriesGoal = goal.calories {
            // Calculates total consumed values and percentages relative to goals.
            let totalCalories = max(0, dailyLog.totalCalories()) // Ensures non-negative calorie total.
            let totalMacros = dailyLog.totalMacros() // Retrieves total macros from the log.
            let protein = max(0, totalMacros.protein) // Ensures non-negative protein.
            let fats = max(0, totalMacros.fats) // Ensures non-negative fats.
            let carbs = max(0, totalMacros.carbs) // Ensures non-negative carbs.

            let proteinGoal = goal.protein // Goal protein in grams.
            let fatsGoal = goal.fats // Goal fats in grams.
            let carbsGoal = goal.carbs // Goal carbs in grams.

            // Calculates the progress percentage for each nutrient as a percentage (0 to 100).
            let caloriesPercentage = (caloriesGoal > 0) ? min((totalCalories / max(caloriesGoal, 1)) * 100, 100) : 0
            let proteinPercentage = (proteinGoal > 0) ? min((protein / max(proteinGoal, 1)) * 100, 100) : 0
            let fatsPercentage = (fatsGoal > 0) ? min((fats / max(fatsGoal, 1)) * 100, 100) : 0
            let carbsPercentage = (carbsGoal > 0) ? min((carbs / max(carbsGoal, 1)) * 100, 100) : 0

            // Creates the chart using the Charts framework.
            Chart {
                // Bar for calories progress.
                BarMark(
                    x: .value("Calories", caloriesPercentage), // X-axis: percentage of goal.
                    y: .value("Type", "Calories") // Y-axis: category label.
                )
                .foregroundStyle(.red) // Red color for calories.
                .annotation(position: .trailing) { // Adds a label showing current vs. goal.
                    Text("\(Int(totalCalories)) / \(Int(caloriesGoal)) kcal")
                        .font(.caption) // Small font for the label.
                }

                // Bar for protein progress.
                BarMark(
                    x: .value("Protein", proteinPercentage),
                    y: .value("Type", "Protein")
                )
                .foregroundStyle(.blue) // Blue color for protein.
                .annotation(position: .trailing) {
                    Text("\(String(format: "%.1f", protein)) / \(String(format: "%.1f", proteinGoal))g")
                        .font(.caption)
                }

                // Bar for fats progress.
                BarMark(
                    x: .value("Fats", fatsPercentage),
                    y: .value("Type", "Fats")
                )
                .foregroundStyle(.green) // Green color for fats.
                .annotation(position: .trailing) {
                    Text("\(String(format: "%.1f", fats)) / \(String(format: "%.1f", fatsGoal))g")
                        .font(.caption)
                }

                // Bar for carbs progress.
                BarMark(
                    x: .value("Carbs", carbsPercentage),
                    y: .value("Type", "Carbs")
                )
                .foregroundStyle(.orange) // Orange color for carbs.
                .annotation(position: .trailing) {
                    Text("\(String(format: "%.1f", carbs)) / \(String(format: "%.1f", carbsGoal))g")
                        .font(.caption)
                }
            }
            .chartXAxis { AxisMarks(position: .bottom) } // Places X-axis labels at the bottom.
            .chartYAxis { AxisMarks(position: .leading) } // Places Y-axis labels on the left.
            .chartXScale(domain: 0...100) // Sets the X-axis range from 0 to 100%.
            .frame(maxHeight: 250) // Limits the maximum height of the chart.
            .padding() // Adds padding around the chart.
        } else {
            // Displays a loading message if the calorie goal is not yet loaded.
            Text("Loading data...")
                .foregroundColor(.gray) // Gray text for the placeholder.
                .frame(maxHeight: 250) // Matches the chart's height for consistency.
                .padding() // Adds padding.
        }
    }
}
