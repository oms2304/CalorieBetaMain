import Foundation
import FirebaseFirestore
import FirebaseAuth

// This class manages the user's goal settings (e.g., calories, macros, weight, height) and
// integrates with Firebase Firestore for persistence. It acts as an ObservableObject to
// notify views of changes.
class GoalSettings: ObservableObject {
    // Published properties to track and update user goals, observable by SwiftUI views:
    @Published var calories: Double? // Optional calorie goal, calculated or set manually.
    @Published var protein: Double = 150 // Default protein goal in grams.
    @Published var fats: Double = 70 // Default fat goal in grams.
    @Published var carbs: Double = 250 // Default carbohydrate goal in grams.
    @Published var weight: Double = 150.0 // Default weight in pounds.
    @Published var height: Double = 170.0 // Default height in centimeters.
    @Published var weightHistory: [(date: Date, weight: Double)] = [] // History of weight entries.
    @Published var isUpdatingGoal: Bool = false // Tracks if a goal update is in progress.
    @Published var proteinPercentage: Double = 30.0 // Percentage of calories from protein.
    @Published var carbsPercentage: Double = 50.0 // Percentage of calories from carbs.
    @Published var fatsPercentage: Double = 20.0 // Percentage of calories from fats.
    @Published var activityLevel: Double = 1.2 // Activity multiplier (e.g., 1.2 for sedentary).
    @Published var age: Int = 25 // Default user age in years.
    @Published var gender: String = "Male" // Default gender.
    @Published var goal: String = "Maintain" // User’s goal (e.g., "Lose", "Maintain", "Gain").
    @Published var showingBubbles: Bool = true // Default to bubbles

    // Private properties for Firebase and state management:
    private let db = Firestore.firestore() // Firestore database instance.
    private var isFetchingGoals = false // Prevents multiple simultaneous fetch requests.
    private var isGoalsLoaded = false // Tracks if goals have been loaded.

    // Updates the macronutrient goals based on the calorie goal and percentages.
    func updateMacros() {
        guard let calorieGoal = calories else { return } // Exits if no calorie goal is set.

        let totalPercentage = proteinPercentage + carbsPercentage + fatsPercentage
        guard totalPercentage == 100 else {
            print("❌ Macronutrient percentages do not sum to 100%") // Logs an error if percentages are invalid.
            return
        }

        // Calculates macronutrient calories and converts to grams (1g protein/carb = 4kcal, 1g fat = 9kcal).
        let proteinCalories = (proteinPercentage / 100) * calorieGoal
        let carbsCalories = (carbsPercentage / 100) * calorieGoal
        let fatsCalories = (fatsPercentage / 100) * calorieGoal

        self.protein = proteinCalories / 4
        self.carbs = carbsCalories / 4
        self.fats = fatsCalories / 9

        print("✅ Updated Macros: \(self.protein)g Protein, \(self.carbs)g Carbs, \(self.fats)g Fats") // Logs the update.
    }

    // Recalculates the calorie goal based on BMR, activity level, and user goal.
    func recalculateCalorieGoal() {
        let weightInKg = weight * 0.453592 // Converts weight from pounds to kilograms.
        let heightInCm = height // Height is already in centimeters.

        // Calculates Basal Metabolic Rate (BMR) using the Mifflin-St Jeor equation.
        let bmr: Double
        if gender == "Male" {
            bmr = 10 * weightInKg + 6.25 * heightInCm - 5 * Double(age) + 5
        } else {
            bmr = 10 * weightInKg + 6.25 * heightInCm - 5 * Double(age) - 161
        }

        var calories = bmr * activityLevel // Adjusts BMR with activity level.
        switch goal {
        case "Lose":
            calories -= 500 // Reduces calories by 500 for weight loss.
        case "Gain":
            calories += 500 // Increases calories by 500 for weight gain.
        default:
            break // No adjustment for "Maintain".
        }

        self.calories = max(calories, 0) // Ensures calories are not negative.
        updateMacros() // Updates macronutrients based on the new calorie goal.
    }

