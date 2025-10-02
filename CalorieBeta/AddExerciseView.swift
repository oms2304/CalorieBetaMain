import SwiftUI

struct AddExerciseView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    
    @State private var exerciseName: String = ""
    @State private var duration: String = ""
    @State private var caloriesBurned: String = ""
    @State private var selectedDate: Date = Date()
    @State private var selectedOptionIndex = 0
    @State private var showDropdown = false

    
    @State private var searchText = ""
    let names = ["Holly", "Josh", "Rhonda", "Ted"]

    var exerciseToEdit: LoggedExercise?
    var onSave: (LoggedExercise) -> Void
    
    @State private var isEditing: Bool = false
    @State private var alertMessage: String? = nil
    @State private var showingAlert = false

    init(exerciseToEdit: LoggedExercise? = nil, onSave: @escaping (LoggedExercise) -> Void) {
        self.exerciseToEdit = exerciseToEdit
        self.onSave = onSave
        
        if let exercise = exerciseToEdit {
            _exerciseName = State(initialValue: exercise.name)
            _duration = State(initialValue: exercise.durationMinutes != nil ? "\(exercise.durationMinutes!)" : "")
            _caloriesBurned = State(initialValue: "\(Int(exercise.caloriesBurned))")
            _selectedDate = State(initialValue: exercise.date)
            _isEditing = State(initialValue: true)
        } else {
             _exerciseName = State(initialValue: "")
             _duration = State(initialValue: "")
             _caloriesBurned = State(initialValue: "")
             _selectedDate = State(initialValue: Date())
             _isEditing = State(initialValue: false)
        }
    }
    var searchResults: [String] {
           if searchText.isEmpty {
               return names
           } else {
               return names.filter { $0.contains(searchText) }
           }
       }

    var body: some View {
        NavigationView {
            VStack {
                ExerciseSearchView()
            
                                
            }
            
//                VStack {
//                    ZStack {
//                        Rectangle()
//                            .fill(Color.backgroundSecondary)
//                            .cornerRadius(20)
//                            .frame(width: UIScreen.main.bounds.width * 0.9, height: UIScreen.main.bounds.height * 0.55)
//                        
//                        
//                        VStack(){
//                            Section(header: Text("Exercise Details")) {
////                                TextField("Exercise Name (e.g., Running)", text: $exerciseName)
////                                    .textFieldStyle(AppTextFieldStyle(iconName: "figure.walk"))
////                                    .padding()
//                                
//                                
//                                
//                                Divider()
//                                
//                                HStack {
//                                    TextField("Duration", text: $duration)
//                                        .keyboardType(.numberPad)
//                                        .textFieldStyle(AppTextFieldStyle(iconName: "clock"))
//                                    Text("min")
//                                }
//                                .padding()
//                                Divider()
//                                
//                                HStack {
//                                    TextField("Calories Burned", text: $caloriesBurned)
//                                        .keyboardType(.numberPad)
//                                        .textFieldStyle(AppTextFieldStyle(iconName: "flame.fill"))
//                                    Text("kcal")
//                                }
//                                .padding()
//                                
//                                Divider()
//                                
//                                DatePicker("Date", selection: $selectedDate, displayedComponents: .date)
//                            }
//                            
//                        }
//                        .padding(.top, -150)
//                        .padding(.bottom, -180)
//                        .padding()
//                    }
//                    
//                    
//
//                
//                
//            }
            .padding()
           
            .navigationTitle(isEditing ? "Edit Exercise" : "Add Exercise")
            .background(colorScheme == .dark ? Color.backgroundSecondary : .white )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert("Input Error", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage ?? "An unknown error occurred.")
            }
        }
        .background(Color.brandSecondary.opacity(0.5)) // covers safe areas too
    }

    private func saveExercise() {
        guard !exerciseName.isEmpty else {
            alertMessage = "Please enter an exercise name."
            showingAlert = true
            return
        }
        guard let calories = Double(caloriesBurned), calories > 0 else {
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
            name: exerciseName,
            durationMinutes: durationMinutes,
            caloriesBurned: calories,
            date: selectedDate,
            source: exerciseToEdit?.source ?? "manual"
        )
        onSave(exercise)
        dismiss()
    }
}

struct AddExerciseView_Previews: PreviewProvider {
    static var previews: some View {
        AddExerciseView(exerciseToEdit: nil) { newExercise in
            print("saved new exercise: \(newExercise)")
        }
        
        AddExerciseView(
            exerciseToEdit: LoggedExercise(
                id: UUID().uuidString,
                name: "Running",
                durationMinutes: 30,
                caloriesBurned: 250,
                date: Date(),
                source: "manual"
            )
        ) { updatedExercise in
            print("Updated exercise: \(updatedExercise)")
        }
    }
}
