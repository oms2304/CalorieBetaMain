import UIKit
import SwiftUI
import DGCharts
import FirebaseAuth
import FirebaseFirestore

// This view controller manages the weight tracking interface using a SwiftUI chart embedded
// in a UIKit environment, fetching and displaying weight history data from Firestore.
class WeightTrackingViewController: UIViewController {
    // Array to store weight history locally, consisting of date-weight pairs.
    var weightHistory: [(date: Date, weight: Double)] = [] // ✅ Stores weight data locally for chart use.

    // Optional reference to the hosting controller for the SwiftUI chart to manage updates.
    var hostingController: UIHostingController<WeightChartView>? // ✅ Retains reference to avoid reloading issues.

    override func viewDidLoad() {
        super.viewDidLoad() // Calls the superclass's initialization.
        view.backgroundColor = .white // Sets a white background for the view.

        setupSwiftUIChart() // Initializes and adds the SwiftUI chart to the view.
        loadWeightData() // Fetches weight data from Firestore. ✅ Ensures actual user data is loaded.
    }

    // Sets up the SwiftUI chart within the UIKit view controller.
    private func setupSwiftUIChart() {
        // ✅ Ensures the chart updates dynamically by creating a hosting controller.
        let chartView = UIHostingController(rootView: WeightChartView(weightHistory: weightHistory))
        addChild(chartView) // Adds the hosting controller as a child.
        chartView.view.frame = view.bounds // Matches the chart view to the parent view's bounds.
        chartView.view.autoresizingMask = [.flexibleWidth, .flexibleHeight] // Allows resizing with the parent.
        view.addSubview(chartView.view) // Adds the chart view to the hierarchy.
        chartView.didMove(toParent: self) // Completes the child view controller setup.

        hostingController = chartView // ✅ Stores the reference for later updates.
    }

    // Fetches weight history data from Firestore for the authenticated user.
    private func loadWeightData() {
        guard let userID = Auth.auth().currentUser?.uid else { return } // Ensures a user is logged in.
        let db = Firestore.firestore() // Initializes the Firestore database instance.

        // Queries the weight history collection, ordered by timestamp.
        db.collection("users").document(userID).collection("weightHistory")
            .order(by: "timestamp", descending: false) // Sorts by timestamp in ascending order.
            .getDocuments { snapshot, error in
                if let error = error { // Checks for Firestore query errors.
                    print("❌ Error fetching weight history: \(error.localizedDescription)") // Logs the error.
                    return
                }

                // Maps Firestore documents to weight history tuples, handling optional data.
                self.weightHistory = snapshot?.documents.compactMap { doc in
                    if let weight = doc.data()["weight"] as? Double, // Extracts weight as Double.
                       let timestamp = doc.data()["timestamp"] as? Timestamp { // Extracts timestamp.
                        return (timestamp.dateValue(), weight) // Returns a tuple of date and weight.
                    }
                    return nil // Returns nil for invalid data to filter out.
                } ?? [] // Defaults to empty array if snapshot is nil.

                DispatchQueue.main.async { // Ensures UI updates on the main thread.
                    self.updateChart() // Updates the chart with the new data.
                }
            }
    }

    // Updates the SwiftUI chart with the latest weight history data.
    private func updateChart() {
        // ✅ Ensures the chart updates dynamically when weight data changes.
        hostingController?.rootView = WeightChartView(weightHistory: weightHistory) // Replaces the root view with updated data.
    }
}
