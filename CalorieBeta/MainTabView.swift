import SwiftUI



import FirebaseAuth







struct MainTabView: View {



    @State private var selectedTab = 0



    @State private var showingAddFoodOptions = false



    



    // Added variables from HomeView



    @State private var showingAddFoodView = false



    @State private var showingSearchView = false



    @State private var showingBarcodeScanner = false



    @State private var showingImagePicker = false



    @State private var scannedFoodName: String?



    @State private var foodPrediction: String = ""



    



    // Environment objects needed



    @EnvironmentObject var dailyLogService: DailyLogService



    



    // ML model for image classification



    private let mlModel = MLImageModel()



    



    var body: some View {



        ZStack(alignment: .bottom) {



            // Main content area



            TabView(selection: $selectedTab) {



                // Home Tab



                HomeView()



                    .tag(0)







                // AI Recipe Bot Tab



                AIChatbotView(selectedTab: $selectedTab)



                    .tag(1)



                



                // Empty view for center tab



                Color.clear



                    .tag(2)



                



                // Weight Tracking Tab



                WeightTrackingView()



                    .tag(3)



                



                // Analytics Tab



                Color(red: 0/255, green: 61/255, blue: 58/255)



                    .tag(4)



            }



            



            // Custom tab bar



            VStack {



                Spacer()



                CustomTabBar(



                    selectedTab: $selectedTab,



                    showingAddFoodOptions: $showingAddFoodOptions



                )

                .background(Color.white)

                       .ignoresSafeArea(edges: .bottom)  // This removes the extra space



            }



            



            // Overlay for the add food options menu



            if showingAddFoodOptions {



                Color.black.opacity(0.4)



                    .edgesIgnoringSafeArea(.all)



                    .onTapGesture { showingAddFoodOptions = false }



                



                VStack(spacing: 16) {



                    Button(action: {



                        showingAddFoodOptions = false



                        showingSearchView = true



                        scannedFoodName = nil



                    }) {



                        FoodOptionButton(title: "Search Food", icon: "magnifyingglass")



                    }



                    Button(action: {



                        showingAddFoodOptions = false



                        showingBarcodeScanner = true



                    }) {



                        FoodOptionButton(title: "Scan Barcode", icon: "barcode.viewfinder")



                    }



                    Button(action: {



                        showingAddFoodOptions = false



                        showingImagePicker = true



                    }) {



                        FoodOptionButton(title: "Scan Food Image", icon: "camera")



                    }



                    Button(action: {



                        showingAddFoodOptions = false



                        showingAddFoodView = true



                    }) {



                        FoodOptionButton(title: "Add Food Manually", icon: "plus.circle")



                    }



                }



                .padding()



                .background(Color.white)



                .cornerRadius(16)



                .shadow(radius: 10)



                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)



            }



        }



        .sheet(isPresented: $showingAddFoodView) {



            AddFoodView { newFood in



                if let userID = Auth.auth().currentUser?.uid {



                    dailyLogService.addFoodToCurrentLog(for: userID, foodItem: newFood)



                }



            }



        }



        .sheet(isPresented: $showingSearchView) {



            if let currentLog = dailyLogService.currentDailyLog {



                FoodSearchView(



                    dailyLog: .constant(currentLog),



                    onLogUpdated: { updatedLog in



                        dailyLogService.currentDailyLog = updatedLog



                    },



                    initialSearchQuery: scannedFoodName ?? ""



                )



            } else {



                Text("Loading...")



            }



        }



        .sheet(isPresented: $showingBarcodeScanner) {



            BarcodeScannerView { foodItem in



                DispatchQueue.main.async {



                    scannedFoodName = foodItem.name



                    showingBarcodeScanner = false



                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {



                        showingSearchView = true



                    }



                }



            }



        }



