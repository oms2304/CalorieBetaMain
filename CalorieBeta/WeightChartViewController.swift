//
//  WeightChartViewController.swift
//  CalorieBeta
//
//  Created by Omar Sabeha on 4/9/25.
//

import SwiftUI
 import FirebaseAuth


struct WeightChartViewController: View {
    @EnvironmentObject var goalSettings: GoalSettings
    
    @State private var weight = ""
    @State private var showTargetWeightSheet = false
    // controls the visibility of the target weight sheet
    @State private var targetWeight: String = ""
    // stores the target wieght input as a string
    var body: some View {
        NavigationView {
            VStack{
                if let targetWeight = goalSettings.targetWeight {
                    // Show the current target weight and a "Change" button.
                    HStack {
                        Text("Target Weight: \(String(format: "%.1f", targetWeight)) lbs")
                            .font(.headline)
                        Spacer()
                        Button(action: {
                            showTargetWeightSheet = true // Opens the sheet to change the target weight.
                        }) {
                            Text("Change")
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.horizontal)
                    
                    if let progress = goalSettings.calculateWeightProgress()
                    {
                        Text("Progress to Target: \(String(format: "%.1f", progress))%")
                            .font(.subheadline)
                            .padding(.horizontal)
                        
                        ProgressBar(
                            currentWeight: goalSettings.weight,
                            initialWeight: goalSettings.weightHistory.first?.weight ?? goalSettings.weight,
                            targetWeight: targetWeight
                        )
                        .padding(.horizontal)
                    }
                    
                    if let weeklyChange = goalSettings.calculateWeeklyWeightChange() {
                        Text(weeklyChangeInsight(weeklyChange))
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .padding(.horizontal)
                    }
                    
                } else {
                    // Show a button to set the target weight.
                    Button(action: {
                        showTargetWeightSheet = true // Opens the sheet to set a target weight.
                    }) {
                        Text("Set Target Weight")
                            .font(.headline)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                }
            }
        }
                .sheet(isPresented: $showTargetWeightSheet) {
                    NavigationView {
                        Form {
                            Section(header: Text("Target Weight")) {
                                TextField("Enter your target weight (lbs)", text: $targetWeight)
                                    .keyboardType(.decimalPad) // Shows a decimal keyboard for numeric input.
                            }
                            Button(action: {
                                saveTargetWeight() // Saves the target weight.
                                showTargetWeightSheet = false // Closes the sheet.
                            }) {
                                Text("Save Target Weight")
                                    .font(.title2)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                            .padding(.top)
                        }
                        .navigationTitle("Set Target Weight")
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Cancel") {
                                    showTargetWeightSheet = false // Closes the sheet without saving.
                                }
                            }
                        }
                        .onAppear {
                            // Sets the initial target weight value if it exists.
                            if let target = goalSettings.targetWeight {
                                targetWeight = String(format: "%.1f", target)
                            }
                        }
                    }
                }
        }
    
    private func saveTargetWeight() {
        
        guard let targetValue = Double(targetWeight), targetValue > 0 else {
            print("saveTargetWeight triggered")
            return } // Validates input.
        
        print("Valid target weight input: \(targetValue)")
        
        
        goalSettings.targetWeight = targetValue // Updates the target weight.
        if let userID = Auth.auth().currentUser?.uid {
            print("Saving for user: \(userID)")
            goalSettings.saveUserGoals(userID: userID) // Saves the updated goals to Firestore.
        } else {
            print("no authenticated user found")
        }
        goalSettings.recalculateCalorieGoal() // Recalculates calorie goals based on the new target.
    }
    
    private func weeklyChangeInsight(_ weeklyChange: Double) -> String{
        if weeklyChange < 0 {
            return "You're losing \(String(format: "%.1f", -weeklyChange))"
        } else if weeklyChange > 0 {
            return "You're gaining \(String(format: "%.1f", weeklyChange))"
        } else {
            return "Your weight is stable. Great job maintaining!"
        }
    }
    
    struct ProgressBar: View {
   
        let currentWeight: Double // Current weight of the user.
        let initialWeight: Double // Initial weight (first recorded weight).
        let targetWeight: Double // Target weight goal.
        var progress: Double {
            let total = abs(targetWeight - initialWeight)
            guard total != 0 else { return 0 }
            return abs(currentWeight - initialWeight) / total
        }

        

        var body: some View {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background bar (gray) representing the full range.
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 10)
                        .cornerRadius(5)
                    // Progress bar (green or red) showing progress toward the target.
                    if progress >= 0{
                        Rectangle()
                            .fill(progressColor)
                            .frame(
                                width: min(
                                    CGFloat(abs(currentWeight - initialWeight) / abs(targetWeight - initialWeight)) * geometry.size.width,
                                    geometry.size.width
                                ),
                                height: 10
                            )
                            .cornerRadius(5)
                    }
                }
            }
            .frame(height: 10)
        }

        var progressColor: Color {
            let weightDifference = currentWeight - targetWeight
            if weightDifference > 0 && currentWeight < initialWeight { // Losing weight toward target.
                return Color(red: 67/255, green: 172/255, blue: 111/255)
            } else if weightDifference < 0 && currentWeight > initialWeight { // Gaining weight toward target.
                return Color(red: 67/255, green: 172/255, blue: 111/255)
            } else {
                return .red // Not making progress toward the target.
            }
        }
    }
    
    

}
    


#Preview {
    WeightChartViewController()
        .environmentObject(GoalSettings())
}
