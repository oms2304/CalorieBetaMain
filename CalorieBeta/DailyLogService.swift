import Foundation
import FirebaseAuth
import FirebaseFirestore

// This class manages the daily log data for the "CalorieBeta" app, interacting with Firebase Firestore.
// It acts as an ObservableObject to notify views of changes to the current daily log.
class DailyLogService: ObservableObject {
    // A published property to share the current daily log with views, updating them when it changes.
    @Published var currentDailyLog: DailyLog?
    // A reference to the Firestore database instance for all data operations.
    private let db = Firestore.firestore()
    // A listener registration to track real-time changes to the log (currently unused but reserved).
    private var logListener: ListenerRegistration?
    // The name of the Firestore subcollection to store recent foods, set as "recentFoods".
    private let recentFoodsCollection = "recentFoods"
    
    // Date formatter for consistent date strings in Firestore document IDs (format: "yyyy-MM-dd").
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    // Initializer for the service, currently empty but can be extended for setup logic.
    init() {
        // No initialization code yet, but this is where you could set up default listeners or configurations.
    }
    
    // Fetches or creates a daily log for a specific date for a given user.
    // If no log exists for the date, it creates a new one and saves it to Firestore.
    func fetchLog(for userID: String, date: Date, completion: @escaping (Result<DailyLog, Error>) -> Void) {
        // Normalize the date to the start of the day to ensure consistent matching.
        let startOfDay = Calendar.current.startOfDay(for: date)
        // Format the date as "yyyy-MM-dd" to use as the Firestore document ID.
        let dateString = dateFormatter.string(from: startOfDay)
        // Reference to the specific daily log document in Firestore.
        let logRef = db.collection("users").document(userID).collection("dailyLogs").document(dateString)
        
        // Fetch the log document from Firestore.
        logRef.getDocument { document, error in
            if let error = error {
                print("❌ Firestore fetch error: \(error.localizedDescription)")
                completion(.failure(error)) // Return the error to the caller.
                return
            }
            
            // Check if the document exists and decode it into a DailyLog.
            if let document = document, document.exists, let data = document.data() {
                print("🔍 Firestore fetched data for \(dateString): \(data)")
                let log = self.decodeDailyLog(from: data, documentID: dateString)
                completion(.success(log))
            } else {
                print("🔍 No log found for \(dateString), creating a new one.")
                // If no log exists, create a new one with the specified date and no meals.
                let newLog = DailyLog(id: dateString, date: startOfDay, meals: [])
                // Save the new log to Firestore.
                do {
                    try logRef.setData(from: newLog) { error in
                        if let error = error {
                            print("❌ Firestore save error: \(error.localizedDescription)")
                            completion(.failure(error))
                        } else {
                            completion(.success(newLog))
                        }
                    }
                } catch {
                    print("❌ Firestore encoding error: \(error.localizedDescription)")
                    completion(.failure(error))
                }
            }
        }
    }
    
    // Fetches or creates a daily log for the current day for a given user.
    // Delegates to fetchLog to ensure consistency in log retrieval.
    func fetchOrCreateTodayLog(for userID: String, completion: @escaping (Result<DailyLog, Error>) -> Void) {
        fetchLog(for: userID, date: Date(), completion: completion)
    }
    
    // Adds a food item to the daily log for a specific date and updates the recent foods list.
    func addFoodToCurrentLog(for userID: String, foodItem: FoodItem, date: Date) {
        // Fetch the log for the specified date to ensure we’re updating the correct log.
        fetchLog(for: userID, date: date) { result in
            switch result {
            case .success(var log):
                // Create a new food item with the current timestamp for tracking.
                let timestampedFoodItem = FoodItem(
                    id: foodItem.id,
                    name: foodItem.name,
                    calories: foodItem.calories,
                    protein: foodItem.protein,
                    carbs: foodItem.carbs,
                    fats: foodItem.fats,
                    servingSize: foodItem.servingSize,
                    servingWeight: foodItem.servingWeight,
                    timestamp: Date()
                )
                
                // Add the food item to the first meal (or create a new meal if none exist).
                if log.meals.isEmpty {
                    log.meals.append(Meal(id: UUID().uuidString, name: "All Meals", foodItems: [timestampedFoodItem]))
                } else {
                    log.meals[0].foodItems.append(timestampedFoodItem)
                }
                
                // Update the log in Firestore and the local state.
                self.updateDailyLog(for: userID, updatedLog: log)
                self.addRecentFood(for: userID, foodId: foodItem.id) // Also track this food as recent.
            case .failure(let error):
                print("❌ Error fetching log to add food: \(error.localizedDescription)")
            }
        }
    }
    
