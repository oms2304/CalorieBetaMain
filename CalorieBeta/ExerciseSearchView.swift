import SwiftUI
import SwiftData

struct ExerciseSearchView: View {
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var viewModel = ExerciseViewModel()   // ✅ Use VM
    @Environment(\.modelContext) private var context
    @State private var showError = false

    @Query(sort: \Favorite.name) var favorites: [Favorite]
    
    @State private var exerciseType = ["Cardio", "Strength"]
    @State private var selectedType = "Cardio"
    @State private var searchText = ""
    @State private var exercises: [Exercise] = []
    
    var filteredExercises: [Exercise] {
        let matchingTypeExercises = exercises.filter { $0.type == selectedType }
        
        if searchText.isEmpty {
            return Array(matchingTypeExercises.prefix(10))
        } else {
            return matchingTypeExercises.filter { $0.name.lowercased().contains(searchText.lowercased()) }
        }
    }
    
    func loadExercises() -> [Exercise] {
        guard let url = Bundle.main.url(forResource: "Exercises", withExtension: "json")
        else {
            print("❌ Failed to find exercises.json in bundle")
            return [] }
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            return try decoder.decode([Exercise].self, from: data)
        } catch { print("❌ Failed to decode exercises.json: \(error)")
            return [] }
    }
    
    
    var body: some View {
        NavigationStack {
            ZStack {
                listBGColor.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
//                    HStack {
//                        Text("Exercises")
//                            .font(.largeTitle.bold())
//                        Spacer()
//
//                    }
//                    .padding(.horizontal)
//                    .padding(.bottom, 8)
//                    .padding(.top, 10)
//                    
                    // Picker
                    Picker("Exercise Type", selection: $selectedType) {
                        ForEach(exerciseType, id: \.self) { type in
                            Text(type)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding()
                    .background(listBGColor)
                    
                    // List
                    listContent
                }
            }.searchable(text: $searchText)
//            .navigationBarHidden(true)
                .navigationTitle("Exercises")
            
            .toolbarBackground(listBGColor, for: .navigationBar)
            .onAppear {
                exercises = loadExercises()
                print("⭐️ Favorites count:", favorites.count)
                favorites.forEach { print("   → \($0.name)") }
            }

        }
        
    }
    
    private var listBGColor: Color {
        colorScheme == .dark ? Color.backgroundSecondary : .white
    }
    
    private func deleteFavorite(indexes: IndexSet) {
        for index in indexes {
            context.delete(favorites[index])
        }
    }
    
    @ViewBuilder
    private var listContent: some View {
            List {
                Section(header: Text("Favorites").font(.subheadline).padding(.leading, -15)) {
                    if favorites.isEmpty {
                        Text("Add your favorite exercises!")
                            .listRowBackground(colorScheme == .dark ? Color.backgroundSecondary : .white )
                            .foregroundColor(colorScheme == .dark ? Color(UIColor.systemGray) : Color(UIColor.systemGray))
                            .font(.footnote)
                            .padding(.leading, 60)
//                            .padding(.trailing, -30)
                        
                    } else {
                        ForEach(favorites){ favorite in
                            NavigationLink(destination: ClickedTerm(selectedType: selectedType, term: favorite.name)) {
                                Text(favorite.name)
                            }.listRowBackground(colorScheme == .dark ? Color.black.opacity(0.4) : Color(UIColor.systemGray6))
                            
                        }.onDelete(perform: deleteFavorite(indexes: ))
                    }
                }
                
                Section(header: Text("Exercises").font(.subheadline).padding(.leading, -15)){
                    ForEach(filteredExercises, id: \.self) { exercise in
                        NavigationLink(destination: ClickedTerm(selectedType: selectedType, term: exercise.name)) {
                            if exercise.type == selectedType {
                                Text(exercise.name)
                            }
                            
                        }
                                        .listRowBackground(colorScheme == .dark ? Color.black.opacity(0.4) : Color(UIColor.systemGray6))
                                        
                    }
                }
            }
            
            .padding(.top, -20)
            .scrollContentBackground(.hidden)
            .background(listBGColor)
            
        }
}


#Preview {
    ExerciseSearchView()
}
