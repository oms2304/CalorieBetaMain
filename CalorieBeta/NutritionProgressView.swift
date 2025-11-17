import SwiftUI
import Charts
import FirebaseAuth

struct NutritionProgressView: View {
    var dailyLog: DailyLog
    @ObservedObject var goal: GoalSettings
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var dailyLogService: DailyLogService
    var insight: UserInsight?

    @State private var dragOffset: CGFloat = 0
    @State private var currentIndex: Int = 0
    
    private let totalViews = 4
    private let cardSpacing: CGFloat = 20
    private let cardWidth: CGFloat = UIScreen.main.bounds.width - 60

    var body: some View {
        let totalCalories = max(0, dailyLog.totalCalories())
        let totalMacros = dailyLog.totalMacros()
        let protein = max(0, totalMacros.protein)
        let fats = max(0, totalMacros.fats)
        let carbs = max(0, totalMacros.carbs)
        let caloriesGoal = max(goal.calories ?? 1, 1)
        let proteinGoal = max(goal.protein, 1)
        let fatsGoal = max(goal.fats, 1)
        let carbsGoal = max(goal.carbs, 1)
        let caloriesPercentage = min(totalCalories / caloriesGoal, 1.0)
        let proteinPercentage = min(protein / proteinGoal, 1.0)
        let fatsPercentage = min(fats / fatsGoal, 1.0)
        let carbsPercentage = min(carbs / carbsGoal, 1.0)
        
        VStack(spacing: 16) {
            GeometryReader { geometry in
                ZStack {
                    ForEach(0..<totalViews, id: \.self) { index in
                        let offset = CGFloat(index - currentIndex) * (cardWidth + cardSpacing) + dragOffset
                        let scale = getScale(for: index)
                        let opacity = getOpacity(for: index)
                        
                        Group {
                            switch index {
                            case 0:
                                summaryView(calories: totalCalories, caloriesGoal: caloriesGoal, caloriesPercentage: caloriesPercentage, protein: protein, proteinGoal: proteinGoal, fats: fats, fatsGoal: fatsGoal, carbs: carbs, carbsGoal: carbsGoal)
                            case 1:
                                bubblesView(calories: totalCalories, caloriesGoal: caloriesGoal, caloriesPercentage: caloriesPercentage, protein: protein, proteinGoal: proteinGoal, proteinPercentage: proteinPercentage, fats: fats, fatsGoal: fatsGoal, fatsPercentage: fatsPercentage, carbs: carbs, carbsGoal: carbsGoal, carbsPercentage: carbsPercentage)
                            case 2:
                                HorizontalBarChartView(dailyLog: dailyLog, goal: goal)
                            case 3:
                                MicronutrientProgressView(dailyLog: dailyLog, goalSettings: goal)
                            default:
                                EmptyView()
                            }
                        }
                        .padding(.horizontal,8)
                        .frame(width: cardWidth, height: 220)
                        .background(Color.backgroundSecondary.opacity(0.8))
                        .cornerRadius(12)
                        
                        .overlay(
                            
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(Color.primary.opacity(0.05), lineWidth: 1)
                        )
                        .scaleEffect(scale)
                        .opacity(opacity)
                        .offset(x: offset)
                        .clipped()
                        .zIndex(index == currentIndex ? 1 : 0)
                    }
                }
                .frame(width: geometry.size.width, height: 220)
            }
            .frame(height: 220)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        dragOffset = value.translation.width
                    }
                    .onEnded { value in
                        let threshold: CGFloat = cardWidth / 3
                        
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                            if value.translation.width < -threshold && currentIndex < totalViews - 1 {
                                currentIndex += 1
                                goal.nutritionViewIndex = currentIndex
                            } else if value.translation.width > threshold && currentIndex > 0 {
                                currentIndex -= 1
                                goal.nutritionViewIndex = currentIndex
                            }
                            dragOffset = 0
                        }
                    }
            )
            
            // Modern page indicator
            HStack(spacing: 6) {
                ForEach(0..<totalViews, id: \.self) { index in
                    if index == currentIndex {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.accentColor)
                            .frame(width: 24, height: 6)
//                            .transition(.scale)
                    } else {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 6, height: 6)
                            .onTapGesture {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                                    currentIndex = index
                                    goal.nutritionViewIndex = index
                                }
                            }
                    }
                }
            }
            .padding(.top, 8)
        }
        .padding(.vertical, 16)
        .onAppear {
            currentIndex = goal.nutritionViewIndex
        }
    }
    
    private func getScale(for index: Int) -> CGFloat {
        let distance = abs(CGFloat(index - currentIndex))
        if distance == 0 {
            return 1.0
        } else if distance == 1 {
            return 0.9
        } else {
            return 0.8
        }
    }
    
    private func getOpacity(for index: Int) -> Double {
        let distance = abs(index - currentIndex)
        if distance == 0 {
            return 1.0
        } else if distance == 1 {
            return 0.5
        } else {
            return 0.2
        }
    }

    @ViewBuilder
    private func summaryView(calories: Double, caloriesGoal: Double, caloriesPercentage: Double, protein: Double, proteinGoal: Double, fats: Double, fatsGoal: Double, carbs: Double, carbsGoal: Double) -> some View {
        HStack(spacing: 16) {
            VStack {
                Text("Calories")
                    .appFont(size: 14, weight: .medium)
                ProgressBubble(
                    value: calories,
                    goal: caloriesGoal,
                    percentage: caloriesPercentage,
                    label: "",
                    unit: "cal",
                    color: .red
                )
            }
            
            VStack(spacing: 12) {
                MacroProgressRow(
                    label: "Protein",
                    value: protein,
                    goal: proteinGoal,
                    unit: "g",
                    color: .accentProtein
                )
                MacroProgressRow(
                    label: "Carbs",
                    value: carbs,
                    goal: carbsGoal,
                    unit: "g",
                    color: .accentCarbs
                )
                MacroProgressRow(
                    label: "Fats",
                    value: fats,
                    goal: fatsGoal,
                    unit: "g",
                    color: .accentFats
                )
            }
        }
        .padding(20)
    }

    @ViewBuilder
    private func bubblesView(calories: Double, caloriesGoal: Double, caloriesPercentage: Double, protein: Double, proteinGoal: Double, proteinPercentage: Double, fats: Double, fatsGoal: Double, fatsPercentage: Double, carbs: Double, carbsGoal: Double, carbsPercentage: Double) -> some View {
        HStack(spacing: 15) {
            ProgressBubble(value: calories, goal: caloriesGoal, percentage: caloriesPercentage, label: "Calories", unit: "cal", color: .red, isSmall: true)
            ProgressBubble(value: protein, goal: proteinGoal, percentage: proteinPercentage, label: "Protein", unit: "g", color: .accentProtein, isSmall: true)
            ProgressBubble(value: fats, goal: fatsGoal, percentage: fatsPercentage, label: "Fats", unit: "g", color: .accentFats, isSmall: true)
            ProgressBubble(value: carbs, goal: carbsGoal, percentage: carbsPercentage, label: "Carbs", unit: "g", color: .accentCarbs, isSmall: true)
        }
        .padding(20)
    }
}

