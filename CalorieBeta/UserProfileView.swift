import SwiftUI
import FirebaseAuth
import Charts


struct UserProfileView: View {
    @EnvironmentObject var dailyLogService: DailyLogService
    @EnvironmentObject var goalSettings: GoalSettings
    @EnvironmentObject var achievementService: AchievementService
    @Environment(\.dismiss) var dismiss
    

    @State private var errorMessage: ErrorMessage?
    @State private var showingChallenges = false
    @State private var showAllAchievements = false
    
    private var userLevelDisplay: String {
        "Level \(achievementService.userAchievementLevel)"
    }
    
    private var pointsToNextLevel: Int {
        let currentLevelIndex = achievementService.userAchievementLevel - 1
        guard currentLevelIndex >= 0 && currentLevelIndex < achievementService.levelThresholds.count - 1 else {
            return 0
        }
        return achievementService.levelThresholds[currentLevelIndex + 1] - achievementService.userTotalAchievementPoints
    }
    
    private var progressToNextLevel: Double {
        let currentLevelIndex = achievementService.userAchievementLevel - 1
        guard currentLevelIndex >= 0 else { return 0.0 }

        let currentLevelThreshold = currentLevelIndex < achievementService.levelThresholds.count ? achievementService.levelThresholds[currentLevelIndex] : achievementService.userTotalAchievementPoints
        let pointsInCurrentLevel = achievementService.userTotalAchievementPoints - currentLevelThreshold
        
        let nextLevelThresholdIndex = currentLevelIndex + 1
        guard nextLevelThresholdIndex < achievementService.levelThresholds.count else { return 1.0 }
            
        let pointsForNextLevelSpan = achievementService.levelThresholds[nextLevelThresholdIndex] - currentLevelThreshold

        if pointsForNextLevelSpan <= 0 { return 1.0 }
        return min(max(0.0, Double(pointsInCurrentLevel) / Double(pointsForNextLevelSpan)), 1.0)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                profileHeader()
                achievementsSection(
                    definitions: achievementService.achievementDefinitions,
                    statuses: achievementService.userStatuses,
                    isLoading: achievementService.isLoading
                )
                dataSection(viewModel: ReportsViewModel(dailyLogService: DailyLogService()))
                
                ProfileInsightsView(insightsService: InsightsService(dailyLogService: DailyLogService(), goalSettings: GoalSettings(), healthKitViewModel: HealthKitViewModel()))
                
                ChallengesView()
                }
            .padding()
        }
        .background(Color.backgroundPrimary)
        .onAppear {
             if let userID = Auth.auth().currentUser?.uid {
                  goalSettings.loadUserGoals(userID: userID)
                  achievementService.fetchUserStatuses(userID: userID)
                  achievementService.listenToUserProfile(userID: userID)
             }
        }
        .alert(item: $errorMessage) { message in
            Alert(title: Text("Error"), message: Text(message.text), dismissButton: .default(Text("OK")))
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
        }
    }

    func profileHeader() -> some View {
         VStack(spacing: 8) {
              Image(systemName: "person.crop.circle").resizable().frame(width: 80, height: 80).foregroundColor(Color(UIColor.secondaryLabel))
              Text(goalSettings.gender == "Male" ? "Fitness Journey" : "Wellness Path")
                  .appFont(size: 25, weight: .bold)
              Text(Auth.auth().currentUser?.email ?? "MyFitPlate User")
                  .foregroundColor(Color(UIColor.secondaryLabel)).appFont(size: 12)
          }
    }

    func userLevelAndPointsSection() -> some View {
        VStack(spacing: 5) {
            Text(userLevelDisplay)
                .appFont(size: 20, weight: .bold)
                .foregroundColor(.brandPrimary)
            ProgressView(value: progressToNextLevel, total: 1.0)
                .progressViewStyle(LinearProgressViewStyle(tint: .brandPrimary))
                .scaleEffect(x:1, y:1.5, anchor: .center)
            
            HStack {
                Text("\(achievementService.userTotalAchievementPoints) pts")
                    .appFont(size: 12)
                Spacer()
                if achievementService.userAchievementLevel <= achievementService.levelThresholds.count && pointsToNextLevel > 0 {
                    Text("\(pointsToNextLevel) pts to next level")
                        .appFont(size: 12)
                        .foregroundColor(Color(UIColor.secondaryLabel))
                } else if !achievementService.levelThresholds.isEmpty && achievementService.userAchievementLevel > achievementService.levelThresholds.count - 1  {
                     Text("Max Level!")
                        .appFont(size: 12)
                        .foregroundColor(.accentPositive)
                }
            }
        }
        .padding()
        .background(Color.backgroundSecondary)
        .cornerRadius(10)
    }
    
    func weeklyChallengesSection() -> some View {
        Button(action: { showingChallenges = true }) {
            HStack {
                Image(systemName: "flame.fill")
                Text("Weekly Challenges")
                    .appFont(size: 20, weight: .semibold)
                Spacer()
                if !achievementService.activeChallenges.isEmpty {
                    Text("\(achievementService.activeChallenges.filter { $0.isCompleted }.count)/\(achievementService.activeChallenges.count)")
                        .appFont(size: 17, weight: .semibold)
                }
                Image(systemName: "chevron.right")
                    .foregroundColor(Color(UIColor.secondaryLabel))
            }
            .foregroundColor(.brandPrimary)
            .padding()
            .background(Color.backgroundSecondary)
            .cornerRadius(10)
        }
    }

    func dailyStats() -> some View {
         HStack(spacing: 16) {
              statBox(title: calorieGoalText(), subtitle: "Calorie Goal"); Divider().frame(height: 40); statBox(title: calculateBMI(), subtitle: "BMI")
          }.padding(.vertical)
    }
    func calorieGoalText() -> String { goalSettings.calories == nil ? "..." : "\(Int(goalSettings.calories ?? 0))" }
    func calculateBMI() -> String { let w = goalSettings.weight * 0.453592; let h = goalSettings.height / 100; guard h > 0 else { return "N/A" }; let bmi = w / (h * h); return String(format: "%.1f", bmi) }
    func statBox(title: String, subtitle: String) -> some View { VStack { Text(title).appFont(size: 28, weight: .bold); Text(subtitle).appFont(size: 12).foregroundColor(Color(UIColor.secondaryLabel)) }.frame(maxWidth: .infinity) }
    
    

    func achievementsSection(definitions: [AchievementDefinition], statuses: [String: UserAchievementStatus], isLoading: Bool) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack{
                Text("Recent Achievements")
                    .appFont(size: 20, weight: .semibold).padding(.bottom, 4)
                
                Spacer()
                
                Button(action: { showAllAchievements = true } ){
                    Text("view all")
                }
            }
            
            if isLoading { HStack { Spacer(); ProgressView(); Spacer() }.padding(.vertical) }
            else if definitions.isEmpty { Text("No achievements defined yet.").foregroundColor(Color(UIColor.secondaryLabel)).appFont(size: 15) }
            else {
                 let sortedDefinitions = definitions.sorted { d1, d2 in
                    let s1 = statuses[d1.id]
                    let s2 = statuses[d2.id]
                    let u1 = s1?.isUnlocked ?? false
                    let u2 = s2?.isUnlocked ?? false
                    if u1 != u2 { return u1 }
                    if u1 {
                        return (s1?.unlockedDate ?? Date.distantPast) > (s2?.unlockedDate ?? Date.distantPast)
                    }
                    let p1 = s1?.currentProgress ?? 0.0
                    let p2 = s2?.currentProgress ?? 0.0
                    if p1 != p2 { return p1 > p2 }
                    if d1.pointsValue != d2.pointsValue {
                        return d1.pointsValue > d2.pointsValue
                    }
                    return d1.title < d2.title
                }
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack{
                        let unlockedOnly = sortedDefinitions.filter { statuses[$0.id]?.isUnlocked == true }
                        if !unlockedOnly.isEmpty {
                            ForEach(unlockedOnly.prefix(3), id: \.id) { definition in
                               AchievementCardView(
                                   definition: definition,
                                   status: statuses[definition.id]
                               )
                           }
                        } else {
                            Text("You haven't unlocked any achievements yet!")
                                .multilineTextAlignment(.center)
                                .padding()
                                .padding(.leading)
                            
                        }
                        
                        
                    }
                }
    
            }
        }
        .padding(.top)
        .sheet(isPresented: $showAllAchievements){
            let sortedDefinitions = definitions.sorted { d1, d2 in
               let s1 = statuses[d1.id]
               let s2 = statuses[d2.id]
               let u1 = s1?.isUnlocked ?? false
               let u2 = s2?.isUnlocked ?? false
               if u1 != u2 { return u1 }
               if u1 {
                   return (s1?.unlockedDate ?? Date.distantPast) > (s2?.unlockedDate ?? Date.distantPast)
               }
               let p1 = s1?.currentProgress ?? 0.0
               let p2 = s2?.currentProgress ?? 0.0
               if p1 != p2 { return p1 > p2 }
               if d1.pointsValue != d2.pointsValue {
                   return d1.pointsValue > d2.pointsValue
               }
               return d1.title < d2.title
           }
            NavigationView{
                ScrollView{
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 15) {
                        ForEach(sortedDefinitions) { definition in
                            AchievementCardView(
                                definition: definition,
                                status: statuses[definition.id]
                            )
                        }
                    }
                    .padding()
                }
                .navigationBarTitle("All Achievemnts")
            }
                        
        }
    }
    
}

