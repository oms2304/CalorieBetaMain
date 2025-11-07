import SwiftUI
import Charts
import FirebaseAuth

struct ReportsView: View {
    @StateObject private var viewModel: ReportsViewModel
    @EnvironmentObject var goalSettings: GoalSettings
    @EnvironmentObject var insightsService: InsightsService
    @EnvironmentObject var healthKitViewModel: HealthKitViewModel
<<<<<<< HEAD
    
=======

>>>>>>> 5424a6b (Recreated the reports page with more polished UI)
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

<<<<<<< HEAD
    init(dailyLogService: DailyLogService) {
        _viewModel = StateObject(wrappedValue: ReportsViewModel(dailyLogService: dailyLogService))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                headerSection
                
=======
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
>>>>>>> 5424a6b (Recreated the reports page with more polished UI)
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
<<<<<<< HEAD
=======
            .padding(.top, 10)
>>>>>>> 5424a6b (Recreated the reports page with more polished UI)
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
<<<<<<< HEAD
        
=======
       
>>>>>>> 5424a6b (Recreated the reports page with more polished UI)
        NavigationLink(isActive: $showingDetailedInsights) {
            DetailedInsightsView(insightsService: insightsService)
        } label: { EmptyView() }
    }
    
<<<<<<< HEAD
    @ViewBuilder
    private var reportsContentSection: some View {
        VStack(spacing: 16) {
            summaryCard
            if let score = viewModel.mealScore {
                MealScoreCard(score: score)
            }
            if let sleepReport = viewModel.weeklySleepReport {
                SleepReportCard(report: sleepReport)
            }
            if let workoutReport = viewModel.weeklyWorkoutReport {
                WorkoutReportCard(report: workoutReport)
            }
            calorieChartCard
            macroChartCard
            micronutrientReportCard
            mealDistributionCard
            citationSection
        }
    }

