import SwiftUI
import Charts

// This view displays a weight tracking interface, allowing users to view their weight history
// over different timeframes and enter new weight data, integrated with the GoalSettings model.
struct WeightTrackingView: View {
    // Environment object to access and modify user goals and weight history.
    @EnvironmentObject var goalSettings: GoalSettings
    // State variable to control the visibility of the weight entry sheet.
    @State private var showingWeightEntry = false
    // State variable to manage the selected timeframe for weight data filtering.
    @State private var selectedTimeframe: Timeframe = .year // Default to one-year view.

    // Computed property to filter weight history based on the selected timeframe.
    var filteredWeightData: [(date: Date, weight: Double)] {
        let now = Date() // Current date as the reference point.
        switch selectedTimeframe { // Filters data based on the chosen timeframe.
        case .day:
            return goalSettings.weightHistory.filter { $0.date > Calendar.current.date(byAdding: .day, value: -1, to: now)! }
        case .week:
            return goalSettings.weightHistory.filter { $0.date > Calendar.current.date(byAdding: .weekOfYear, value: -1, to: now)! }
        case .month:
            return goalSettings.weightHistory.filter { $0.date > Calendar.current.date(byAdding: .month, value: -1, to: now)! }
        case .sixMonths:
            return goalSettings.weightHistory.filter { $0.date > Calendar.current.date(byAdding: .month, value: -6, to: now)! }
        case .year:
            return goalSettings.weightHistory.filter { $0.date > Calendar.current.date(byAdding: .year, value: -1, to: now)! }
        }
    }

    // The main body of the view, organized in a vertical stack.
    var body: some View {
        VStack { // Vertical stack to arrange the content.
            Text("Weight Tracking") // Title of the view.
                .font(.largeTitle) // Large, prominent font.
                .padding() // Adds padding around the title.

            // Picker to select the timeframe for weight data display.
            Picker("Select Timeframe", selection: $selectedTimeframe) { // Segmented picker for timeframe options.
                Text("D").tag(Timeframe.day) // Day option with "D" label.
                Text("W").tag(Timeframe.week) // Week option with "W" label.
                Text("M").tag(Timeframe.month) // Month option with "M" label.
                Text("6M").tag(Timeframe.sixMonths) // Six months option with "6M" label.
                Text("Y").tag(Timeframe.year) // Year option with "Y" label.
            }
            .pickerStyle(SegmentedPickerStyle()) // Uses a segmented control style.
            .padding() // Adds padding around the picker.

            // Displays a chart of weight history using the filtered data.
            WeightChartView(weightHistory: filteredWeightData) // Custom chart view for weight data.

            // Button to trigger the weight entry sheet.
            Button(action: {
                showingWeightEntry = true // Shows the weight entry sheet.
            }) {
                Text("Enter Current Weight") // Button label.
                    .frame(maxWidth: .infinity) // Expands to full width.
                    .padding() // Adds internal padding.
                    .background(Color(red: 67/255, green: 173/255, blue: 111/255)) // Changed to #43AD6F.
                    .foregroundColor(.white) // White text for contrast.
                    .cornerRadius(10) // Rounded corners for a modern look.
            }
            .padding() // Adds padding around the button.
            .sheet(isPresented: $showingWeightEntry) { // Presents the weight entry view as a sheet.
                CurrentWeightView() // View for entering new weight data.
                    .environmentObject(goalSettings)
                // Passes the goal settings to the sheet.
            }
            WeightChartViewController()
                .environmentObject(goalSettings)
        }
        .onAppear {
            goalSettings.loadWeightHistory() // Loads the weight history when the view appears.
        }
    }
}

// Enum defining the possible timeframes for filtering weight data.
enum Timeframe {
    case day, week, month, sixMonths, year // Options for data filtering (1 day, 1 week, 1 month, 6 months, 1 year).
}
