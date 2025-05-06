import SwiftUI
import HealthKit

struct SavingWorkoutView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @Environment(\.dismiss) private var dismiss
    @State private var saveComplete = false

    var body: some View {
        let distance = workoutManager.finalDistance
        let totalEnergyBurned = workoutManager.finalEnergyBurned
        let startDate = workoutManager.finalStartDate
        let endDate = startDate.addingTimeInterval(workoutManager.elapsedTime)

        return ScrollView {
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

                if saveComplete {
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

                    Button("Done") {
                        workoutManager.workoutState = .idle
                    }
                    .padding()
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
        }
        .onAppear {
            Task {
                try? await Task.sleep(nanoseconds: 2 * 1_000_000_000)
                saveComplete = true
            }
        }
    }
}
