<<<<<<< HEAD
import UIKit
import SwiftUI
import DGCharts
import FirebaseAuth
import FirebaseFirestore

class WeightTrackingViewController: UIViewController {
    var weightHistory: [(date: Date, weight: Double)] = [] // ✅ Store weight history locally
    var hostingController: UIHostingController<WeightChartView>? // ✅ Keep reference to avoid reloading issues
=======
//
//  WeightTrackingViewController.swift
//  CalorieBeta
//
//  Created by Peter Andrews, jr.  on 10/25/24.
//

import UIKit
import DGCharts

class WeightTrackingViewController: UIViewController {
    var lineChartView: DGCharts.LineChartView!
>>>>>>> d3d7eb3 (Initial commit)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white

<<<<<<< HEAD
        setupSwiftUIChart()
        loadWeightData() // ✅ Fetch actual user weight data
    }

    private func setupSwiftUIChart() {
        // ✅ Ensure chart updates dynamically
        let chartView = UIHostingController(rootView: WeightChartView(weightHistory: weightHistory))
        addChild(chartView)
        chartView.view.frame = view.bounds
        chartView.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(chartView.view)
        chartView.didMove(toParent: self)

        hostingController = chartView // ✅ Store reference for later updates
    }

    private func loadWeightData() {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()

        db.collection("users").document(userID).collection("weightHistory")
            .order(by: "timestamp", descending: false)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("❌ Error fetching weight history: \(error.localizedDescription)")
                    return
                }

                self.weightHistory = snapshot?.documents.compactMap { doc in
                    if let weight = doc.data()["weight"] as? Double,
                       let timestamp = doc.data()["timestamp"] as? Timestamp {
                        return (timestamp.dateValue(), weight)
                    }
                    return nil
                } ?? []

                DispatchQueue.main.async {
                    self.updateChart()
                }
            }
    }

    private func updateChart() {
        // ✅ Ensure chart updates dynamically when weight data changes
        hostingController?.rootView = WeightChartView(weightHistory: weightHistory)
=======
      
        setupLineChartView()
        setChartData() // Set initial chart data
    }

    private func setupLineChartView() {
        lineChartView = DGCharts.LineChartView()
        lineChartView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(lineChartView)

      
        NSLayoutConstraint.activate([
            lineChartView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            lineChartView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            lineChartView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            lineChartView.heightAnchor.constraint(equalToConstant: 300)
        ])
    }

    private func setChartData() {
    
        let sampleData = [1500, 1600, 1700, 1800, 1900]
        var dataEntries: [ChartDataEntry] = []

    
        for (index, value) in sampleData.enumerated() {
            let dataEntry = ChartDataEntry(x: Double(index), y: Double(value))
            dataEntries.append(dataEntry)
        }

      
        let lineDataSet = LineChartDataSet(entries: dataEntries, label: "Weight Over Time")
        lineDataSet.colors = [NSUIColor.blue]
        lineDataSet.circleColors = [NSUIColor.red]
        lineDataSet.circleRadius = 4
        lineDataSet.lineWidth = 2
        lineDataSet.valueFont = .systemFont(ofSize: 12)
        lineDataSet.mode = .cubicBezier

       
        let lineData = LineChartData(dataSet: lineDataSet)
        lineChartView.data = lineData

       
        lineChartView.animate(xAxisDuration: 1.5, yAxisDuration: 1.5, easingOption: .easeInOutQuad)
>>>>>>> d3d7eb3 (Initial commit)
    }
}
