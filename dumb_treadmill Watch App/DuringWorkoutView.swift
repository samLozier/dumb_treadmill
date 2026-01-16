import SwiftUI

struct DuringWorkoutView: View {
    @EnvironmentObject var workoutManager: WorkoutManager

    var body: some View {
        VStack {
            Text("Workout in Progress")

            Text("Heart Rate: \(workoutManager.heartRate, specifier: "%.0f") bpm")
            Text("Elapsed Time: \(workoutManager.elapsedTime.formatted())")
            Text("Distance: \(workoutManager.distance.formattedDistance())")

            Button(action: {
                workoutManager.pauseWorkout()
            }) {
                Text("Pause")
            }
            .navigationBarBackButtonHidden(true)
        }
        .padding()
    }
}
