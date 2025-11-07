import Foundation
import FirebaseFirestore
import FirebaseAuth

class RecipeService: ObservableObject {
    private let db = Firestore.firestore()
    private var recipesListener: ListenerRegistration?
<<<<<<< HEAD
=======
    private let foodAPIService = FatSecretFoodAPIService()
>>>>>>> 5424a6b (Recreated the reports page with more polished UI)

    @Published var userRecipes: [UserRecipe] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

<<<<<<< HEAD
    // Firestore collection reference for user-specific recipes
=======
    weak var achievementService: AchievementService?

>>>>>>> 5424a6b (Recreated the reports page with more polished UI)
    private func recipesCollectionRef(for userID: String) -> CollectionReference {
        return db.collection("users").document(userID).collection("recipes")
    }

<<<<<<< HEAD
    // MARK: - CRUD Operations

    // Fetch recipes for the current user
=======
>>>>>>> 5424a6b (Recreated the reports page with more polished UI)
    @MainActor
    func fetchUserRecipes() {
        guard let userID = Auth.auth().currentUser?.uid else {
            errorMessage = "User not logged in."
            userRecipes = []
            return
        }

        isLoading = true
        errorMessage = nil
<<<<<<< HEAD
        recipesListener?.remove() // Remove previous listener

        recipesListener = recipesCollectionRef(for: userID)
            .order(by: "name", descending: false) // Order alphabetically
            .addSnapshotListener { [weak self] querySnapshot, error in
                guard let self = self else { return }
                isLoading = false

                if let error = error {
                    self.errorMessage = "Error fetching recipes: \(error.localizedDescription)"
                    print("❌ Error fetching recipes: \(error.localizedDescription)")
=======
        recipesListener?.remove()

        recipesListener = recipesCollectionRef(for: userID)
            .order(by: "name", descending: false)
            .addSnapshotListener { [weak self] querySnapshot, error in
                guard let self = self else { return }
                self.isLoading = false

                if let error = error {
                    self.errorMessage = "Error fetching recipes: \(error.localizedDescription)"
>>>>>>> 5424a6b (Recreated the reports page with more polished UI)
                    self.userRecipes = []
                    return
                }

                guard let documents = querySnapshot?.documents else {
<<<<<<< HEAD
                    self.errorMessage = "No recipe documents found."
=======
>>>>>>> 5424a6b (Recreated the reports page with more polished UI)
                    self.userRecipes = []
                    return
                }

<<<<<<< HEAD
                self.userRecipes = documents.compactMap { document -> UserRecipe? in
                    do {
                        let recipe = try document.data(as: UserRecipe.self)
                        print("✅ Successfully decoded recipe: \(recipe.name)")
                        return recipe
                    } catch let error {
                        print("❌ Error decoding recipe document \(document.documentID): \(error)")
                        // Added detailed debug information
                        if let decodingError = error as? DecodingError {
                            switch decodingError {
                            case .keyNotFound(let key, let context):
                                print("    - Key '\(key.stringValue)' not found. Path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
                                print("    - Debug Description: \(context.debugDescription)")
                            case .valueNotFound(let type, let context):
                                print("    - Value of type '\(type)' not found. Path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
                                print("    - Debug Description: \(context.debugDescription)")
                            case .typeMismatch(let type, let context):
                                print("    - Type mismatch for type '\(type)'. Path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
                                print("    - Debug Description: \(context.debugDescription)")
                            case .dataCorrupted(let context):
                                print("    - Data corrupted. Path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
                                print("    - Debug Description: \(context.debugDescription)")
                            @unknown default:
                                print("    - An unknown decoding error occurred.")
                            }
                        }
                        return nil
                    }
                }
                 print("✅ Fetched \(self.userRecipes.count) user recipes.")
            }
    }

    // Save a new recipe or update an existing one
=======
                self.userRecipes = documents.compactMap { document in
                    try? document.data(as: UserRecipe.self)
                }
            }
    }

>>>>>>> 5424a6b (Recreated the reports page with more polished UI)
    func saveRecipe(_ recipe: UserRecipe, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let userID = Auth.auth().currentUser?.uid else {
            completion(.failure(NSError(domain: "App", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])))
            return
        }

        var recipeToSave = recipe
<<<<<<< HEAD
        recipeToSave.userID = userID // Ensure userID is set
        recipeToSave.calculateTotals() // Recalculate totals before saving
        recipeToSave.updatedAt = Timestamp(date: Date()) // Update timestamp
        
        print("\n--- RecipeService: Attempting to save recipe ---")
        dump(recipeToSave)

=======
        recipeToSave.userID = userID
        recipeToSave.calculateTotals()
        recipeToSave.updatedAt = Timestamp(date: Date())
        
>>>>>>> 5424a6b (Recreated the reports page with more polished UI)
        let collectionRef = recipesCollectionRef(for: userID)

        do {
            if let id = recipeToSave.id, !id.isEmpty {
<<<<<<< HEAD
                // Update existing recipe
                 print("RecipeService: Updating recipe \(id)")
                try collectionRef.document(id).setData(from: recipeToSave, merge: true) { error in
                    if let error = error { completion(.failure(error)) } else { completion(.success(())) }
                }
            } else {
                // Add new recipe (Firestore generates ID)
                 print("RecipeService: Adding new recipe")
                var newRecipe = recipeToSave
                newRecipe.createdAt = Timestamp(date: Date()) // Set created time
                _ = try collectionRef.addDocument(from: newRecipe) { error in
                    if let error = error { completion(.failure(error)) } else { completion(.success(())) }
                }
            }
        } catch {
            print("❌ Error encoding or saving recipe: \(error)")
=======
                try collectionRef.document(id).setData(from: recipeToSave, merge: true) { error in
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        completion(.success(()))
                        Task { @MainActor in
                            self.achievementService?.checkRecipeCountAchievements(userID: userID)
                        }
                    }
                }
            } else {
                var newRecipe = recipeToSave
                newRecipe.createdAt = Timestamp(date: Date())
                _ = try collectionRef.addDocument(from: newRecipe) { error in
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        completion(.success(()))
                        Task { @MainActor in
                            self.achievementService?.checkRecipeCountAchievements(userID: userID)
                        }
                    }
                }
            }
        } catch {
>>>>>>> 5424a6b (Recreated the reports page with more polished UI)
            completion(.failure(error))
        }
    }

<<<<<<< HEAD
    // Delete a recipe
=======
>>>>>>> 5424a6b (Recreated the reports page with more polished UI)
    func deleteRecipe(_ recipe: UserRecipe, completion: @escaping (Error?) -> Void) {
        guard let userID = Auth.auth().currentUser?.uid else {
            completion(NSError(domain: "App", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"]))
            return
        }
        guard let recipeID = recipe.id else {
            completion(NSError(domain: "App", code: 400, userInfo: [NSLocalizedDescriptionKey: "Recipe has no ID"]))
            return
        }
<<<<<<< HEAD
        print("RecipeService: Deleting recipe \(recipeID)")
        recipesCollectionRef(for: userID).document(recipeID).delete { error in
            completion(error)
        }
    }

    // Call this when the user logs out or the service is no longer needed
=======
        recipesCollectionRef(for: userID).document(recipeID).delete(completion: completion)
    }
    
    func migrateUserRecipesToIncludeMicronutrients(completion: @escaping (String) -> Void) {
        guard let userID = Auth.auth().currentUser?.uid else {
            completion("Error: User not logged in.")
            return
        }

        let recipesRef = recipesCollectionRef(for: userID)
        recipesRef.getDocuments { [weak self] snapshot, error in
            guard let self = self, let documents = snapshot?.documents, error == nil else {
                completion("Error fetching recipes: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            let recipesToMigrate = documents.compactMap { try? $0.data(as: UserRecipe.self) }
            if recipesToMigrate.isEmpty {
                completion("No recipes to migrate.")
                return
            }
            
            let group = DispatchGroup()
            var updatedCount = 0
            
            for var recipe in recipesToMigrate {
                group.enter()
                Task {
                    var updatedIngredients: [RecipeIngredient] = []
                    for ingredient in recipe.ingredients {
                        if let foodId = ingredient.foodId {
                            let detailsResult = await self.fetchIngredientDetails(foodId: foodId)
                            if let newIngredientData = detailsResult {
                                var updatedIngredient = ingredient
                                updatedIngredient.fiber = newIngredientData.fiber
                                updatedIngredient.calcium = newIngredientData.calcium
                                updatedIngredients.append(updatedIngredient)
                            } else {
                                updatedIngredients.append(ingredient)
                            }
                        } else {
                            updatedIngredients.append(ingredient)
                        }
                    }
                    
                    recipe.ingredients = updatedIngredients
                    recipe.calculateTotals()
                    
                    self.saveRecipe(recipe) { result in
                        if case .success = result {
                            updatedCount += 1
                        }
                        group.leave()
                    }
                }
            }
            
            group.notify(queue: .main) {
                completion("Migration complete. Updated \(updatedCount) of \(recipesToMigrate.count) recipes.")
            }
        }
    }
    
    private func fetchIngredientDetails(foodId: String) async -> ServingSizeOption? {
        return await withCheckedContinuation { continuation in
            foodAPIService.fetchFoodDetails(foodId: foodId) { result in
                switch result {
                case .success(let (_, servings)):
                    continuation.resume(returning: servings.first)
                case .failure:
                    continuation.resume(returning: nil)
                }
            }
        }
    }

>>>>>>> 5424a6b (Recreated the reports page with more polished UI)
    func stopListening() {
        recipesListener?.remove()
        recipesListener = nil
        userRecipes = []
<<<<<<< HEAD
        print("RecipeService: Stopped listening for recipe updates.")
=======
>>>>>>> 5424a6b (Recreated the reports page with more polished UI)
    }
}