struct ProfileInsightsView: View {
    @ObservedObject var insightsService: InsightsService
    @State private var showShareSheet = false
    @State private var pdfURL: URL?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if insightsService.isLoadingInsights {
                    ProgressView("Loading Detailed Insights...")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 50)
                } else if insightsService.currentInsights.isEmpty {
                    Text("No specific insights to show for this period based on your logs. Log consistently for a few more days to unlock your personalized weekly insights!")
                        .multilineTextAlignment(.center)
                        .foregroundColor(Color(UIColor.secondaryLabel))
                        .padding()
                } else {
                    Text("Weekly Insights")
                        .appFont(size: 20, weight: .bold)
                    ForEach(insightsService.currentInsights) { insight in
                        InsightDetailCard(insight: insight)
                    }
                }
              
            }
        }
    }

    @MainActor
    private func exportToPDF() {
        let insightsToExport = insightsService.currentInsights
        guard !insightsToExport.isEmpty else { return }

        let renderer = ImageRenderer(content: InsightsPDFLayout(insights: insightsToExport))
        
        let url = URL.documentsDirectory.appending(path: "MyFitPlate_Insights.pdf")
        
        renderer.render { size, context in
            var box = CGRect(x: 0, y: 0, width: 612, height: 792)
            
            guard var pdf = CGContext(url as CFURL, mediaBox: &box, nil) else {
                return
            }
            
            pdf.beginPDFPage(nil)
            context(pdf)
            pdf.endPDFPage()
            pdf.closePDF()
            
            self.pdfURL = url
            self.showShareSheet = true
        }
    }
}

