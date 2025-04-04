


import SwiftUI
import DGCharts
import FirebaseFirestore

struct CalorieHistoryView: View {
    @State private var selectedTimePeriod: TimePeriod = .last7Days

    
    @State private var calorieData: [DailyLog] = generateSampleCalorieData()

    var body: some View {
        NavigationView {
            VStack {
                Picker("Select Time Period", selection: $selectedTimePeriod) {
                    ForEach(TimePeriod.allCases, id: \.self) { period in
                        Text(period.rawValue).tag(period)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()

              
                LineChartView(calorieData: filteredCalorieData())
                    .frame(height: 300)
                    .padding()

                Spacer()
            }
            .navigationTitle("Calorie History")
        }
    }

    
    private func filteredCalorieData() -> [DailyLog] {
        switch selectedTimePeriod {
        case .last7Days:
            return calorieData.filter { $0.date >= Calendar.current.date(byAdding: .day, value: -7, to: Date())! }
        case .last30Days:
            return calorieData.filter { $0.date >= Calendar.current.date(byAdding: .day, value: -30, to: Date())! }
        case .lastYear:
            return calorieData.filter { $0.date >= Calendar.current.date(byAdding: .year, value: -1, to: Date())! }
        }
    }
}


enum TimePeriod: String, CaseIterable {
    case last7Days = "Last 7 Days"
    case last30Days = "Last 30 Days"
    case lastYear = "Last Year"
}


func generateSampleCalorieData() -> [DailyLog] {
    var data: [DailyLog] = []
    for i in 0..<365 {
        if let date = Calendar.current.date(byAdding: .day, value: -i, to: Date()) {
            let calories = Double(Int.random(in: 1500...3000))
            data.append(DailyLog(date: date, meals: [], totalCaloriesOverride: calories))
        }
    }
    return data
}

extension DailyLog {
    init(date: Date, meals: [Meal], totalCaloriesOverride: Double) {
        self.date = date
        self.meals = meals
        self.totalCaloriesOverride = totalCaloriesOverride
    }
}