    // Loads user goals from Firestore for a given user ID.
    func loadUserGoals(userID: String, completion: @escaping () -> Void = {}) {
        guard !isFetchingGoals else { return } // Prevents redundant fetches.
        isFetchingGoals = true

        // Fetches the user document from Firestore.
        db.collection("users").document(userID).getDocument { [weak self] document, error in
            // Ensures cleanup and callback execution regardless of success or failure.
            defer {
                self?.isFetchingGoals = false
                self?.isGoalsLoaded = true
                completion()
            }
            guard let self = self else { return } // Avoids retain cycles with weak self.

            if let document = document, document.exists, let data = document.data() {
                DispatchQueue.main.async {
                    // Updates properties with data from Firestore, using defaults if missing.
                    if let goals = data["goals"] as? [String: Any] {
                        self.calories = goals["calories"] as? Double ?? self.calories
                        self.protein = goals["protein"] as? Double ?? self.protein
                        self.fats = goals["fats"] as? Double ?? self.fats
                        self.carbs = goals["carbs"] as? Double ?? self.carbs
                        self.proteinPercentage = goals["proteinPercentage"] as? Double ?? self.proteinPercentage
                        self.carbsPercentage = goals["carbsPercentage"] as? Double ?? self.carbsPercentage
                        self.fatsPercentage = goals["fatsPercentage"] as? Double ?? self.fatsPercentage
                        self.activityLevel = goals["activityLevel"] as? Double ?? self.activityLevel
                        self.age = goals["age"] as? Int ?? self.age
                        self.gender = goals["gender"] as? String ?? self.gender
                        self.goal = goals["goal"] as? String ?? self.goal
                    }

                    self.weight = data["weight"] as? Double ?? self.weight
                    self.height = data["height"] as? Double ?? self.height

                    self.recalculateCalorieGoal() // Recalculates goals based on loaded data.
                    print("✅ Loaded user goals: \(self.calories ?? 0) calories") // Logs success.
                }
            } else {
                print("❌ Error fetching user goals: \(error?.localizedDescription ?? "Unknown error")") // Logs any errors.
            }
        }
    }

    // Saves user goals to Firestore for a given user ID.
    func saveUserGoals(userID: String) {
        self.isUpdatingGoal = true // Indicates an update is in progress.

        self.updateMacros() // Updates macros before saving.

        // Prepares the goal data to save.
        let goalData = [
            "calories": calories ?? 2000, // Default to 2000 if nil.
            "protein": protein,
            "fats": fats,
            "carbs": carbs,
            "proteinPercentage": proteinPercentage,
            "carbsPercentage": carbsPercentage,
            "fatsPercentage": fatsPercentage,
            "activityLevel": activityLevel,
            "age": age,
            "gender": gender,
            "goal": goal
        ] as [String: Any]

        let userData = [
            "goals": goalData,
            "weight": weight,
            "height": height
        ] as [String: Any]

        // Saves the data to Firestore, merging with existing data.
        db.collection("users").document(userID).setData(userData, merge: true) { [weak self] error in
            guard let self = self else { return } // Avoids retain cycles.

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.isUpdatingGoal = false // Resets the update flag after a delay.
            }

            if let error = error {
                print("❌ Error saving user goals: \(error.localizedDescription)") // Logs any errors.
            } else {
                DispatchQueue.main.async {
                    print("✅ User goals saved successfully.") // Logs success.
                }
            }
        }
    }

    // Loads the user's weight history from Firestore.
    func loadWeightHistory() {
        guard let userID = Auth.auth().currentUser?.uid else { return } // Ensures a user is logged in.

        // Fetches weight history, ordered chronologically.
        db.collection("users").document(userID).collection("weightHistory")
            .order(by: "timestamp", descending: false)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("❌ Error fetching weight history: \(error.localizedDescription)") // Logs any errors.
                    return
                }

                DispatchQueue.main.async {
                    // Maps Firestore documents to weight history tuples.
                    self.weightHistory = snapshot?.documents.compactMap { doc in
                        if let weight = doc.data()["weight"] as? Double,
                           let timestamp = doc.data()["timestamp"] as? Timestamp {
                            return (timestamp.dateValue(), weight) // Returns (date, weight) tuple.
                        }
                        return nil // Ignores invalid entries.
                    } ?? []
                }
            }
    }

    // Updates the user's weight and saves it to Firestore with a timestamp.
    func updateUserWeight(_ newWeight: Double) {
        guard let userID = Auth.auth().currentUser?.uid else { return } // Ensures a user is logged in.

        weight = newWeight // Updates the current weight.
        recalculateCalorieGoal() // Recalculates goals based on new weight.

        let weightData: [String: Any] = [
            "weight": newWeight, // New weight value.
            "timestamp": Timestamp(date: Date()) // Current timestamp.
        ]

        // Updates the user's weight in the main document.
        db.collection("users").document(userID).setData(["weight": newWeight], merge: true)

        // Adds the weight to the history collection.
        db.collection("users").document(userID).collection("weightHistory")
            .addDocument(data: weightData) { error in
                if let error = error {
                    print("❌ Error saving weight history: \(error.localizedDescription)") // Logs any errors.
                } else {
                    print("✅ Weight history updated successfully.") // Logs success.
                }
            }

        saveUserGoals(userID: userID) // Saves all updated goals.
    }

    // Converts the height from centimeters to feet and inches.
    func getHeightInFeetAndInches() -> (feet: Int, inches: Int) {
        let totalInches = Int(height / 2.54) // Converts cm to inches (1 cm = 0.393701 inches).
        let feet = totalInches / 12 // Calculates the number of feet.
        let inches = totalInches % 12 // Calculates the remaining inches.
        return (feet, inches)
    }

    // Sets the height from feet and inches, converting to centimeters.
    func setHeight(feet: Int, inches: Int) {
        let totalInches = (feet * 12) + inches // Combines feet and inches into total inches.
        height = Double(totalInches) * 2.54 // Converts inches to centimeters.
    }
}
