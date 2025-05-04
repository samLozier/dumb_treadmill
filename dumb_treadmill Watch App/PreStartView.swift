import SwiftUI

struct PreStartView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @State private var pace: Double = 3.0

    var body: some View {
        VStack {
            Text("Pace: \(pace, specifier: "%.1f") mph")
            Slider(value: $pace, in: 0...10, step: 0.1)

            Text("Heart Rate: \(workoutManager.heartRate, specifier: "%.0f") bpm")

            Button(action: {
                workoutManager.startWorkout(pace: pace)
            }) {
                Text("Start")
            }
        }
        .padding()
    }
}
