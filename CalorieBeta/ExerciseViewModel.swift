//
//  ExerciseViewModel.swift
//  MyFitPlate
//
//  Created by Omar Sabeha on 09/08/2025.
//
import Foundation
import Combine

class ExerciseViewModel: ObservableObject {
    @Published var exercises: [Exercise] = []
    
    
    func addToFavorites(name: String, type: String, duration: String, calories: String) {
        loadFavorites()
        
        let newExercise = Exercise(
            name: name,
            type: type,
            duration: duration,
            calories: calories
        )
        
        if !exercises.contains(where: {
            $0.name.lowercased() == newExercise.name.lowercased() &&
            $0.type.lowercased() == newExercise.type.lowercased()
            
        }) {
            exercises.append(newExercise)
            save(exercises: exercises)
        }
        
    }
    
    
    
    func loadFavorites() {
        if let data = UserDefaults.standard.data(forKey: "exercises"),
           let decoded = try? JSONDecoder().decode([Exercise].self, from: data) {
            exercises = decoded
        }
    }
    
    
    func save(exercises: [Exercise]) {
        if let encoded = try? JSONEncoder().encode(exercises) {
            UserDefaults.standard.set(encoded, forKey:  "exercises")
        }
    }
    
    func delete(at offsets: IndexSet) {
        exercises.remove(atOffsets: offsets)
        save(exercises: exercises)
        
        if exercises.isEmpty {
            UserDefaults.standard.removeObject(forKey: "exercises")
        }
    }
    
    
    

}


struct Exercise: Codable, Identifiable, Hashable {
    let id = UUID()
    let name: String
    let type: String
    let duration: String?
    let calories: String?
}
