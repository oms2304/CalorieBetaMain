

import SwiftUI

struct WorkoutReport {
    let totalWorkouts: Int
    let totalCaloriesBurned: Double
    let mostFrequentWorkout: String
}

struct WorkoutReportCard: View {
    let report: WorkoutReport
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
<<<<<<< HEAD
            Text("Weekly Workout Summary")
                .appFont(size: 17, weight: .semibold)
                .padding([.top, .leading, .trailing])
            
=======
            HStack{
                
                Text("Weekly Workout Summary")
                    .appFont(size: 16, weight: .semibold)
    //                .padding([.top, .leading, .trailing])
                
                Spacer()
                
                Image(systemName:"ellipsis")
                    .foregroundColor(.white)
                    .padding(.bottom,5)
                
            }
     
>>>>>>> 5424a6b (Recreated the reports page with more polished UI)
            HStack(spacing: 16) {
                workoutStatBox(value: "\(report.totalWorkouts)", label: "Workouts")
                workoutStatBox(value: String(format: "%.0f", report.totalCaloriesBurned), label: "Calories Burned")
            }
            .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Most Frequent Activity")
                    .appFont(size: 12, weight: .bold)
                    .foregroundColor(Color(UIColor.secondaryLabel))
                Text(report.mostFrequentWorkout)
                    .appFont(size: 15)
            }
            .padding(.horizontal)
<<<<<<< HEAD
            .padding(.bottom)
        }
        .asCard()
=======
//            .padding(.bottom)
        }
        .asCard()
        
>>>>>>> 5424a6b (Recreated the reports page with more polished UI)
    }
    
    @ViewBuilder
    private func workoutStatBox(value: String, label: String) -> some View {
        VStack {
            Text(value)
                .appFont(size: 22, weight: .semibold)
                .foregroundColor(.brandPrimary)
            Text(label)
                .appFont(size: 12)
                .foregroundColor(Color(UIColor.secondaryLabel))
        }
        .frame(maxWidth: .infinity)
    }
}
