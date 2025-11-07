import SwiftUI
import Charts
import FirebaseAuth

struct ReportsView: View {
    @StateObject private var viewModel: ReportsViewModel
    @EnvironmentObject var goalSettings: GoalSettings
    @EnvironmentObject var insightsService: InsightsService
    @EnvironmentObject var healthKitViewModel: HealthKitViewModel

    @State private var selectedTimeframe: ReportTimeframe = .week
    @State private var customStartDate: Date = Calendar.current.date(byAdding: .day, value: -6, to: Date())!
    @State private var customEndDate: Date = Date()
    
    @State private var showingDetailedInsights = false

    private var numberFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = false
        formatter.maximumFractionDigits = 0
        return formatter
    }

    init(dailyLogService: DailyLogService, wellnessScore: WellnessScore) {
        _viewModel = StateObject(wrappedValue: ReportsViewModel(dailyLogService: dailyLogService))
        self.wellnessScore = wellnessScore
    }
    
    func safePercentage(user: Double, total: Double) -> Double {
        guard total > 0 else { return 0 }
        return min((user / total) * 100, 100)
    }
    
    private func calculateProgress(consumed: Double, goal: Double) -> Double {
        guard goal > 0 else { return 0 }
        return min(consumed / goal, 1.0) * 0.8
    }

    var body: some View {
        VStack {
            VStack(alignment: .leading, spacing: 16) {
                if viewModel.isLoading {
                    ProgressView("Loading Reports...")
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 50)
                } else if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 50)
                } else if !viewModel.calorieTrend.isEmpty {
                     reportsContentSection
                } else {
                    VStack {
                        Spacer()
                        Text("No food or exercise logged in the selected period.")
                            .multilineTextAlignment(.center)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 50)
                }
                
                Spacer()
            }
            .padding(.top, 10)
            .padding(.horizontal)
        }
        .background(Color.backgroundPrimary.ignoresSafeArea())
        .navigationTitle("Reports")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.setup(goals: goalSettings)
            fetchDataForCurrentSelection()
            insightsService.generateDailySmartInsight()
            if healthKitViewModel.isAuthorized {
                viewModel.processSleepData(samples: healthKitViewModel.sleepSamples)
            }
        }
        .onChange(of: selectedTimeframe) { newValue in
            if newValue != .custom {
                fetchDataForCurrentSelection()
            }
        }
        .onChange(of: healthKitViewModel.sleepSamples) { newSamples in
            viewModel.processSleepData(samples: newSamples)
        }
    }

    @ViewBuilder
    private var headerSection: some View {
        if let insight = insightsService.smartSuggestion {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "sparkles")
                        .foregroundColor(.brandPrimary)
                    Text(insight.title.lowercased() == "have a great day!" ? "Have a Great Day!" : insight.title)
                        .appFont(size: 17, weight: .semibold)
                }
                Text(insight.message)
                    .appFont(size: 15)
                    .foregroundColor(Color(UIColor.secondaryLabel))
            }
            .asCard()
        }
        
        timeframeSelectorAndPickers
        
        VStack(spacing: 12) {
            insightsActionSection
            
            NavigationLink(destination: WeightTrackingView()) {
                Label("View Weight Tracking", systemImage: "chart.xyaxis.line")
            }
            .buttonStyle(SecondaryButtonStyle())
            
            NavigationLink(destination: CycleTrackingView()) {
                Label("View Cycle Tracking", systemImage: "timer.circle")
            }
            .buttonStyle(SecondaryButtonStyle())
        }
    }

    @ViewBuilder
    private var insightsActionSection: some View {
        Button {
            insightsService.generateAndFetchInsights(forLastDays: 7)
            showingDetailedInsights = true
        } label: {
            Label("Generate Weekly Insights", systemImage: "wand.and.stars")
        }
        .buttonStyle(PrimaryButtonStyle())
       
        NavigationLink(isActive: $showingDetailedInsights) {
            DetailedInsightsView(insightsService: insightsService)
        } label: { EmptyView() }
    }
    
    let wellnessScore: WellnessScore
    