    // Adds a new meal with specified food items to the daily log for a specific date.
    func addMealToCurrentLog(for userID: String, mealName: String, foodItems: [FoodItem], date: Date) {
        // Fetch the log for the specified date to ensure we’re updating the correct log.
        fetchLog(for: userID, date: date) { result in
            switch result {
            case .success(var log):
                // Create a new meal with the provided name and food items.
                let newMeal = Meal(
                    id: UUID().uuidString,
                    name: mealName,
                    foodItems: foodItems.map { foodItem in
                        FoodItem(
                            id: foodItem.id,
                            name: foodItem.name,
                            calories: foodItem.calories,
                            protein: foodItem.protein,
                            carbs: foodItem.carbs,
                            fats: foodItem.fats,
                            servingSize: foodItem.servingSize,
                            servingWeight: foodItem.servingWeight,
                            timestamp: Date()
                        )
                    }
                )
                
                // Add the new meal to the log.
                log.meals.append(newMeal)
                
                // Update the log in Firestore and the local state.
                self.updateDailyLog(for: userID, updatedLog: log)
                print("✅ Added meal '\(mealName)' with \(foodItems.count) items to log for \(self.dateFormatter.string(from: date))")
            case .failure(let error):
                print("❌ Error fetching log to add meal: \(error.localizedDescription)")
            }
        }
    }
    
    // Removes a food item from the daily log for a specific date based on its ID.
    func deleteFoodFromCurrentLog(for userID: String, foodItemID: String, date: Date) {
        // Fetch the log for the specified date to ensure we’re updating the correct log.
        fetchLog(for: userID, date: date) { result in
            switch result {
            case .success(var log):
                // Remove the food item with the matching ID from all meals.
                for i in log.meals.indices {
                    log.meals[i].foodItems.removeAll { $0.id == foodItemID }
                }
                
                // Update the log in Firestore and the local state.
                self.updateDailyLog(for: userID, updatedLog: log)
            case .failure(let error):
                print("❌ Error fetching log to delete food: \(error.localizedDescription)")
            }
        }
    }
    
    // Adds a food item to the user's recent foods list in Firestore, managing a limit of 10.
    private func addRecentFood(for userID: String, foodId: String) {
        // Ensure the current user is authenticated to proceed.
        guard let userID = Auth.auth().currentUser?.uid else { return }
        // Reference to the recentFoods subcollection for the user.
        let recentRef = self.db.collection("users").document(userID).collection(recentFoodsCollection)
        
        // Fetch the current recent foods to handle deduplication and limits.
        recentRef.order(by: "timestamp", descending: true).limit(to: 10).getDocuments { snapshot, error in
            if let error = error {
                print("❌ Error fetching recent foods for deduplication: \(error.localizedDescription)")
                return
            }
            
            // Create a batch for multiple Firestore operations.
            let batch = self.db.batch()
            // Extract existing food IDs from the snapshot.
            let existingFoodIds = snapshot?.documents.compactMap { $0.data()["foodId"] as? String } ?? []
            
            // Handle deduplication and limit enforcement.
            if existingFoodIds.contains(foodId) {
                if existingFoodIds.count >= 10 {
                    // If the limit is reached and the food exists, remove the oldest.
                    if let oldestDoc = snapshot?.documents.last {
                        batch.deleteDocument(oldestDoc.reference)
                    }
                }
            } else if existingFoodIds.count >= 10 {
                // If adding a new food exceeds the limit, remove the oldest.
                if let oldestDoc = snapshot?.documents.last {
                    batch.deleteDocument(oldestDoc.reference)
                }
            }
            
            // Clean up foods older than 30 days.
            let thirtyDaysAgo = Timestamp(date: Date().addingTimeInterval(-30 * 24 * 3600))
            recentRef.whereField("timestamp", isLessThan: thirtyDaysAgo).getDocuments { oldSnapshot, oldError in
                if let oldError = oldError {
                    print("❌ Error cleaning old recent foods: \(oldError.localizedDescription)")
                    return
                }
                // Delete documents older than 30 days.
                if let oldDocuments = oldSnapshot?.documents {
                    for document in oldDocuments {
                        batch.deleteDocument(document.reference)
                    }
                }
                
                // Add the new recent food entry.
                let newDocRef = recentRef.document()
                batch.setData([
                    "foodId": foodId,
                    "timestamp": Timestamp(date: Date())
                ], forDocument: newDocRef)
                
                // Commit all changes in the batch.
                batch.commit { error in
                    if let error = error {
                        print("❌ Error adding recent food: \(error.localizedDescription)")
                    } else {
                        print("✅ Added recent food ID: \(foodId) for user: \(userID)")
                    }
                }
            }
        }
    }
    
