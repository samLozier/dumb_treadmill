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

            Text("❤️ \(workoutManager.heartRate, specifier: "%.0f") bpm")
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text("⏳ \(workoutManager.elapsedTime.formatted())")
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text("👣 \(workoutManager.distance.formattedDistance(unit: distanceUnit))")
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text("🏃 \(workoutManager.currentPaceMph, specifier: "%.1f") mph")
                .lineLimit(1)
                .minimumScaleFactor(0.7)

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