struct ProgressBubble: View {
    let value: Double
    let goal: Double
    let percentage: Double
    let label: String
    let unit: String
    let color: Color
    var isSmall: Bool = false
    
    private var remaining: Double {
        goal - value
    }
    
    var body: some View {
        VStack {
            ZStack {
                Circle().stroke(lineWidth: isSmall ? 6 : 10).opacity(0.15).foregroundColor(color)
                Circle()
                    .trim(from: 0, to: CGFloat(percentage))
                    .stroke(style: StrokeStyle(lineWidth: isSmall ? 6 : 10, lineCap: .round, lineJoin: .round))
                    .foregroundColor(color)
                    .rotationEffect(Angle(degrees: -90))
                    .animation(.easeInOut(duration: 0.75), value: percentage)

                VStack {
                    if isSmall {
                        Text("\(String(format: "%.0f", value))")
                            .appFont(size: isSmall ? 15 : 24, weight: isSmall ? .medium : .bold)
                            .foregroundColor(.textPrimary)
                        Text("/ \(String(format: "%.0f", goal)) \(unit)")
                             .appFont(size: isSmall ? 10 : 12)
                            .foregroundColor(Color(UIColor.secondaryLabel))
                    } else {
                        Text("\(String(format: "%.0f", remaining))")
                            .appFont(size: 28, weight: .bold)
                            .foregroundColor(.textPrimary)
                        Text("Remaining")
                            .appFont(size: 12)
                            .foregroundColor(Color(UIColor.secondaryLabel))
                    }
                }
            }
            .frame(width: isSmall ? 70 : 100, height: isSmall ? 70 : 100)
            
            if !isSmall {
                Text("\(String(format: "%.0f", value)) / \(String(format: "%.0f", goal)) \(unit)")
                     .appFont(size: 12)
                    .foregroundColor(Color(UIColor.secondaryLabel))
            } else if !label.isEmpty {
                Text(label)
                    .appFont(size: 12)
                    .foregroundColor(.textPrimary)
                    .lineLimit(1)
            }
        }
    }
}

#Preview {
    NutritionProgressView(
        dailyLog: DailyLog(date: Date(), meals: []),
        goal: GoalSettings()
    )
    .environmentObject(DailyLogService())
}
