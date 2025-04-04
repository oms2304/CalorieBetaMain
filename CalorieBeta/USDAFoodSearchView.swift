import SwiftUI
import FirebaseFirestore

struct USDAFoodSearchView: View {
    @Binding var dailyLog: DailyLog?
    var onLogUpdated: (DailyLog) -> Void
    
    @Environment(\.dismiss) var dismiss
    @State private var searchQuery = ""
    @State private var searchResults: [FoodItem] = []
    @State private var isLoading = false
    
    private let foodAPIService = USDAFoodAPIService()
    
    var body: some View {
        VStack {
            TextField("Search for food...", text: $searchQuery, onCommit: performSearch)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            Button(action: performSearch) {
                Text("Search")
                    .font(.title2)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding(.horizontal)
            }
            
            if isLoading {
                ProgressView("Searching...")
                    .padding()
            }
            
            List(searchResults, id: \.id) { foodItem in
                VStack(alignment: .leading) {
                    Text(foodItem.name)
                        .font(.headline)
                    Text("\(foodItem.calories, specifier: "%.0f") kcal")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .onTapGesture {
                    addFoodToLog(foodItem)
                }
            }
            
            Spacer()
        }
        .navigationTitle("Search Food")
        .navigationBarItems(trailing: Button("Cancel") {
            dismiss()
        })
        .padding()
    }
    
    private func performSearch() {
        guard !searchQuery.isEmpty else { return }
        isLoading = true
        
        foodAPIService.fetchUSDAFoodData(query: searchQuery) { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success(let foodItems):
                    searchResults = foodItems
                case .failure(let error):
                    print("Error fetching food data: \(error)")
                }
            }
        }
    }
    
    private func addFoodToLog(_ foodItem: FoodItem) {
        guard var unwrappedLog = dailyLog else {
            print("No daily log available")
            return
        }
        
        if unwrappedLog.meals.isEmpty {
           
            let newMeal = Meal(id: UUID().uuidString, name: "All Meals", foodItems: [foodItem])
            unwrappedLog.meals.append(newMeal)
        } else {
         
            unwrappedLog.meals[0].foodItems.append(foodItem)
        }
        
    
        dailyLog = unwrappedLog
        onLogUpdated(unwrappedLog)
        dismiss()
    }
}
