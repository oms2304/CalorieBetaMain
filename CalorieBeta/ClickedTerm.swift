//
//  ClickedTerm.swift
//  MyFitPlate
//
//  Created by Omar Sabeha on 13/08/2025.
//

import SwiftUI
import SwiftData

struct ClickedTerm: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    
    @EnvironmentObject var viewModel: ExerciseViewModel
    
    
    @State private var showError = false
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Favorite.name) var favorites: [Favorite]

    @State var selectedType: String
    @State private var isClicked = false
    @State private var name: String = ""
    @State private var errorMessage: String = ""
    @State private var duration: String = ""
    @State private var calories: String = ""
    @State private var selectedDate: Date = Date()
    @State private var selectedOptionIndex = 0
    @State private var showDropdown = false
    @State private var Note: String = ""
    @State var sets: String = ""
    @State var reps: String = ""
    
    @State private var searchText = ""
    let names = ["Holly", "Josh", "Rhonda", "Ted"]

    var exerciseToEdit: LoggedExercise?
//  var onSave: (LoggedExercise) -> Void
    
    @State private var isEditing: Bool = false
    @State private var alertMessage: String? = nil
    @State private var showingAlert = false
    
    @State private var deviceName: String = ""
    @State private var isWifiEnabled: Bool = false
    
    @State private var date = Date()
    
    let term: String
    
    private func saveExercise() {
        guard !name.isEmpty else {
            alertMessage = "Please enter an exercise name."
            showingAlert = true
            return
        }
        guard let caloriesValue = Double(calories), caloriesValue > 0 else {
            alertMessage = "Please enter valid calories burned (must be a number greater than 0)."
            showingAlert = true
            return
        }
        let durationMinutes = Int(duration)

        if let durationVal = durationMinutes, durationVal <= 0 && !duration.isEmpty {
            alertMessage = "Duration must be a positive number if entered."
            showingAlert = true
            return
        }

        let exercise = LoggedExercise(
            id: exerciseToEdit?.id ?? UUID().uuidString,
            name: name,
            durationMinutes: durationMinutes,
            caloriesBurned: caloriesValue,
            date: selectedDate,
            source: exerciseToEdit?.source ?? "manual"
        )

        dismiss()
    }
    
    private func addFavorite() {

        let newFavorite = Favorite(name: name, type: selectedType)
        
        
        modelContext.insert(newFavorite)
        try? modelContext.save()
        
        
        print("\(name) was added to favorites.")
    }
    

    
    
    @ViewBuilder
    private var strengthSection: some View {
        Section {
            TextField("Sets", text: $sets)
                .keyboardType(.numberPad)
            TextField("Repititions", text: $reps)
                .keyboardType(.numberPad)
            TextField("Calories Burned", text: $calories)
                .keyboardType(.numberPad)
            TextField("Duration", text: $duration)
                .keyboardType(.numberPad)
            DatePicker("Date picker", selection: $date, displayedComponents: .date)
        }
        
        .listRowBackground(colorScheme == .dark ? Color.black.opacity(0.5) : Color(UIColor.systemGray6))
    }
    
    @ViewBuilder
    private var defaultSection: some View {
        Section {
            TextField("Calories Burned", text: $calories)
                .keyboardType(.numberPad)
            TextField("Duration", text: $duration)
                .keyboardType(.numberPad)
            DatePicker("Date", selection: $date, displayedComponents: .date)
        }.onAppear  {
            if let fav = favorites.first(where: {$0.name == term }) {
                name = fav.name
    
                isClicked = true
            }
        }
        
        .listRowBackground(colorScheme == .dark ? Color.black.opacity(0.5) : Color(UIColor.systemGray6))
    }
    
    var allFieldsFilled: Bool {
        if selectedType == "Strength" {
            return !calories.trimmingCharacters(in: .whitespaces).isEmpty &&
            !duration.trimmingCharacters(in: .whitespaces).isEmpty &&
            !reps.trimmingCharacters(in: .whitespaces).isEmpty &&
            !sets.trimmingCharacters(in: .whitespaces).isEmpty
        } else {
            return
            !calories.trimmingCharacters(in: .whitespaces).isEmpty &&
            !duration.trimmingCharacters(in: .whitespaces).isEmpty
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Form {
                    if selectedType == "Strength" {
                        strengthSection
                    } else {
                        defaultSection
                    }
                    
                    Section {
                        TextField("Notes", text: $Note)
                            .padding(.bottom, 150)
                    }
                    .listRowBackground(colorScheme == .dark ? Color.black.opacity(0.5) : Color(UIColor.systemGray6))
                }
                .background(colorScheme == .dark ? Color.backgroundSecondary : .white) // Use your custom color if available
                .padding(.top, 10)
                .scrollContentBackground(.hidden)
                
                Button(isEditing ? "Update Exercise" : "Log Exercise") {
                    saveExercise()
                }
                .cornerRadius(30)
                 .buttonStyle(PrimaryButtonStyle()) // Assuming you have this defined
                .disabled(name.isEmpty || calories.isEmpty)
                .padding()
            }
            .alert("Error", isPresented: $showError) {
                Button("Ok", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }

            .onAppear {
                if favorites.contains(where: {$0.name == term }) {
                    name = term
                    isClicked = true
                } else {
                    name = term
                    isClicked = false
                }
            }
            .padding(.top, -1)
            .background(colorScheme == .light ? .white : Color.backgroundSecondary) // Use your custom color if available
            .navigationTitle("\(term)")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        if let favorite = favorites.first(where: { $0.name == term }) {
                            modelContext.delete(favorite)
                            
                            try? modelContext.save()
                            
                            isClicked.toggle()
                            errorMessage = "Exercise removed from favorites"
                            showError = true
                            
                        } else {
                            isClicked.toggle() // Toggle the star state
//                            modelContext.insert(favorite)
//                            try? modelContext.save()
                            addFavorite()}
                        
                    } label: {
                        Image(systemName: isClicked ? "star.fill" : "star")
                    }
                    .disabled(!allFieldsFilled)
                }
            }
        }
    }
}

#Preview {
    ClickedTerm(selectedType: "Cardio", term: "push ups")
        .environmentObject(ExerciseViewModel()) // Added for preview to work
}
