import SwiftUI
import Toasts


struct Food: Codable{
    let type: String
    let name: String
}


private struct SwipeableFoodItemView: View {
    let initialFoodItem: FoodItem
    @Binding var dailyLog: DailyLog?
    let onDelete: (String) -> Void
    let onLogUpdated: () -> Void
    let date: Date
    @State private var offset: CGFloat = 0
    @State private var isSwiped: Bool = false
    @State private var showDetailView = false
    @Environment(\.colorScheme) var colorScheme


    var body: some View {
        ZStack(alignment: .trailing) {
            NavigationLink(destination: FoodDetailView(initialFoodItem: initialFoodItem, dailyLog: $dailyLog, date: date, source: "log_swipe", onLogUpdated: onLogUpdated ), isActive: $showDetailView) { EmptyView() }.opacity(0)
            if isSwiped { HStack { Spacer(); Button { withAnimation(.easeInOut) { onDelete(initialFoodItem.id); offset = 0; isSwiped = false } } label: { Image(systemName: "trash").foregroundColor(.white).frame(width: 60, height: 50, alignment: .center) }.buttonStyle(PlainButtonStyle()).background(Color.red).contentShape(Rectangle()).cornerRadius(8) }.padding(.vertical, 2).transition(.move(edge: .trailing).combined(with: .opacity)) }
            VStack {
                HStack {
                    Text(FoodEmojiMapper.getEmoji(for: initialFoodItem.name) + " " + initialFoodItem.name)
                        .lineLimit(1)
                        .appFont(size: 17)
                        .foregroundColor(.textPrimary)
                    Spacer()
                    Text("\(Int(initialFoodItem.calories)) cal")
                        .appFont(size: 15)
                        .foregroundColor(Color(UIColor.secondaryLabel))
                }
                .padding(.vertical, 18)
                .padding(.horizontal)
                .background(Color.clear)
                .cornerRadius(10)
                .contentShape(Rectangle())
                .offset(x: offset)
                .onTapGesture { if !isSwiped { showDetailView = true } else { withAnimation(.easeInOut) { offset = 0; isSwiped = false } } }
                .gesture( DragGesture().onChanged { value in if value.translation.width < 0 { offset = max(value.translation.width, -70) } else if isSwiped && value.translation.width > 0 { offset = -70 + value.translation.width } }.onEnded { value in withAnimation(.easeInOut) { if value.translation.width < -50 { offset = -70; isSwiped = true } else { offset = 0; isSwiped = false } } } )
                
            }
        }
        .padding(.bottom, 1)
    }
}


struct AddFoodView: View {
    var onFoodLogged: (FoodItem) -> Void
    
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var dailyLogService: DailyLogService

    @State private var foodName = ""
    @State private var calories = ""
    @State private var protein = ""
    @State private var carbs = ""
    @State private var fats = ""
    @State private var searchText = ""
    @State private var selectedMeal: String = "Breakfast"
    @State private var foodType = ["Breakfast","Lunch","Dinner"]
    