struct dataSection: View {
    @EnvironmentObject var goalSettings: GoalSettings
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var viewModel: ReportsViewModel
    @State private var selectedGraph = "weight"
    @State private var selectedChartTimeframe: WeightChartTimeframe = .month
    @State private var chartEntryToDeleteID: String? = nil
    @State private var chartEntryToDeleteDetails: String = ""
    @State private var showingChartDeleteAlert = false
    
    private var buttonColor: Color {
        colorScheme == .light ? Color.black : Color.white
    }
    
    private var numberFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = false
        formatter.maximumFractionDigits = 0
        return formatter
    }

    @ViewBuilder var calorieChartCard: some View {
        VStack(alignment: .leading) {
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
                .frame(height: 295)
            } else if !viewModel.isLoading {
                Text("Not enough data for trend.")
                    .foregroundColor(Color(UIColor.secondaryLabel)).padding().frame(height: 295).frame(maxWidth: .infinity)
            }
        }
        .asCard()
    }
    
    init(viewModel: ReportsViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var filteredDataForLineChart: [(id: String, date: Date, weight: Double)] {
        let now = Date()
        let allHistory = goalSettings.weightHistory.sorted { $0.date < $1.date }
        
        guard !allHistory.isEmpty else { return [] }

        let calendar = Calendar.current
        var startDate: Date?

        switch selectedChartTimeframe {
        case .week:
            startDate = calendar.date(byAdding: .day, value: -6, to: calendar.startOfDay(for: now))
        case .month:
            startDate = calendar.date(byAdding: .month, value: -1, to: calendar.startOfDay(for: now))
        case .threeMonths:
            startDate = calendar.date(byAdding: .month, value: -3, to: calendar.startOfDay(for: now))
        case .year:
            startDate = calendar.date(byAdding: .year, value: -1, to: calendar.startOfDay(for: now))
        case .allTime:
            return allHistory
        }
        
        if let start = startDate {
            return allHistory.filter { $0.date >= start }
        }
        return allHistory
    }
    
    private let alertItemFormatter: DateFormatter = {
         let formatter = DateFormatter()
         formatter.dateStyle = .short
         formatter.timeStyle = .short
         return formatter
     }()
    
    @ViewBuilder var weightGraph: some View {
        VStack(alignment: .leading, spacing: 10) {
            Picker("Timeframe", selection: $selectedChartTimeframe.animation()) {
                ForEach(WeightChartTimeframe.allCases) { timeframe in
                    Text(timeframe.rawValue).tag(timeframe)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)

            if !filteredDataForLineChart.isEmpty {
                WeightChartView(
                    weightHistory: filteredDataForLineChart,
                    currentWeight: goalSettings.weight,
                    onEntrySelected: { entryId in
                         if let entry = goalSettings.weightHistory.first(where: { $0.id == entryId }) {
                             self.chartEntryToDeleteID = entryId
                             let weightString = numberFormatter.string(from: NSNumber(value: entry.weight)) ?? ""
                             let dateString = alertItemFormatter.string(from: entry.date)
                             self.chartEntryToDeleteDetails = "\(weightString) lbs on \(dateString)"
                             self.showingChartDeleteAlert = true
                         }
                     }
                )
                .frame(height: 250)
                .padding(.top, 5)
            } else {
                Text("No weight data for this period.")
                    .foregroundColor(Color(UIColor.secondaryLabel))
                    .frame(height: 250, alignment: .center)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .background(Color.backgroundSecondary)
        .cornerRadius(15)
    }
    
    var body: some View {
        VStack(alignment: .leading){
            Text("Statistics").appFont(size: 20, weight: .semibold).padding(.bottom, 5)
            switch selectedGraph {
            case "weight":
                weightGraph
            case "workouts":
                if let workoutReport = viewModel.weeklyWorkoutReport {
                    WorkoutReportCard(report: workoutReport)
                }
            case "calorie":
                calorieChartCard
            default:
                calorieChartCard
            }
            
            HStack{
                Button(action: { selectedGraph = "weight" }){
                    Text("Weight")
                        .font(.system(size:17))
                        .frame(height: 40)
                        .frame(maxWidth:.infinity)
                        .background(selectedGraph == "weight" ? Color.backgroundSecondary : Color.backgroundSecondary.opacity(0.3))
                        .foregroundColor(selectedGraph == "weight" ? buttonColor : buttonColor.opacity(0.3))
                        .cornerRadius(20)
                }
                Button(action: { selectedGraph = "calorie" }){
                    Text("Calories")
                        .font(.system(size:17))
                        .frame(height: 40)
                        .frame(maxWidth:.infinity)
                    
                        .background(selectedGraph == "calorie" ? Color.backgroundSecondary : Color.backgroundSecondary.opacity(0.3))
                        .foregroundColor(selectedGraph == "calorie" ? buttonColor : buttonColor.opacity(0.3))
                        .cornerRadius(20)
                }
                Button(action: { selectedGraph = "workout" }){
                    Text("Workouts")
                        .font(.system(size:17))
                        .frame(height: 40)
                        .frame(maxWidth:.infinity)
                        .background(selectedGraph == "workout" ? Color.backgroundSecondary : Color.backgroundSecondary.opacity(0.3))
                        .foregroundColor(selectedGraph == "workout" ? buttonColor : buttonColor.opacity(0.3))
                        .cornerRadius(20)
                }
                
            }
            .padding()
            
        }
    }
}

struct recentAchievementCardView: View {
    let definition: AchievementDefinition
    let status: UserAchievementStatus?
    var isUnlocked: Bool { status?.isUnlocked ?? false }
    var progress: Double { status?.currentProgress ?? 0.0 }
    var progressFraction: Double { guard definition.criteriaValue > 0 else { return isUnlocked ? 1.0 : 0.0 }; return min(max(0, progress / definition.criteriaValue), 1.0) }
    var progressText: String { if definition.criteriaValue <= 1 && isUnlocked { return "Complete!" } else if definition.criteriaValue <= 1 { return "Not Yet"} else { return "\(Int(progress.rounded())) / \(Int(definition.criteriaValue.rounded()))" } }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: definition.iconName).font(.title2).foregroundColor(isUnlocked ? .yellow : Color(UIColor.secondaryLabel)).frame(width: 30)
                Text(definition.title).appFont(size: 15, weight: .semibold).foregroundColor(isUnlocked ? .textPrimary : Color(UIColor.secondaryLabel)).lineLimit(1)
                Spacer()
                Text("\(definition.pointsValue) pts")
                    .appFont(size: 10, weight: .bold)
                    .padding(.horizontal, 5)
//                    .padding(.vertical, 2)
                    .background((isUnlocked ? Color.yellow.opacity(0.7) : Color(UIColor.secondaryLabel).opacity(0.3)))
                    .cornerRadius(5)
                    .foregroundColor(isUnlocked ? .black.opacity(0.7) : Color(UIColor.secondaryLabel))
            }
            Text(definition.description).appFont(size: 12).foregroundColor(Color(UIColor.secondaryLabel)).frame(minHeight: 30 ,alignment: .top).fixedSize(horizontal: false, vertical: true)
            
            if !isUnlocked && definition.criteriaValue > 0 && definition.criteriaType != .featureUsed {
                VStack(spacing: 2) {
                    ProgressView(value: progressFraction)
                        .progressViewStyle(LinearProgressViewStyle(tint: .brandPrimary))
//                        .frame(height: 6)
                    if definition.criteriaValue > 1 || (definition.criteriaValue == 1 && progress > 0 && progress < 1 && definition.criteriaType != .featureUsed) {
                        Text(progressText)
                            .appFont(size: 10)
                            .foregroundColor(Color(UIColor.secondaryLabel))
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }.padding(.top, 4)
             } else if isUnlocked {
//                 HStack {
//                     
//                 }
//                 .appFont(size: 12, weight: .bold)
//                 .foregroundColor(.accentPositive)
//                 .padding(.top, 4)
            } else {
//                 Spacer().frame(height: 12)
            }
//             Spacer(minLength: 0)
        }
        .padding(12)
//        .frame(minHeight: 120)
        .background(Color.backgroundSecondary)
        .cornerRadius(10)
        .opacity(isUnlocked ? 1.0 : (definition.secret && !isUnlocked ? 0.35 : 0.7))
        .overlay(
            Group {
                if definition.secret && !isUnlocked {
                    VStack{
                        Spacer()
                        HStack{
                            Spacer()
                            Image(systemName: "questionmark.diamond.fill")
                                .font(.system(size: 50))
                                .foregroundColor(Color(UIColor.secondaryLabel).opacity(0.2))
                                .padding()
                            Spacer()
                        }
                        Spacer()
                    }
                }
            }
        )
    }
}

