<<<<<<< HEAD
import SwiftUI
import DGCharts

struct WeightChartView: UIViewRepresentable {
    var weightHistory: [(date: Date, weight: Double)] // ✅ Updated to use weight tracking
=======

import SwiftUI
import DGCharts
struct LineChartView: UIViewRepresentable {
    
    var calorieData: [DailyLog]
>>>>>>> d3d7eb3 (Initial commit)

    func makeUIView(context: Context) -> DGCharts.LineChartView {
        let chartView = DGCharts.LineChartView()
        chartView.rightAxis.enabled = false
        chartView.xAxis.labelPosition = .bottom
        chartView.xAxis.drawGridLinesEnabled = false
        chartView.leftAxis.drawGridLinesEnabled = false
<<<<<<< HEAD
        chartView.leftAxis.axisMinimum = 0
        chartView.legend.form = .line
        chartView.xAxis.valueFormatter = DateValueFormatter() // ✅ Formats X-axis as dates
=======
        chartView.leftAxis.axisMinimum = 0 // Start the y-axis from 0
        chartView.legend.form = .line
>>>>>>> d3d7eb3 (Initial commit)
        return chartView
    }

    func updateUIView(_ uiView: DGCharts.LineChartView, context: Context) {
        setChartData(for: uiView)
    }

    private func setChartData(for chartView: DGCharts.LineChartView) {
<<<<<<< HEAD
        guard !weightHistory.isEmpty else {
            chartView.data = nil // Clear the chart if there is no data
            return
        }

        var dataEntries: [ChartDataEntry] = []

        // ✅ Loop through weight history and add entries
        for record in weightHistory {
            let dateValue = record.date.timeIntervalSince1970
            let weightValue = record.weight
            let dataEntry = ChartDataEntry(x: dateValue, y: weightValue)
            dataEntries.append(dataEntry)
        }

        let lineDataSet = LineChartDataSet(entries: dataEntries, label: "Weight Over Time")
=======
        var dataEntries: [ChartDataEntry] = []

        // Create data entries from calorieData
        for (index, log) in calorieData.enumerated() {
            let dataEntry = ChartDataEntry(x: Double(index), y: log.totalCalories())
            dataEntries.append(dataEntry)
        }

        let lineDataSet = LineChartDataSet(entries: dataEntries, label: "Calories Over Time")
>>>>>>> d3d7eb3 (Initial commit)
        lineDataSet.colors = [NSUIColor.blue]
        lineDataSet.circleColors = [NSUIColor.red]
        lineDataSet.circleRadius = 4
        lineDataSet.lineWidth = 2
        lineDataSet.valueFont = .systemFont(ofSize: 12)
        lineDataSet.mode = .cubicBezier

        let lineData = LineChartData(dataSet: lineDataSet)
        chartView.data = lineData

<<<<<<< HEAD
        chartView.animate(xAxisDuration: 1.5, yAxisDuration: 1.5, easingOption: .easeInOutQuad)
    }
}

// ✅ Custom formatter to convert timestamps into readable dates
class DateValueFormatter: AxisValueFormatter {
    private let dateFormatter: DateFormatter

    init() {
        dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short // Shows short date format (e.g., MM/dd)
    }

    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        let date = Date(timeIntervalSince1970: value)
        return dateFormatter.string(from: date)
    }
}
=======
 
        chartView.animate(xAxisDuration: 1.5, yAxisDuration: 1.5, easingOption: .easeInOutQuad)
    }
}
>>>>>>> d3d7eb3 (Initial commit)