    let breakfastFoods: [FoodItem] = [
        FoodItem(
            id: UUID().uuidString,
            name: "Banana",
            calories: 105,
            protein: 1.3,
            carbs: 27,
            fats: 0.3,
            servingSize: "1 medium (118g)",
            servingWeight: 118
        ),
        FoodItem(
            id: UUID().uuidString,
            name: "Toast",
            calories: 75,
            protein: 2.5,
            carbs: 13,
            fats: 1,
            servingSize: "1 slice (28g)",
            servingWeight: 28
        ),
        FoodItem(
            id: UUID().uuidString,
            name: "Eggs",
            calories: 70,
            protein: 6,
            carbs: 0.4,
            fats: 5,
            servingSize: "1 large (50g)",
            servingWeight: 50
        ),
        FoodItem(
            id: UUID().uuidString,
            name: "Apple",
            calories: 95,
            protein: 0.5,
            carbs: 25,
            fats: 0.3,
            servingSize: "1 medium (182g)",
            servingWeight: 182
        ),
        FoodItem(
            id: UUID().uuidString,
            name: "Milk",
            calories: 103,
            protein: 8,
            carbs: 12,
            fats: 2.4,
            servingSize: "1 cup (244g)",
            servingWeight: 244
        )
    ]
    let lunchFoods: [FoodItem] = [
        FoodItem(
            id: UUID().uuidString,
            name: "Grilled Chicken Breast",
            calories: 165,
            protein: 31,
            carbs: 0,
            fats: 3.6,
            servingSize: "3 oz (85g)",
            servingWeight: 85
        ),
        FoodItem(
            id: UUID().uuidString,
            name: "Brown Rice",
            calories: 216,
            protein: 5,
            carbs: 45,
            fats: 1.8,
            servingSize: "1 cup (195g)",
            servingWeight: 195
        ),
        FoodItem(
            id: UUID().uuidString,
            name: "Steamed Broccoli",
            calories: 55,
            protein: 3.7,
            carbs: 11,
            fats: 0.6,
            servingSize: "1 cup (156g)",
            servingWeight: 156
        ),
        FoodItem(
            id: UUID().uuidString,
            name: "Avocado",
            calories: 234,
            protein: 3,
            carbs: 12,
            fats: 21,
            servingSize: "1 avocado (200g)",
            servingWeight: 200
        ),
        FoodItem(
            id: UUID().uuidString,
            name: "Greek Yogurt (Plain, Nonfat)",
            calories: 100,
            protein: 17,
            carbs: 6,
            fats: 0,
            servingSize: "6 oz (170g)",
            servingWeight: 170
        )
    ]
    let dinnerFoods: [FoodItem] = [
        FoodItem(
            id: UUID().uuidString,
            name: "Salmon (Baked)",
            calories: 233,
            protein: 25,
            carbs: 0,
            fats: 14,
            servingSize: "4 oz (113g)",
            servingWeight: 113
        ),
        FoodItem(
            id: UUID().uuidString,
            name: "Quinoa (Cooked)",
            calories: 222,
            protein: 8,
            carbs: 39,
            fats: 3.6,
            servingSize: "1 cup (185g)",
            servingWeight: 185
        ),
        FoodItem(
            id: UUID().uuidString,
            name: "Roasted Sweet Potatoes",
            calories: 180,
            protein: 2,
            carbs: 41,
            fats: 0.3,
            servingSize: "1 cup (200g)",
            servingWeight: 200
        ),
        FoodItem(
            id: UUID().uuidString,
            name: "Sauteed Spinach",
            calories: 75,
            protein: 3.8,
            carbs: 6.7,
            fats: 5.3,
            servingSize: "1 cup (180g)",
            servingWeight: 180
        ),
        FoodItem(
            id: UUID().uuidString,
            name: "Lentil Soup",
            calories: 185,
            protein: 12,
            carbs: 30,
            fats: 3.6,
            servingSize: "1 cup (240g)",
            servingWeight: 240
        )
    ]




//    @State private var breakfastFoods = ["Banana", "Toast", "Eggs", "Apple", "Milk"]
    @State private var showingBarcodeScanner = false
    @State private var selectedDate: Date = Calendar.current.startOfDay(for: Date())
    
    @Environment(\.presentToast) var presentToast
    
    @State private var selectedTab = 1
    
    @State private var image: String = "food"
    @State private var title: String = "title"
    @State private var subtitle: String = "subtitle"

    @State private var showingImagePicker = false
    @State private var isProcessingLabel = false
    @State private var scanError: (Bool, String) = (false, "")
    @State private var isProcessingImage = false
    @State private var foods : [Food] = []
    
    @State private var showingAskMaiaPage = false
    
    @State private var scannedFoodItem: FoodItem? = nil
    @State private var estimatedFoodItems: [FoodItem]? = nil
    
    private let foodAPIService = FatSecretFoodAPIService()
    
    private var listBGColor: Color {
        colorScheme == .dark ? Color.backgroundSecondary : .white
    }
    private var plusColor: Color {
        colorScheme == .dark ? .white : .white
    }
    
    private let imageModel = MLImageModel()
    @Environment(\.dismiss) var dismiss
    
