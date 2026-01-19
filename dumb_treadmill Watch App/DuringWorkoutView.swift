import SwiftUI

struct DuringWorkoutView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @AppStorage("distanceUnit") private var distanceUnitRaw: String = DistanceUnit.miles.rawValue

    private var distanceUnit: DistanceUnit {
        DistanceUnit(rawValue: distanceUnitRaw) ?? .miles
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Workout in Progress")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .center)
                .accessibilityIdentifier("workoutInProgressTitle")

            WorkoutMetricsView(
                heartRate: workoutManager.heartRate,
                elapsedTime: workoutManager.elapsedTime,
                distance: workoutManager.distance,
                paceMph: workoutManager.currentPaceMph,
                distanceUnit: distanceUnit
            )

            NavigationLink("Adjust Speed") {
                PaceControlView(title: "Speed")
                    .environmentObject(workoutManager)
            }

            Button(action: {
                workoutManager.pauseWorkout()
            }) {
                Text("Pause")
            }
            .navigationBarBackButtonHidden(true)
            .accessibilityIdentifier("pauseWorkoutButton")
        }
        .padding()
    }
}