    // Fetches the IDs of the user's recently added foods from Firestore.
    func fetchRecentFoods(for userID: String, completion: @escaping (Result<[String], Error>) -> Void) {
        // Ensure the current user is authenticated.
        guard let userID = Auth.auth().currentUser?.uid else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user ID found"])))
            return
        }
        
        // Query the recent foods collection, ordered by timestamp and limited to 10.
        let recentRef = db.collection("users").document(userID).collection(recentFoodsCollection)
            .order(by: "timestamp", descending: true)
            .limit(to: 10)
        
        recentRef.getDocuments { snapshot, error in
            if let error = error {
                completion(.failure(error)) // Return the error.
                print("❌ Error fetching recent foods: \(error.localizedDescription)")
                return
            }
            
            // Extract food IDs from the snapshot documents.
            let foodIds: [String] = snapshot?.documents.compactMap { $0.data()["foodId"] as? String } ?? []
            print("✅ Fetched recent food IDs: \(foodIds)")
            completion(.success(foodIds)) // Notify the caller with the result.
        }
    }
    
    // Adds a new daily log to Firestore for a given user (unused with new fetchLog method).
    private func addNewDailyLog(for userID: String, newLog: DailyLog, completion: @escaping (Result<Void, Error>) -> Void) {
        // Reference to the new log document in the user's dailyLogs collection.
        let logRef = db.collection("users").document(userID).collection("dailyLogs").document(newLog.id ?? UUID().uuidString)
        logRef.setData(encodeDailyLog(newLog)) { error in
            if let error = error { completion(.failure(error)) } // Return error if present.
            else { completion(.success(())) } // Notify success.
        }
    }
    
    // Updates an existing daily log in Firestore and the local state.
    private func updateDailyLog(for userID: String, updatedLog: DailyLog) {
        // Format the date as the document ID.
        let dateString = dateFormatter.string(from: updatedLog.date)
        // Reference to the log document to update.
        let logRef = db.collection("users").document(userID).collection("dailyLogs").document(dateString)
        logRef.setData(encodeDailyLog(updatedLog), merge: true) // Merge new data with existing.
        DispatchQueue.main.async {
            self.currentDailyLog = updatedLog // Update the published log on the main thread.
        }
    }
    
    // Fetches posts authored by a specific user from Firestore (currently unused in main flow).
    func fetchPosts(for userID: String, completion: @escaping (Result<[Post], Error>) -> Void) {
        db.collection("posts").whereField("author", isEqualTo: userID).getDocuments { snapshot, error in
            if let error = error {
                completion(.failure(error)) // Return the error.
                return
            }
            
            // Map Firestore documents to Post objects.
            let posts: [Post] = snapshot?.documents.compactMap { document in
                let data = document.data()
                return Post(
                    id: document.documentID,
                    content: data["content"] as? String ?? "",
                    timestamp: (data["timestamp"] as? Timestamp)?.dateValue() ?? Date()
                )
            } ?? []
            
            completion(.success(posts)) // Notify the caller with the result.
        }
    }
    
    // Fetches achievements for a specific user from Firestore (currently unused in main flow).
    func fetchAchievements(for userID: String, completion: @escaping (Result<[Achievement], Error>) -> Void) {
        db.collection("users").document(userID).collection("achievements").getDocuments { snapshot, error in
            if let error = error {
                completion(.failure(error)) // Return the error.
                return
            }
            
            // Map Firestore documents to Achievement objects.
            let achievements: [Achievement] = snapshot?.documents.compactMap { document in
                let data = document.data()
                return Achievement(
                    id: document.documentID,
                    title: data["title"] as? String ?? ""
                )
            } ?? []
            
            completion(.success(achievements)) // Notify the caller with the result.
        }
    }
    
    // Fetches the history of daily logs for a specific user from Firestore.
    func fetchDailyHistory(for userID: String, completion: @escaping (Result<[DailyLog], Error>) -> Void) {
        db.collection("users").document(userID).collection("dailyLogs")
            .order(by: "date", descending: true).getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error)) // Return the error.
                    return
                }
                
                // Map Firestore documents to DailyLog objects.
                let logs: [DailyLog] = snapshot?.documents.compactMap { document in
                    self.decodeDailyLog(from: document.data(), documentID: document.documentID)
                } ?? []
                
                print("🔍 Fetched daily history: \(logs.map { "\($0.id ?? "nil") - Meals: \($0.meals.count)" })")
                completion(.success(logs)) // Notify the caller with the result.
            }
    }
    
    // Encodes a DailyLog object into a dictionary format suitable for Firestore.
    private func encodeDailyLog(_ log: DailyLog) -> [String: Any] {
        return [
            "id": log.id ?? UUID().uuidString, // Ensure an ID is always present.
            "date": Timestamp(date: log.date), // Convert Date to Firestore Timestamp.
            "meals": log.meals.map { meal in // Convert each meal and its food items.
                [
                    "id": meal.id,
                    "name": meal.name,
                    "foodItems": meal.foodItems.map { foodItem in
                        [
                            "id": foodItem.id,
                            "name": foodItem.name,
                            "calories": foodItem.calories,
                            "protein": foodItem.protein,
                            "carbs": foodItem.carbs,
                            "fats": foodItem.fats,
                            "servingSize": foodItem.servingSize,
                            "servingWeight": foodItem.servingWeight,
                            "timestamp": foodItem.timestamp.map { Timestamp(date: $0) } ?? NSNull()
                        ]
                    }
                ]
            }
        ]
    }
    
    // Decodes a Firestore document into a DailyLog object.
    private func decodeDailyLog(from data: [String: Any], documentID: String) -> DailyLog {
        // Extract the date, using the current date as a fallback.
        let date = (data["date"] as? Timestamp)?.dateValue() ?? Date()
        // Extract the meals data, handling potential nil values.
        let mealsData = data["meals"] as? [[String: Any]] ?? []
        // Map the meals data into Meal objects, including their food items.
        let meals = mealsData.map { mealData in
            Meal(
                id: mealData["id"] as? String ?? UUID().uuidString, // Default ID if missing.
                name: mealData["name"] as? String ?? "Meal", // Default name if missing.
                foodItems: (mealData["foodItems"] as? [[String: Any]])?.compactMap { foodItemData in
                    FoodItem(
                        id: foodItemData["id"] as? String ?? UUID().uuidString,
                        name: foodItemData["name"] as? String ?? "",
                        calories: foodItemData["calories"] as? Double ?? 0.0,
                        protein: foodItemData["protein"] as? Double ?? 0.0,
                        carbs: foodItemData["carbs"] as? Double ?? 0.0,
                        fats: foodItemData["fats"] as? Double ?? 0.0,
                        servingSize: foodItemData["servingSize"] as? String ?? "N/A",
                        servingWeight: foodItemData["servingWeight"] as? Double ?? 0.0,
                        timestamp: (foodItemData["timestamp"] as? Timestamp)?.dateValue()
                    )
                } ?? [] // Empty array if food items are missing.
            )
        }
        // Return the fully constructed DailyLog.
        return DailyLog(id: documentID, date: date, meals: meals)
    }
}
