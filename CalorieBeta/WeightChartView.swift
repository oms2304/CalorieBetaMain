import SwiftUI
import DGCharts

// This view represents a line chart for displaying weight history over time, bridging SwiftUI
// with a UIKit-based DGCharts (Charts) LineChartView for advanced charting capabilities.
struct WeightChartView: UIViewRepresentable {
    // Input data: an array of tuples containing date and weight values.
    var weightHistory: [(date: Date, weight: Double)] // ✅ Stores weight tracking data for the chart.

    // Creates and configures the LineChartView for the first time.
    func makeUIView(context: Context) -> DGCharts.LineChartView {
        let chartView = DGCharts.LineChartView() // Initializes a new LineChartView.
        chartView.rightAxis.enabled = false // Disables the right Y-axis for a cleaner look.
        chartView.xAxis.labelPosition = .bottom // Places X-axis labels at the bottom.
        chartView.xAxis.drawGridLinesEnabled = false // Removes X-axis grid lines.
        chartView.leftAxis.drawGridLinesEnabled = false // Removes left Y-axis grid lines.
        chartView.leftAxis.axisMinimum = 0 // Sets the minimum Y-axis value to 0.
        chartView.legend.form = .line // Displays the legend as a line.
        chartView.xAxis.valueFormatter = DateValueFormatter() // ✅ Formats X-axis labels as dates.
        return chartView
    }

    // Updates the LineChartView when the SwiftUI view changes (e.g., new data).
    func updateUIView(_ uiView: DGCharts.LineChartView, context: Context) {
        setChartData(for: uiView) // Updates the chart with the latest weight history data.
    }

    // Configures the chart data and appearance based on the weight history.
    private func setChartData(for chartView: DGCharts.LineChartView) {
        guard !weightHistory.isEmpty else { // Checks if there is data to display.
            chartView.data = nil // Clears the chart if no data is available.
            return
        }

        var dataEntries: [ChartDataEntry] = [] // Array to store chart data points.

        // ✅ Loops through weight history to create chart entries.
        for record in weightHistory {
            let dateValue = record.date.timeIntervalSince1970 // Converts date to timestamp for X-axis.
            let weightValue = record.weight // Weight value for Y-axis.
            let dataEntry = ChartDataEntry(x: dateValue, y: weightValue) // Creates a chart entry.
            dataEntries.append(dataEntry) // Adds the entry to the array.
        }

        // Creates a dataset for the line chart with the collected entries.
        let lineDataSet = LineChartDataSet(entries: dataEntries, label: "Weight Over Time")
        lineDataSet.colors = [NSUIColor(red: 67/255, green: 173/255, blue: 111/255, alpha: 1)] // Changed to #43AD6F for the line color.
        lineDataSet.circleColors = [NSUIColor(red: 67/255, green: 173/255, blue: 111/255, alpha: 1)] // Changed to #43AD6F for data point circle colors.
        lineDataSet.circleRadius = 4 // Sets the radius of data point circles.
        lineDataSet.lineWidth = 2 // Sets the thickness of the line.
        lineDataSet.valueFont = .systemFont(ofSize: 12) // Sets the font for data point labels.
        lineDataSet.mode = .cubicBezier // Smooths the line using a cubic Bezier curve.

        let lineData = LineChartData(dataSet: lineDataSet) // Wraps the dataset in chart data.
        chartView.data = lineData // Assigns the data to the chart.

        // Animates the chart display with a smooth transition.
        chartView.animate(xAxisDuration: 1.5, yAxisDuration: 1.5, easingOption: .easeInOutQuad)
    }
}

// ✅ Custom formatter to convert timestamps into readable dates for the X-axis.
class DateValueFormatter: AxisValueFormatter {
    private let dateFormatter: DateFormatter // Formatter for converting dates to strings.

    init() {
        dateFormatter = DateFormatter() // Initializes the date formatter.
        dateFormatter.dateStyle = .short // Sets the date style to short (e.g., MM/dd).
    }

    // Converts a timestamp value into a formatted date string.
    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        let date = Date(timeIntervalSince1970: value) // Converts timestamp to Date.
        return dateFormatter.string(from: date) // Returns the formatted date string.
    }
}