    var filteredFoods: [Food] {
        let matchingTypeExercises = foods.filter { $0.type == selectedMeal}
        
        if searchText.isEmpty {
            return Array(matchingTypeExercises.prefix(10))
        } else {
            return matchingTypeExercises.filter { $0.name.lowercased().contains(searchText.lowercased()) }
        }
    }
    
    private func logRecommended(_ food: FoodItem) {
        onFoodLogged(food)

    }
    
    struct GrowingButton: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .padding()
                .background(Color.brandPrimary)
                .foregroundStyle(.white)
                .clipShape(Capsule())
                .scaleEffect(configuration.isPressed ? 1.2 : 1)
                .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
        }
    }
    
    @State private var showingAddFoodManually = false
        
    
   
    
    @ViewBuilder
    private func foodDiaryGroupedContent(meals: [Meal]) -> some View {
        VStack(alignment: .leading, spacing: 15) {
            ForEach(Array(meals.enumerated()), id: \.element.id) { index, meal in
                if !meal.foodItems.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
//                        Text(meal.name)
//                            .appFont(size: 20, weight: .semibold)
                        
                        VStack(spacing: 0) {
                            ForEach(meal.foodItems) { foodItem in
                                SwipeableFoodItemView(
                                    initialFoodItem: foodItem,
                                    dailyLog: $dailyLogService.currentDailyLog,
                                    onDelete: { itemID in self.deleteFood(byID: itemID) },
                                    onLogUpdated: { },
                                    date: self.selectedDate
                                )
                            }
                        }
                    }
                }
            }
        }
    }
    
    private var breakfastRecommendedSection: some View {
        Section(header:Text("Recommended")) {
            ForEach(breakfastFoods, id: \.id) { food in
                HStack(spacing: 15) {
                    if colorScheme == .light {
                        Text(FoodEmojiMapper.getEmoji(for: food.name))
                            .lineLimit(1)
                            .appFont(size: 17)
                            .foregroundColor(.textPrimary)
//                            .resizable()
                            .scaledToFit()
                            .frame(width:30, height:30)
                            .padding(5)
//                                        .clipShape(Circle())
                    } else {
                        Text(FoodEmojiMapper.getEmoji(for: food.name))
                            .lineLimit(1)
                            .appFont(size: 17)
                            .foregroundColor(.textPrimary)
//                            .resizable()
                            .scaledToFit()
                            .frame(width:30, height:30)
                            .padding(5)
//                                        .clipShape(Circle())
                            
                    }
                    
                    VStack(alignment: .leading){
                        Text("\(food.name)")
                        Text("\(Int(food.calories)) cal")
                            .font(.caption)
                            .foregroundColor(.brandPrimary)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        logRecommended(food)
                        let toast = ToastValue(
                            icon:
                                Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green),
                            message: "Food Logged!"
                        )
                        presentToast(toast)
                    }){
                        Image(systemName: "plus")
                            .resizable()
                            .scaledToFit()
                            .frame(width:15, height:15)
//                                        .padding(10)
//                                        .background(Color.brandPrimary)
//                                        .foregroundStyle(plusColor)
//                                        .clipShape(Circle())
                    }
                    .buttonStyle(GrowingButton())
                }
                .contentShape(Rectangle())
            }
        }
    }
    private var lunchRecommendedSection: some View {
        Section(header:Text("Recommended")) {
            ForEach(lunchFoods, id: \.id) { food in
                HStack(spacing: 15) {
                    if colorScheme == .light {
                        Text(FoodEmojiMapper.getEmoji(for: food.name))
                            .lineLimit(1)
                            .appFont(size: 17)
                            .foregroundColor(.textPrimary)
//                            .resizable()
                            .scaledToFit()
                            .frame(width:30, height:30)
                            .padding(5)
//                                        .clipShape(Circle())
                    } else {
                        Text(FoodEmojiMapper.getEmoji(for: food.name))
                            .lineLimit(1)
                            .appFont(size: 17)
                            .foregroundColor(.textPrimary)
//                            .resizable()
                            .scaledToFit()
                            .frame(width:30, height:30)
                            .padding(5)
//                                        .clipShape(Circle())
                            
                    }
                    
                    VStack(alignment: .leading){
                        Text("\(food.name)")
                        Text("\(Int(food.calories)) cal")
                            .font(.caption)
                            .foregroundColor(.brandPrimary)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        logRecommended(food)
                        let toast = ToastValue(
                            icon:
                                Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green),
                            message: "Food Logged!"
                        )
                        presentToast(toast)
                    }){
                        Image(systemName: "plus")
                            .resizable()
                            .scaledToFit()
                            .frame(width:15, height:15)
//                                        .padding(10)
//                                        .background(Color.brandPrimary)
//                                        .foregroundStyle(plusColor)
//                                        .clipShape(Circle())
                    }
                    .buttonStyle(GrowingButton())
                    
                }
                .contentShape(Rectangle())
            }
        }
    }
    
    private var addManually: some View {
        ZStack {
            NavigationView {
                VStack {
                    Form {
                        Section(header: Text("Nutritional Information"), footer: Text("Tap the camera icon to scan a nutrition label automatically.")) {
                            HStack {
                                TextField("Food Name", text: $foodName)
                                Button {
                                    showingImagePicker = true
                                } label: {
                                    Image(systemName: "camera.fill")
                                        .font(.title2)
                                        .foregroundColor(.brandPrimary)
                                }
                            }
                            
                            TextField("Calories (kcal)", text: $calories)
                                .keyboardType(.decimalPad)
                            TextField("Protein (g)", text: $protein)
                                .keyboardType(.decimalPad)
                            TextField("Carbs (g)", text: $carbs)
                                .keyboardType(.decimalPad)
                            TextField("Fats (g)", text: $fats)
                                .keyboardType(.decimalPad)
                        }
                    }
                    
                    Button(action: {
                        logFood()
                        HapticManager.instance.feedback(.heavy)
                    }) {
                        Text("Log Food")
                    }
                    
                    
                    .buttonStyle(PrimaryButtonStyle())
                    .padding()
                    .disabled(foodName.isEmpty || calories.isEmpty)
                }
                .navigationTitle("Add Food Manually")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                    }
                }
                .sheet(isPresented: $showingImagePicker) {
                    ImagePicker(sourceType: .camera) { image in
                        self.isProcessingLabel = true
                        imageModel.parseNutritionLabel(from: image) { result in
                            self.isProcessingLabel = false
                            switch result {
                            case .success(let nutrition):
                                // Populate the view's state with the results
                                self.foodName = nutrition.foodName
                                self.calories = String(format: "%.0f", nutrition.calories)
                                self.protein = String(format: "%.1f", nutrition.protein)
                                self.carbs = String(format: "%.1f", nutrition.carbs)
                                self.fats = String(format: "%.1f", nutrition.fats)
                            case .failure(let error):
                                self.scanError = (true, "Could not read the nutrition label. Please try again. Error: \(error.localizedDescription)")
                            }
                        }
                    }
                }
                .alert("Scan Error", isPresented: $scanError.0) {
                    Button("OK") { }
                } message: {
                    Text(scanError.1)
                }
            }
            
            if isProcessingLabel {
                Color.black.opacity(0.4).edgesIgnoringSafeArea(.all)
                ProgressView("Reading Label...")
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .foregroundColor(.white)
                    .scaleEffect(1.5)
            }
            
        }
       
    }
    private var DinnerRecommendedSection: some View {
        Section(header:Text("Recommended")) {
            ForEach(dinnerFoods, id: \.id) { food in
                HStack(spacing: 15) {
                    if colorScheme == .light {
                        Text(FoodEmojiMapper.getEmoji(for: food.name))
                            .lineLimit(1)
                            .appFont(size: 17)
                            .foregroundColor(.textPrimary)
//                            .resizable()
                            .scaledToFit()
                            .frame(width:30, height:30)
                            .padding(5)
//                                        .clipShape(Circle())
                    } else {
                        Text(FoodEmojiMapper.getEmoji(for: food.name))
                            .lineLimit(1)
                            .appFont(size: 17)
                            .foregroundColor(.textPrimary)
                            .scaledToFit()
                            .frame(width:30, height:30)
                            .padding(5)
                    }
                    
                    VStack(alignment: .leading){
                        Text("\(food.name)")
                        Text("\(Int(food.calories)) cal")
                            .font(.caption)
                            .foregroundColor(.brandPrimary)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        logRecommended(food)
                        let toast = ToastValue(
                            icon:
                                Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green),
                            message: "Food Logged!"
                        )
                        presentToast(toast)
                    }){
                        Image(systemName: "plus")
                            .resizable()
                            .scaledToFit()
                            .frame(width:15, height:15)
//                                        .padding(10)
//                                        .background(Color.brandPrimary)
//                                        .foregroundStyle(plusColor)
//                                        .clipShape(Circle())
                    }
                    .buttonStyle(GrowingButton())
                    
                }
                .contentShape(Rectangle())
            }
        }
    }
    
    private var recentSection: some View {
        Section(header: Text("Recent")){
            VStack(alignment: .leading, spacing: 15) {
                
                let logForDisplay = (dailyLogService.currentDailyLog != nil && Calendar.current.isDate(dailyLogService.currentDailyLog!.date, inSameDayAs: selectedDate)) ? dailyLogService.currentDailyLog : nil
                
                if(logForDisplay?.meals.flatMap({ $0.foodItems }).isEmpty ?? true) {
                    Text("Recently logged meals will show up here!")
                        .foregroundColor(Color(UIColor.secondaryLabel))
                        .appFont(size: 15)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                } else {
                    foodDiaryGroupedContent(meals: logForDisplay?.meals ?? [])
                    if let exercises = dailyLogService.currentDailyLog?.exercises,
                       !exercises.isEmpty {
                        Divider().padding(.vertical, 8)
                        
                    }
                }
            }
        }
    }
    
    private var listSection: some View {
        VStack {
            if selectedMeal == "Breakfast" {
                List {
                    breakfastRecommendedSection
                    
                    recentSection
                    //                                DiarySection
                }
                .listStyle(.insetGrouped)
            } else if selectedMeal == "Lunch" {
                List {
                    lunchRecommendedSection
                    
                    recentSection
                    //                                DiarySection
                }
                .listStyle(.insetGrouped)

            } else {
                List {
                    DinnerRecommendedSection
                    
                    recentSection
                    //                                DiarySection
                }
                .listStyle(.insetGrouped)

            }

        }
    }
     
    private func deleteFood(byID id: String) {
        if var currentLog = dailyLogService.currentDailyLog {
            for mealIndex in currentLog.meals.indices {
                currentLog.meals[mealIndex].foodItems.removeAll { $0.id == id }
            }
            dailyLogService.currentDailyLog = currentLog
        }
    }
    
    private var barcodeScannerSheet: some View {
        BarcodeScannerView { barcode in
            self.showingBarcodeScanner = false
            
            foodAPIService.fetchFoodByBarcode(barcode: barcode) { result in
                
                switch result {
                case .success(let foodItem):
                    self.scannedFoodItem = foodItem
                case .failure(let error):
                    self.scanError = (true, "Could not find a food for this barcode. Error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func scannedFoodSheet(for foodItem: FoodItem) -> some View {
        NavigationView {
            FoodDetailView(
                initialFoodItem: foodItem,
                dailyLog: $dailyLogService.currentDailyLog,
                date: dailyLogService.activelyViewedDate,
                source: "barcode_result",
                onLogUpdated: { self.scannedFoodItem = nil }
            )
        }
    }
    
    private var imagePicker: some View {
        ImagePicker(sourceType: .camera) { image in
            self.isProcessingImage = true
            imageModel.estimateNutritionFromImage(image: image) { result in
                self.isProcessingImage = false
                switch result {
                case .success(let foodItems):
                    self.estimatedFoodItems = foodItems
                case .failure(let error):
                    self.scanError = (true, "Could not analyze the image. Error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private var DiarySection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Recent")
                .appFont(size: 22, weight: .bold)
            
            let logForDisplay = (dailyLogService.currentDailyLog != nil && Calendar.current.isDate(dailyLogService.currentDailyLog!.date, inSameDayAs: selectedDate)) ? dailyLogService.currentDailyLog : nil
            
            if(logForDisplay?.meals.flatMap({ $0.foodItems }).isEmpty ?? true) {
                Text("Recently logged meals will show up here!")
                    .foregroundColor(Color(UIColor.secondaryLabel))
                    .appFont(size: 15)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                foodDiaryGroupedContent(meals: logForDisplay?.meals ?? [])
                if let exercises = dailyLogService.currentDailyLog?.exercises,
                   !exercises.isEmpty {
                    Divider().padding(.vertical, 8)
                    
                }
            }
        }
    }

    var body: some View {
        ZStack {
            NavigationView {
                VStack {
                    HStack {
                        Button(action: {self.showingImagePicker = true}){
                            Label {
                                Text("Camera")
                                    .foregroundStyle(.white)
                            }
                            icon: {
                                Image(systemName: "camera").foregroundStyle(.white)
                            }
                                .padding()
                                .background(Color.brandPrimary)
                                .cornerRadius(10)
                        }
                        
                        Button(action: {self.showingBarcodeScanner = true}){
                            Label {
                                Text("Scan")
                                    .foregroundStyle(.white)
                            }
                            icon: {
                                Image(systemName: "barcode").foregroundStyle(.white)
                            }
                                .padding()
                                .background(Color.brandPrimary)
                                .cornerRadius(10)
                        }
                        
                        Button(action: {self.showingAskMaiaPage = true}){
                            Label {
                                Text("Ask Maia!")
                                    .foregroundStyle(.white)
                            }
                            icon: {
                                Image(systemName: "person.fill.questionmark").foregroundStyle(.white)
                            }
                            .padding()
                            .background(Color.brandPrimary)
                            .cornerRadius(10)
                        }
                    }
                    .sheet(isPresented: $showingBarcodeScanner) {
                        barcodeScannerSheet
                    }

                    .sheet(isPresented: $showingImagePicker) {
                        imagePicker
                    }
                    
                    .sheet(isPresented: $showingAddFoodManually) {
                      addManually
                    }
                    .sheet(isPresented: $showingAskMaiaPage) {
                        AskMaiaView()
                    }
                    
                    Picker("Food Type", selection: $selectedMeal) {
                        ForEach(foodType, id: \.self) { type in
                            Text(type)
                        }
                    }
                    .padding()
                    .pickerStyle(SegmentedPickerStyle())
                    
                    listSection

                    Spacer()

                    Button {
                        self.showingAddFoodManually = true
                    } label: {
                        Text("Add new")
                    }
                    .sheet(isPresented: $showingAddFoodManually){
                        addManually
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .padding()
//                    .disabled(foodName.isEmpty || calories.isEmpty)
                }
                
                .searchable(text: $searchText)
                .navigationTitle("Log Food")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                    }
                }

                .alert("Scan Error", isPresented: $scanError.0) {
                    Button("OK") { }
                } message: {
                    Text(scanError.1)
                }
            }
            
            if isProcessingLabel {
                Color.black.opacity(0.4).edgesIgnoringSafeArea(.all)
                ProgressView("Reading Label...")
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .foregroundColor(.white)
                    .scaleEffect(1.5)
            }
        }
        
    }

    private func logFood() {
        guard !foodName.isEmpty, let caloriesValue = Double(calories) else {
            return
        }

        let proteinValue = Double(protein) ?? 0.0
        let carbsValue = Double(carbs) ?? 0.0
        let fatsValue = Double(fats) ?? 0.0

        let newFood = FoodItem(
            id: UUID().uuidString,
            name: foodName,
            calories: caloriesValue,
            protein: proteinValue,
            carbs: carbsValue,
            fats: fatsValue,
            servingSize: "1 serving",
            servingWeight: 0.0
        )

        onFoodLogged(newFood)
        dismiss()
    }
}

#Preview {
    AddFoodView(onFoodLogged: { _ in
        print("Food logged in preview")
    }).environmentObject(DailyLogService())
}