        .sheet(isPresented: $showingImagePicker) {



            ImagePicker(sourceType: .camera) { image in



                mlModel.classifyImage(image: image) { result in



                    switch result {



                    case .success(let foodName):



                        self.foodPrediction = "Predicted: \(foodName)"



                        self.scannedFoodName = foodName



                        self.showingImagePicker = false



                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {



                            self.showingSearchView = true



                        }



                    case .failure(let error):



                        self.foodPrediction = "No food recognized: \(error.localizedDescription)"



                        self.showingImagePicker = false



                    }



                }



            }



        }



    }



}







struct CustomTabBar: View {



    @Binding var selectedTab: Int



    @Binding var showingAddFoodOptions: Bool



    



    var body: some View {



        HStack(spacing: 0) {



            ForEach(0..<5) { index in



                if index == 2 {



                    // Center add button



                    Button(action: {



                        showingAddFoodOptions.toggle()



                    }) {



                        Image(systemName: "plus.circle.fill")



                            .resizable()



                            .aspectRatio(contentMode: .fit)



                            .frame(width: 35, height: 35)



                            .foregroundColor(Color(red: 0/255, green: 61/255, blue: 58/255))



                            .padding(.vertical, 8)



                    }



                    .frame(maxWidth: .infinity)



                } else {



                    // Regular tab buttons



                    let tabIndex = index



                    TabButton(



                        icon: getIcon(for: tabIndex),



                        isSelected: selectedTab == tabIndex,



                        action: { selectedTab = tabIndex }



                    )



                }



            }



        }



        .padding(.horizontal, 8)



        .padding(.top, 7)



        .padding(.bottom, 12)



        .background(Color.white)



        .cornerRadius(25, corners: [.topLeft, .topRight])



       



    }



    



    private func getIcon(for index: Int) -> String {



        switch index {



        case 0: return "house.fill"



        case 1: return "message.fill"



        case 3: return "scalemass.fill"



        case 4: return "person.2.fill"



        default: return ""



        }



    }



}







struct TabButton: View {



    let icon: String



    let isSelected: Bool



    let action: () -> Void



    



    var body: some View {



        Button(action: action) {

            

            Image(systemName: icon)

            

                .resizable()

            

                .aspectRatio(contentMode: .fit)

            

                .frame(width: 24, height: 24)

            

                .foregroundColor(isSelected ? Color(red: 0/255, green: 61/255, blue: 58/255): .gray)



                                .padding(.vertical, 8)



                        }



                        .frame(maxWidth: .infinity)



                    }



                }







                struct FoodOptionButton: View {



                    let title: String



                    let icon: String



                    



                    var body: some View {



                        HStack {



                            Image(systemName: icon)



                                .foregroundColor(.green)



                                .frame(width: 24, height: 24)



                            Text(title)



                                .foregroundColor(.black)



                                .font(.system(size: 16, weight: .medium))



                        }



                        .padding()



                        .frame(maxWidth: .infinity, alignment: .leading)



                        .background(Color.white)



                        .cornerRadius(8)



                        .overlay(



                            RoundedRectangle(cornerRadius: 8)



                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)



                        )



                    }



                }







                // Extension for rounded corners



                extension View {



                    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {



                        clipShape(RoundedCorner(radius: radius, corners: corners))



                    }



                }







                struct RoundedCorner: Shape {



                    var radius: CGFloat = .infinity



                    var corners: UIRectCorner = .allCorners







                    func path(in rect: CGRect) -> Path {



                        let path = UIBezierPath(



                            roundedRect: rect,



                            byRoundingCorners: corners,



                            cornerRadii: CGSize(width: radius, height: radius)



                        )



                        return Path(path.cgPath)



                    }



                }

struct ActionButtonLabel: View {
    let title: String
    let icon: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24, height: 24)

            Text(title)
                .foregroundColor(.black)
                .font(.headline)

            Spacer()
        }
        .padding()
        .background(Color.gray.opacity(0.2))
        .cornerRadius(12)
    }
}