struct AchievementCardView: View {
    let definition: AchievementDefinition
    let status: UserAchievementStatus?
    var isUnlocked: Bool { status?.isUnlocked ?? false }
    var progress: Double { status?.currentProgress ?? 0.0 }
    var progressFraction: Double { guard definition.criteriaValue > 0 else { return isUnlocked ? 1.0 : 0.0 }; return min(max(0, progress / definition.criteriaValue), 1.0) }
    var progressText: String { if definition.criteriaValue <= 1 && isUnlocked { return "Complete!" } else if definition.criteriaValue <= 1 { return "Not Yet"} else { return "\(Int(progress.rounded())) / \(Int(definition.criteriaValue.rounded()))" } }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: definition.iconName).font(.title2).foregroundColor(isUnlocked ? .yellow : Color(UIColor.secondaryLabel)).frame(width: 30)
                Text(definition.title).appFont(size: 15, weight: .semibold).foregroundColor(isUnlocked ? .textPrimary : Color(UIColor.secondaryLabel)).lineLimit(1)
                Spacer()
                Text("\(definition.pointsValue) pts")
                    .appFont(size: 10, weight: .bold)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background((isUnlocked ? Color.yellow.opacity(0.7) : Color(UIColor.secondaryLabel).opacity(0.3)))
                    .cornerRadius(5)
                    .foregroundColor(isUnlocked ? .black.opacity(0.7) : Color(UIColor.secondaryLabel))
            }
            Text(definition.description).appFont(size: 12).foregroundColor(Color(UIColor.secondaryLabel)).frame(minHeight: 30 ,alignment: .top).fixedSize(horizontal: false, vertical: true)
            
            if !isUnlocked && definition.criteriaValue > 0 && definition.criteriaType != .featureUsed {
                VStack(spacing: 2) {
                    ProgressView(value: progressFraction)
                        .progressViewStyle(LinearProgressViewStyle(tint: .brandPrimary))
                        .frame(height: 6)
                    if definition.criteriaValue > 1 || (definition.criteriaValue == 1 && progress > 0 && progress < 1 && definition.criteriaType != .featureUsed) {
                        Text(progressText)
                            .appFont(size: 10)
                            .foregroundColor(Color(UIColor.secondaryLabel))
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }.padding(.top, 4)
             } else if isUnlocked {
                 HStack {
                     Text("Unlocked!")
                     if let date = status?.unlockedDate { Text(date, style: .date) }
                 }
                 .appFont(size: 12, weight: .bold)
                 .foregroundColor(.accentPositive)
                 .padding(.top, 4)
            } else {
                 Spacer().frame(height: 12)
            }
             Spacer(minLength: 0)
        }
        .padding(12)
        .frame(minHeight: 120)
        .background(Color.backgroundSecondary)
        .cornerRadius(10)
        .opacity(isUnlocked ? 1.0 : (definition.secret && !isUnlocked ? 0.35 : 0.7))
        .overlay(
            Group {
                if definition.secret && !isUnlocked {
                    VStack{
                        Spacer()
                        HStack{
                            Spacer()
                            Image(systemName: "questionmark.diamond.fill")
                                .font(.system(size: 50))
                                .foregroundColor(Color(UIColor.secondaryLabel).opacity(0.2))
                                .padding()
                            Spacer()
                        }
                        Spacer()
                    }
                }
            }
        )
    }
}


struct ErrorMessage: Identifiable { let id = UUID(); let text: String; init(_ text: String) { self.text = text } }
