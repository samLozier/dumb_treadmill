import SwiftUI

struct PausedView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @State private var showConfirmation = false
    @AppStorage("distanceUnit") private var distanceUnitRaw: String = DistanceUnit.miles.rawValue

    private var distanceUnit: DistanceUnit {
        DistanceUnit(rawValue: distanceUnitRaw) ?? .miles
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 6) {
                Text("Workout Paused")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .accessibilityIdentifier("workoutPausedTitle")

                WorkoutMetricsView(
                    heartRate: workoutManager.heartRate,
                    elapsedTime: workoutManager.elapsedTime,
                    distance: workoutManager.distance,
                    paceMph: nil,
                    distanceUnit: distanceUnit
                )

                if workoutManager.workoutState == .saving {
                    ProgressView("Saving Workout...")
                        .padding()
                } else {
                    NavigationLink("Adjust Speed") {
                        PaceControlView(title: "Speed")
                            .environmentObject(workoutManager)
                    }
                    .padding(.bottom, 8)

                    Button("Resume Workout") {
                        workoutManager.resumeWorkout()
                    }
                    .padding(.vertical, 4)

                    Button("Finish Workout") {
                        showConfirmation = true
                    }
                    .padding(.vertical, 4)
                }
            }
            .padding()
        }
        .alert("Finish Workout?", isPresented: $showConfirmation) {
            Button("Save", role: .none) {
                workoutManager.finishWorkout(onComplete: {})
            }
            Button("Discard", role: .destructive) {
                workoutManager.discardWorkout()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Do you want to save or discard this workout?")
        }
    }
}
