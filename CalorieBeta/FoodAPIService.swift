import Foundation
import FirebaseFirestore


enum APIError: Error {
    case invalidURL
    case noData
    case decodingError
}


struct OpenFoodFactsResponse: Decodable {
    let products: [OpenFoodFactsItem]
}

struct OpenFoodFactsItem: Decodable {
    let productName: String?
    let nutriments: Nutrients
    let servingSize: String?
    let servingWeight: Double?

    enum CodingKeys: String, CodingKey {
        case productName = "product_name"
        case nutriments
        case servingSize = "serving_size"
        case servingWeight = "serving_weight"
    }
}

struct Nutrients: Decodable {
    let energyKcal: Double?
    let proteins: Double?
    let carbohydrates: Double?
    let fat: Double?

    enum CodingKeys: String, CodingKey {
        case energyKcal = "energy-kcal_100g"
        case proteins = "proteins_100g"
        case carbohydrates = "carbohydrates_100g"
        case fat = "fat_100g"
    }
}


class USDAFoodAPIService {
    let apiKey = "add_api_key"

    func fetchUSDAFoodData(query: String, completion: @escaping (Result<[FoodItem], Error>) -> Void) {
        let refinedQuery = query.replacingOccurrences(of: " ", with: "%20")
        let urlString = "https://api.nal.usda.gov/fdc/v1/foods/search?query=\(refinedQuery)&api_key=\(apiKey)"

        guard let url = URL(string: urlString) else {
            completion(.failure(APIError.invalidURL))
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(APIError.noData))
                return
            }

            do {
            
                let decodedResponse = try JSONDecoder().decode(USDAFoodResponse.self, from: data)
                let foodItems = decodedResponse.foods.map { item in
                    FoodItem(
                        id: UUID().uuidString,
                        name: item.description,
                        calories: item.foodNutrients.first(where: { $0.nutrientName == "Energy" })?.value ?? 0.0,
                        protein: item.foodNutrients.first(where: { $0.nutrientName == "Protein" })?.value ?? 0.0,
                        carbs: item.foodNutrients.first(where: { $0.nutrientName == "Carbohydrate, by difference" })?.value ?? 0.0,
                        fats: item.foodNutrients.first(where: { $0.nutrientName == "Total lipid (fat)" })?.value ?? 0.0,
                        servingSize: "N/A",
                        servingWeight: 0.0
                    )
                }
                completion(.success(foodItems))
            } catch {
                completion(.failure(APIError.decodingError))
            }
        }.resume()
    }
}


struct USDAFoodResponse: Decodable {
    let foods: [USDAFoodItem]
}

struct USDAFoodItem: Decodable {
    let description: String
    let foodNutrients: [USDANutrient]
}

struct USDANutrient: Decodable {
    let nutrientName: String
    let value: Double
}
