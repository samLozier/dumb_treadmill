import SwiftUI

struct SavingWorkoutView: View {
    @Environment(\.dismiss) private var dismiss
    var distance: Double
    var totalEnergyBurned: Double
    var startDate: Date
    var endDate: Date
    
    var body: some View {
        VStack {
            ProgressView()
                .scaleEffect(1.5)
                .padding()
            
            Text("Saving Workout...")
                .font(.title2)
                .padding()
            
            Text("Please wait while we save your workout.")
                .font(.body)
                .foregroundColor(.gray)
                .padding(.horizontal)
                .multilineTextAlignment(.center)
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Workout Details:")
                    .font(.headline)
                
                Text("Distance: \(distance.formattedDistance())")
                Text("Calories Burned: \(totalEnergyBurned.formattedCalories())")
                Text("Start Time: \(startDate.formatted(date: .numeric, time: .shortened))")
                Text("End Time: \(endDate.formatted(date: .numeric, time: .shortened))")
            }
            .padding()
            .foregroundColor(.gray)
        }
        .padding()
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.dismiss() // Automatically navigate back
            }
        }
    }
}