    private var timeframeSelectorAndPickers: some View {
        VStack {
=======
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
            
>>>>>>> 5424a6b (Recreated the reports page with more polished UI)
            Picker("Timeframe", selection: $selectedTimeframe) {
                ForEach(ReportTimeframe.allCases) { tf in
                    Text(tf.rawValue).tag(tf)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            
            if selectedTimeframe == .custom {
                VStack(spacing: 12) {
<<<<<<< HEAD
                    Grid(alignment: .leading) {
=======
                    
                    Grid(alignment: .leading) {
                        
>>>>>>> 5424a6b (Recreated the reports page with more polished UI)
                        GridRow {
                            Text("Start Date").gridColumnAlignment(.leading)
                            DatePicker("Start Date", selection: $customStartDate, in: ...customEndDate, displayedComponents: .date)
                                .labelsHidden()
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        }
<<<<<<< HEAD
=======
                        
>>>>>>> 5424a6b (Recreated the reports page with more polished UI)
                        GridRow {
                            Text("End Date").gridColumnAlignment(.leading)
                            DatePicker("End Date", selection: $customEndDate, in: customStartDate..., displayedComponents: .date)
                                .labelsHidden()
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                    }
<<<<<<< HEAD
                    
=======

>>>>>>> 5424a6b (Recreated the reports page with more polished UI)
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
<<<<<<< HEAD
    
    @ViewBuilder private var calorieChartCard: some View {
        VStack(alignment: .leading) {
            Text("Daily Calorie Trend").appFont(size: 17, weight: .semibold).padding(.bottom, 5)
            if !viewModel.calorieTrend.isEmpty {
                Chart(viewModel.calorieTrend) { dp in
                    LineMark(x: .value("Date", dp.date, unit: .day), y: .value("Calories", dp.value))
                        .foregroundStyle(Color.brandPrimary)
                        .interpolationMethod(.catmullRom)
                    if let goal = goalSettings.calories {
                        let formattedGoal = numberFormatter.string(from: NSNumber(value: goal)) ?? ""
                        RuleMark(y: .value("Goal", goal))
                            .foregroundStyle(Color(UIColor.secondaryLabel))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [3]))
                            .annotation(position: .top, alignment: .leading) {
                                Text("Goal: \(formattedGoal)")
                                    .appFont(size: 10).foregroundColor(Color(UIColor.secondaryLabel))
                            }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { _ in
                        AxisTick()
                        AxisValueLabel(format: .dateTime.month().day(), centered: false)
                    }
                }
                .chartYAxis { AxisMarks(preset: .aligned, position: .leading) }
                .chartYAxisLabel("Calories (cal)", position: .leading, alignment: .center, spacing: 10)
                .frame(height: 200)
            } else if !viewModel.isLoading {
                Text("Not enough data for trend.")
                    .foregroundColor(Color(UIColor.secondaryLabel)).padding().frame(height: 200).frame(maxWidth: .infinity)
            }
        }
        .asCard()
    }

    @ViewBuilder private var macroChartCard: some View {
        VStack(alignment: .leading) {
            Text("Daily Macro Trend (g)").appFont(size: 17, weight: .semibold).padding(.bottom, 5)
            if !viewModel.proteinTrend.isEmpty || !viewModel.carbTrend.isEmpty || !viewModel.fatTrend.isEmpty {
                Chart {
                    RuleMark(y: .value("P Goal", goalSettings.protein)).foregroundStyle(Color.accentProtein.opacity(0.5)).lineStyle(StrokeStyle(lineWidth: 1, dash: [3])).annotation(position: .top, alignment: .trailing) { Text("P Goal").appFont(size: 10).foregroundColor(Color.accentProtein.opacity(0.7)) }
                    RuleMark(y: .value("C Goal", goalSettings.carbs)).foregroundStyle(Color.accentCarbs.opacity(0.5)).lineStyle(StrokeStyle(lineWidth: 1, dash: [3])).annotation(position: .top, alignment: .trailing) { Text("C Goal").appFont(size: 10).foregroundColor(Color.accentCarbs.opacity(0.7)) }
                    RuleMark(y: .value("F Goal", goalSettings.fats)).foregroundStyle(Color.accentFats.opacity(0.5)).lineStyle(StrokeStyle(lineWidth: 1, dash: [3])).annotation(position: .top, alignment: .trailing) { Text("F Goal").appFont(size: 10).foregroundColor(Color.accentFats.opacity(0.7)) }
                    ForEach(viewModel.proteinTrend) {
                        LineMark(x: .value("Date", $0.date, unit: .day), y: .value("Protein", $0.value)).foregroundStyle(by: .value("Macro", "Protein"))
                        PointMark(x: .value("Date", $0.date, unit: .day), y: .value("Protein", $0.value)).foregroundStyle(by: .value("Macro", "Protein")).symbolSize(10)
                    }
                    ForEach(viewModel.carbTrend) {
                        LineMark(x: .value("Date", $0.date, unit: .day), y: .value("Carbs", $0.value)).foregroundStyle(by: .value("Macro", "Carbs"))
                        PointMark(x: .value("Date", $0.date, unit: .day), y: .value("Carbs", $0.value)).foregroundStyle(by: .value("Macro", "Carbs")).symbolSize(10)
                    }
                    ForEach(viewModel.fatTrend) {
                        LineMark(x: .value("Date", $0.date, unit: .day), y: .value("Fats", $0.value)).foregroundStyle(by: .value("Macro", "Fats"))
                        PointMark(x: .value("Date", $0.date, unit: .day), y: .value("Fats", $0.value)).foregroundStyle(by: .value("Macro", "Fats")).symbolSize(10)
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { _ in
                        AxisTick()
                        AxisValueLabel(format: .dateTime.month().day(), centered: false)
                    }
                }
                .chartYAxis { AxisMarks(preset: .aligned, position: .leading) }
                .chartYAxisLabel("Grams (g)", position: .leading, alignment: .center, spacing: 10)
                .chartForegroundStyleScale([ "Protein": Color.accentProtein, "Carbs": Color.accentCarbs, "Fats": Color.accentFats ])
                .chartLegend(position: .top, alignment: .center)
                .frame(height: 200)
            } else if !viewModel.isLoading {
                Text("Not enough data for trend.")
                    .foregroundColor(Color(UIColor.secondaryLabel)).padding().frame(height: 200).frame(maxWidth: .infinity)
            }
        }
        .asCard()
    }

    @ViewBuilder private var micronutrientReportCard: some View {
        VStack(alignment: .leading) {
            Text("Avg. Micronutrient Intake (% Goal)").appFont(size: 17, weight: .semibold).padding(.bottom, 5)
            if !viewModel.micronutrientAverages.isEmpty {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                    ForEach(viewModel.micronutrientAverages) { micro in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(micro.name).appFont(size: 12, weight: .bold)
                                Spacer()
                                Text("\(micro.percentageMet, specifier: "%.0f")%").appFont(size: 12, weight: .bold)
                            }
                            ProgressView(value: micro.progressViewValue).tint(micro.name == "Sodium" ? (micro.percentageMet >= 100 ? .red : .orange) : (micro.percentageMet >= 100 ? .accentPositive : .brandPrimary)).scaleEffect(x: 1, y: 1.5, anchor: .center)
                            Text("\(micro.averageValue, specifier: micro.unit == "mcg" ? "%.0f" : "%.1f") / \(micro.goalValue, specifier: "%.0f") \(micro.unit)").appFont(size: 10).foregroundColor(Color(UIColor.secondaryLabel)).frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
            } else if !viewModel.isLoading {
                Text("No micronutrient data available for this period.").foregroundColor(Color(UIColor.secondaryLabel)).padding()
            }
        }
        .asCard()
    }

    @ViewBuilder private var mealDistributionCard: some View {
        VStack(alignment: .leading) {
            Text("Avg. Calorie Distribution by Meal").appFont(size: 17, weight: .semibold).padding(.bottom, 5)
            if !viewModel.mealDistributionData.isEmpty {
                let chartColors: [Color] = [.brandPrimary, .brandSecondary, .accentCarbs, .accentFats, .accentProtein]
                Chart(viewModel.mealDistributionData) { dp in
                    SectorMark(
                        angle: .value("Calories", dp.totalCalories),
                        innerRadius: .ratio(0.6),
                        angularInset: 2
                    )
                    .foregroundStyle(by: .value("Meal", dp.mealName))
                    .annotation(position: .overlay) {
                        Text("\(dp.totalCalories, specifier: "%.0f")")
                            .appFont(size: 12, weight: .bold)
                            .foregroundColor(.white)
                    }
                    .cornerRadius(5)
                }
                .chartForegroundStyleScale(domain: viewModel.mealDistributionData.map { $0.mealName }, range: chartColors)
                .chartLegend(position: .bottom, alignment: .center)
                .frame(height: 200)
            } else if !viewModel.isLoading {
                Text("No meal data available for calorie distribution.")
                    .foregroundColor(Color(UIColor.secondaryLabel)).padding().frame(height: 200).frame(maxWidth: .infinity)
            }
        }
        .asCard()
    }
}
=======

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
>>>>>>> 5424a6b (Recreated the reports page with more polished UI)