//     MARK: - Content
    @ViewBuilder
    private var reportsContentSection: some View {
        VStack(spacing: 12) {
//            if let score = viewModel.mealScore {
//                MealScoreCard(score: score)
//            }
            if let score = viewModel.mealScore {
                WellnessScoreCardView(wellnessScore: wellnessScore)
            }
        
            if let workoutReport = viewModel.weeklyWorkoutReport {
                WorkoutReportCard(report: workoutReport)
            }
            
            HStack(spacing: 12){
                mealDistributionCard
                WeightCardReport
            }
        }
        .padding(.bottom, 15)
        
        insightsActionSection

    }
    //     MARK: - Weight
    private var WeightCardReport: some View {
        NavigationLink(destination: WeightTrackingView()){
            VStack(alignment: .center){
                HStack{
                    Text("Weight Report")
                        .appFont(size: 16, weight: .semibold)
                        .padding(.bottom, 15)
                        .foregroundColor(.white)
                    
                    Spacer()
                    VStack{
                        Image(systemName:"ellipsis")
                            .foregroundColor(.white)
                            Spacer()
                    }
                    .padding(.top,-5)
                    
                }
              
                
                HStack(spacing: 24) {
                    ZStack {
                        Circle()
                            .trim(from: 0, to: 5/6)
                            .stroke(Color.gray.opacity(0.3), style: StrokeStyle(lineWidth: 14, lineCap: .round))
                            .rotationEffect(.degrees(120))
                            .frame(width: 130, height: 105)
                        Circle()
                            .trim(from: 0, to: (goalSettings.calculateWeightProgress() ?? 0) / 100 * 5/6)
                            .stroke(Color.green, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                            .rotationEffect(.degrees(120))
                            .frame(width: 130, height: 105)
                            .animation(.easeInOut, value: goalSettings.weight)
                        VStack {
                            Text("\(Int(goalSettings.calculateWeightProgress() ?? 0))%")
                                .font(.title2.bold())
                            Text("Progress")
                                .font(.caption)
                        }
                    }

                }
            }
            .asCard()
//            .background(Color.black.opacity(0.8))
            .cornerRadius(20)
            .frame(width: 180, height: 140) // <-- same width & height
            
            
        }
    }


    private var timeframeSelectorAndPickers: some View {
        VStack {
            
            Picker("Timeframe", selection: $selectedTimeframe) {
                ForEach(ReportTimeframe.allCases) { tf in
                    Text(tf.rawValue).tag(tf)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            
            if selectedTimeframe == .custom {
                VStack(spacing: 12) {
                    
                    Grid(alignment: .leading) {
                        
                        GridRow {
                            Text("Start Date").gridColumnAlignment(.leading)
                            DatePicker("Start Date", selection: $customStartDate, in: ...customEndDate, displayedComponents: .date)
                                .labelsHidden()
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                        
                        GridRow {
                            Text("End Date").gridColumnAlignment(.leading)
                            DatePicker("End Date", selection: $customEndDate, in: customStartDate..., displayedComponents: .date)
                                .labelsHidden()
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                    }

                    Button("View Custom Report") {
                        fetchDataForCurrentSelection()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
                .padding(.top, 10)
                .transition(.asymmetric(insertion: .scale(scale: 0.95).combined(with: .opacity), removal: .opacity))
                .animation(.easeInOut(duration: 0.2), value: selectedTimeframe)
            }
        }
    }
    
    private var citationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Source Information")
                .appFont(size: 17, weight: .semibold)
            Text("Calorie and micronutrient goals are based on established dietary guidelines, including the Mifflin-St Jeor equation and Dietary Reference Intakes (DRIs).")
                .appFont(size: 12)
                .foregroundColor(Color(UIColor.secondaryLabel))
            if let url = URL(string: "https://www.nal.usda.gov/human-nutrition-and-food-safety/dri-calculator") {
                Link("Source: USDA Dietary Reference Intakes", destination: url)
                    .appFont(size: 12)
            }
        }
        .asCard()
    }
    
    private func fetchDataForCurrentSelection() {
        if selectedTimeframe == .custom {
            if customEndDate < customStartDate {
                viewModel.errorMessage = "End date cannot be before start date."
                return
            }
            viewModel.fetchData(for: .custom, startDate: customStartDate, endDate: customEndDate)
        } else {
            viewModel.fetchData(for: selectedTimeframe)
        }
    }

    @ViewBuilder private var summaryCard: some View {
        if let summary = viewModel.summary {
            VStack(alignment: .leading, spacing: 12) {
                Text("\(summary.timeframe) Averages")
                    .appFont(size: 17, weight: .semibold)
                Text("Based on \(summary.daysLogged) day(s) logged")
                    .appFont(size: 12)
                    .foregroundColor(Color(UIColor.secondaryLabel))
                    .padding(.bottom, 5)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                    averageStatBox(value: summary.averageCalories, label: "Calories", unit: "cal", goal: goalSettings.calories)
                    averageStatBox(value: summary.averageProtein, label: "Protein", unit: "g", goal: goalSettings.protein)
                    averageStatBox(value: summary.averageCarbs, label: "Carbs", unit: "g", goal: goalSettings.carbs)
                    averageStatBox(value: summary.averageFats, label: "Fats", unit: "g", goal: goalSettings.fats)
                }
            }
            .asCard()
        }
    }

    @ViewBuilder private func averageStatBox(value: Double, label: String, unit: String, goal: Double?) -> some View {
       let formattedValue = numberFormatter.string(from: NSNumber(value: value)) ?? ""
       let valueText = "\(formattedValue) \(unit)"
       
       VStack(alignment: .leading) {
           Text(label).appFont(size: 12).foregroundColor(Color(UIColor.secondaryLabel))
           Text(valueText)
                .appFont(size: 22, weight: .medium)
           if let g = goal, g > 0 {
               let pct = (value / g) * 100
               let goalText = "Goal: \(numberFormatter.string(from: NSNumber(value: g)) ?? "") (\(String(format: "%.0f", pct))%)"
               Text(goalText)
                    .appFont(size: 10).foregroundColor(Color(UIColor.secondaryLabel))
           }
       }
       .frame(maxWidth: .infinity, alignment: .leading)
    }

//     MARK: - Macro
    @ViewBuilder private var mealDistributionCard: some View {
        NavigationLink(destination: CalorieTrackingView(viewModel: viewModel)){
            VStack(alignment: .center) {
                HStack{
                    Text("Calorie Report")
                        .appFont(size: 16, weight: .semibold)
                        
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Image(systemName:"ellipsis")
                        .foregroundColor(.white)
                        .padding(.bottom, 1)
                }
                
                if !viewModel.mealDistributionData.isEmpty {
                    // Group and order meals correctly
                    let groupedMeals = Dictionary(grouping: viewModel.mealDistributionData, by: { $0.mealName })
                    let orderedMealNames = ["Breakfast", "Lunch", "Dinner", "Snack"]
                    
                    // Calculate total calories per meal type
                    let processedData: [(meal: String, totalCalories: Double)] = orderedMealNames.compactMap { mealName in
                        if let items = groupedMeals[mealName] {
                            let total = items.reduce(0) { $0 + $1.totalCalories }
                            return (mealName, total)
                        } else { return nil }
                    }
                    
                    // Define distinct colors
                    let colorMapping: [String: Color] = [
                        "Breakfast": .red,
                        "Lunch": .orange,
                        "Dinner": .blue,
                        "Snack": .green
                    ]
                    
                    Chart(processedData, id: \.meal) { dp in
                        SectorMark(
                            angle: .value("Calories", dp.totalCalories),
                            innerRadius: .ratio(0.5),
                            angularInset: 2
                        )
                        .foregroundStyle(colorMapping[dp.meal, default: .gray])
                        .annotation(position: .overlay) {
                            VStack {
                                Text(dp.meal)
                                    .appFont(size: 11, weight: .bold)
                                Text("\(dp.totalCalories, specifier: "%.0f") cal")
                                    .appFont(size: 10, weight: .bold)
                                
                            }
                        }
                    }
                    .chartLegend(position: .bottom, alignment: .center)
                    .frame(maxWidth: .infinity, maxHeight: 120)
                    .padding(.top, 8)
                    
                } else if !viewModel.isLoading {
                    Text("No meal data available for calorie distribution.")
                        .foregroundColor(Color(UIColor.secondaryLabel))
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                }
            }
            .asCard()
            .frame(width: 180, height: 180) // <-- same width & height
        }
        
    }
}
//
//
//struct ReportsView_Previews: PreviewProvider {
//    static var previews: some View {
//        NavigationView {
//            ReportsView(dailyLogService: DailyLogService())
//                .environmentObject(GoalSettings())
////                .environmentObject(InsightsService())
//                .environmentObject(HealthKitViewModel())
//        }
//    }
//}
