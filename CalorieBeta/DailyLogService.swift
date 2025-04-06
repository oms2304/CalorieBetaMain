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

    // Initializer for the service, currently empty but can be extended for setup logic.
    init() {
        // No initialization code yet, but this is where you could set up default listeners or configurations.
    }

    // Fetches or creates a daily log for the current day for a given user.
    // If no log exists, it creates a new one and saves it to Firestore.
    func fetchOrCreateTodayLog(for userID: String, completion: @escaping (Result<DailyLog, Error>) -> Void) {
        // Gets the start of today to match logs by date.
        let today = Calendar.current.startOfDay(for: Date())
        // Reference to the user's dailyLogs collection in Firestore.
        let logsRef = db.collection("users").document(userID).collection("dailyLogs")

        // Queries Firestore for a log matching today's date.
        logsRef.whereField("date", isEqualTo: Timestamp(date: today)).getDocuments { snapshot, error in
            // Checks if there was an error during the query.
            if let error = error {
                completion(.failure(error)) // Returns the error to the caller.
                return
            }

            // If a log exists, decode and return it.
            if let document = snapshot?.documents.first {
                let log = self.decodeDailyLog(from: document.data(), documentID: document.documentID)
                DispatchQueue.main.async {
                    self.currentDailyLog = log // Updates the published log on the main thread.
                }
                completion(.success(log)) // Notifies the caller of success.
            } else {
                // If no log exists, create a new one with today's date and no meals.
                let newLog = DailyLog(id: UUID().uuidString, date: today, meals: [])
                // Asynchronously adds the new log to Firestore.
                self.addNewDailyLog(for: userID, newLog: newLog) { result in
                    if case .success = result {
                        DispatchQueue.main.async {
                            self.currentDailyLog = newLog // Updates the published log.
                        }
                        completion(.success(newLog)) // Notifies the caller.
                    } else if case let .failure(error) = result {
                        completion(.failure(error)) // Passes any error back.
                    }
                }
            }
        }
    }

    // Adds a food item to the current daily log and updates the recent foods list.
    func addFoodToCurrentLog(for userID: String, foodItem: FoodItem) {
        // Ensures there’s a current log to modify, otherwise exits early.
        guard var currentLog = currentDailyLog else { return }

        // Creates a new food item with the current timestamp for tracking.
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

        // Adds the food item to the first meal (or creates a new meal if none exist).
        if currentLog.meals.isEmpty {
            currentLog.meals.append(Meal(id: UUID().uuidString, name: "All Meals", foodItems: [timestampedFoodItem]))
        } else {
            currentLog.meals[0].foodItems.append(timestampedFoodItem)
        }

        // Updates the log in Firestore and the local state.
        updateDailyLog(for: userID, updatedLog: currentLog)
        addRecentFood(for: userID, foodId: foodItem.id) // Also tracks this food as recent.
    }

    // Removes a food item from the current daily log based on its ID.
    func deleteFoodFromCurrentLog(for userID: String, foodItemID: String) {
        // Ensures there’s a current log to modify, otherwise exits early.
        guard var currentLog = currentDailyLog else { return }

        // Removes the food item with the matching ID from all meals.
        for i in currentLog.meals.indices {
            currentLog.meals[i].foodItems.removeAll { $0.id == foodItemID }
        }

        // Updates the log in Firestore and the local state.
        updateDailyLog(for: userID, updatedLog: currentLog)
    }

    // Adds a food item to the user's recent foods list in Firestore, managing a limit of 10.
    private func addRecentFood(for userID: String, foodId: String) {
        // Ensures the current user is authenticated to proceed.
        guard let userID = Auth.auth().currentUser?.uid else { return }
        // Reference to the recentFoods subcollection for the user.
        let recentRef = self.db.collection("users").document(userID).collection(recentFoodsCollection)

        // Fetches the current recent foods to handle deduplication and limits.
        recentRef.order(by: "timestamp", descending: true).limit(to: 10).getDocuments { snapshot, error in
            if let error = error {
                print("❌ Error fetching recent foods for deduplication: \(error.localizedDescription)")
                return
            }

            // Creates a batch for multiple Firestore operations.
            let batch = self.db.batch()
            // Extracts existing food IDs from the snapshot.
            let existingFoodIds = snapshot?.documents.compactMap { $0.data()["foodId"] as? String } ?? []

            // Handles deduplication and limit enforcement.
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

            // Cleans up foods older than 30 days.
            let thirtyDaysAgo = Timestamp(date: Date().addingTimeInterval(-30 * 24 * 3600))
            recentRef.whereField("timestamp", isLessThan: thirtyDaysAgo).getDocuments { oldSnapshot, oldError in
                if let oldError = oldError {
                    print("❌ Error cleaning old recent foods: \(oldError.localizedDescription)")
                    return
                }
                // Deletes documents older than 30 days.
                if let oldDocuments = oldSnapshot?.documents {
                    for document in oldDocuments {
                        batch.deleteDocument(document.reference)
                    }
                }

                // Adds the new recent food entry.
                let newDocRef = recentRef.document()
                batch.setData([
                    "foodId": foodId,
                    "timestamp": Timestamp(date: Date())
                ], forDocument: newDocRef)

                // Commits all changes in the batch.
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
        // Ensures the current user is authenticated.
        guard let userID = Auth.auth().currentUser?.uid else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user ID found"])))
            return
        }

        // Queries the recent foods collection, ordered by timestamp and limited to 10.
        let recentRef = db.collection("users").document(userID).collection(recentFoodsCollection)
            .order(by: "timestamp", descending: true)
            .limit(to: 10)

        recentRef.getDocuments { snapshot, error in
            if let error = error {
                completion(.failure(error)) // Returns the error.
                print("❌ Error fetching recent foods: \(error.localizedDescription)")
                return
            }

            // Extracts food IDs from the snapshot documents.
            let foodIds: [String] = snapshot?.documents.compactMap { $0.data()["foodId"] as? String } ?? []
            print("✅ Fetched recent food IDs: \(foodIds)")
            completion(.success(foodIds)) // Notifies the caller with the result.
        }
    }

    // Adds a new daily log to Firestore for a given user.
    private func addNewDailyLog(for userID: String, newLog: DailyLog, completion: @escaping (Result<Void, Error>) -> Void) {
        // Reference to the new log document in the user's dailyLogs collection.
        let logRef = db.collection("users").document(userID).collection("dailyLogs").document(newLog.id ?? UUID().uuidString)
        logRef.setData(encodeDailyLog(newLog)) { error in
            if let error = error { completion(.failure(error)) } // Returns error if present.
            else { completion(.success(())) } // Notifies success.
        }
    }

    // Updates an existing daily log in Firestore and the local state.
    private func updateDailyLog(for userID: String, updatedLog: DailyLog) {
        // Reference to the log document to update.
        let logRef = db.collection("users").document(userID).collection("dailyLogs").document(updatedLog.id ?? UUID().uuidString)
        logRef.setData(encodeDailyLog(updatedLog), merge: true) // Merges new data with existing.
        DispatchQueue.main.async {
            self.currentDailyLog = updatedLog // Updates the published log on the main thread.
        }
    }

    // Fetches posts authored by a specific user from Firestore (currently unused in main flow).
    func fetchPosts(for userID: String, completion: @escaping (Result<[Post], Error>) -> Void) {
        db.collection("posts").whereField("author", isEqualTo: userID).getDocuments { snapshot, error in
            if let error = error {
                completion(.failure(error)) // Returns the error.
                return
            }

            // Maps Firestore documents to Post objects.
            let posts: [Post] = snapshot?.documents.compactMap { document in
                let data = document.data()
                return Post(
                    id: document.documentID,
                    content: data["content"] as? String ?? "",
                    timestamp: (data["timestamp"] as? Timestamp)?.dateValue() ?? Date()
                )
            } ?? []

            completion(.success(posts)) // Notifies the caller with the result.
        }
    }

    // Fetches achievements for a specific user from Firestore (currently unused in main flow).
    func fetchAchievements(for userID: String, completion: @escaping (Result<[Achievement], Error>) -> Void) {
        db.collection("users").document(userID).collection("achievements").getDocuments { snapshot, error in
            if let error = error {
                completion(.failure(error)) // Returns the error.
                return
            }

            // Maps Firestore documents to Achievement objects.
            let achievements: [Achievement] = snapshot?.documents.compactMap { document in
                let data = document.data()
                return Achievement(
                    id: document.documentID,
                    title: data["title"] as? String ?? ""
                )
            } ?? []

            completion(.success(achievements)) // Notifies the caller with the result.
        }
    }

    // Fetches the history of daily logs for a specific user from Firestore.
    func fetchDailyHistory(for userID: String, completion: @escaping (Result<[DailyLog], Error>) -> Void) {
        db.collection("users").document(userID).collection("dailyLogs")
            .order(by: "date", descending: true).getDocuments { snapshot, error in
            if let error = error {
                completion(.failure(error)) // Returns the error.
                return
            }

            // Maps Firestore documents to DailyLog objects.
            let logs: [DailyLog] = snapshot?.documents.compactMap { document in
                self.decodeDailyLog(from: document.data(), documentID: document.documentID)
            } ?? []

            completion(.success(logs)) // Notifies the caller with the result.
        }
    }

    // Encodes a DailyLog object into a dictionary format suitable for Firestore.
    private func encodeDailyLog(_ log: DailyLog) -> [String: Any] {
        return [
            "id": log.id ?? UUID().uuidString, // Ensures an ID is always present.
            "date": Timestamp(date: log.date), // Converts Date to Firestore Timestamp.
            "meals": log.meals.map { meal in // Converts each meal and its food items.
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
        // Extracts the date, using the current date as a fallback.
        let date = (data["date"] as? Timestamp)?.dateValue() ?? Date()
        // Extracts the meals data, handling potential nil values.
        let mealsData = data["meals"] as? [[String: Any]] ?? []
        // Maps the meals data into Meal objects, including their food items.
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
        // Returns the fully constructed DailyLog.
        return DailyLog(id: documentID, date: date, meals: meals)
    }
}
