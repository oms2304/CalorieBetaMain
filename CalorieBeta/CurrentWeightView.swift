<<<<<<< HEAD
import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct CurrentWeightView: View {
    @EnvironmentObject var goalSettings: GoalSettings
    @State private var weight = ""
=======


import SwiftUI
import FirebaseFirestore

struct CurrentWeightView: View {
    @ObservedObject var goalSettings: GoalSettings  
    @State private var weight = ""

>>>>>>> d3d7eb3 (Initial commit)
    @Environment(\.dismiss) var dismiss

    var body: some View {
        Form {
            Section(header: Text("Current Weight")) {
                TextField("Enter your weight (lbs)", text: $weight)
                    .keyboardType(.decimalPad)
            }

            Button(action: {
                saveWeight()
                dismiss()
            }) {
                Text("Save Weight")
                    .font(.title2)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.top)
        }
        .navigationTitle("Current Weight")
        .onAppear {
            weight = String(format: "%.1f", goalSettings.weight)
        }
    }

    private func saveWeight() {
<<<<<<< HEAD
        guard let weightValue = Double(weight), weightValue > 0 else { return }
        goalSettings.updateUserWeight(weightValue)
=======
        if let weightValue = Double(weight) {
            goalSettings.weight = weightValue
        }
>>>>>>> d3d7eb3 (Initial commit)
    }
}
