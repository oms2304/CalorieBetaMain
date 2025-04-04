


import SwiftUI
import FirebaseFirestore

struct DailyGoalsView: View {
    @EnvironmentObject var goalSettings: GoalSettings // Use EnvironmentObject instead of ObservedObject

    @State private var calories = ""
    @State private var protein = ""
    @State private var fats = ""
    @State private var carbs = ""

    @Environment(\.dismiss) var dismiss

    var body: some View {
        Form {
            Section(header: Text("Daily Goals")) {
                TextField("Calories", text: $calories)
                    .keyboardType(.decimalPad)
                    .onChange(of: calories) { _ in updateGoalSettings() }

                TextField("Protein (g)", text: $protein)
                    .keyboardType(.decimalPad)
                    .onChange(of: protein) { _ in updateGoalSettings() }

                TextField("Fats (g)", text: $fats)
                    .keyboardType(.decimalPad)
                    .onChange(of: fats) { _ in updateGoalSettings() }

                TextField("Carbs (g)", text: $carbs)
                    .keyboardType(.decimalPad)
                    .onChange(of: carbs) { _ in updateGoalSettings() }
            }

            Button(action: {
                saveAllGoals()
                dismiss()
            }) {
                Text("Save Goals")
                    .font(.title2)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.top)
        }
        .navigationTitle("Set Goals")
        .onAppear {
            // Populate the fields with existing goal values
            calories = String(format: "%.0f", goalSettings.calories)
            protein = String(format: "%.0f", goalSettings.protein)
            fats = String(format: "%.0f", goalSettings.fats)
            carbs = String(format: "%.0f", goalSettings.carbs)
        }
    }

    private func updateGoalSettings() {
        if let value = Double(calories) {
            goalSettings.calories = value
        }
        if let value = Double(protein) {
            goalSettings.protein = value
        }
        if let value = Double(fats) {
            goalSettings.fats = value
        }
        if let value = Double(carbs) {
            goalSettings.carbs = value
        }
    }

    private func saveAllGoals() {
        updateGoalSettings()
    }
}
