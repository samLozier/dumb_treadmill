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

            Text("❤️ \(workoutManager.heartRate, specifier: "%.0f") bpm")
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text("⏳ \(workoutManager.elapsedTime.formatted())")
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text("👣 \(workoutManager.distance.formattedDistance(unit: distanceUnit))")
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            PaceControlView(title: "Speed")
                .environmentObject(workoutManager)
                .frame(maxWidth: .infinity)

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
