import SwiftUI

struct PausedView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    var onFinish: () -> Void
    @State private var showConfirmation = false
    @AppStorage("distanceUnit") private var distanceUnitRaw: String = DistanceUnit.miles.rawValue

    private var distanceUnit: DistanceUnit {
        DistanceUnit(rawValue: distanceUnitRaw) ?? .miles
    }

    var body: some View {
        ScrollView {
            VStack {
                Text("Workout Paused")
                    .font(.title2)
                    .padding(.bottom, 20)
                Text("Elapsed Time: \(workoutManager.elapsedTime.formatted())")
                Text("Distance: \(workoutManager.distance.formattedDistance(unit: distanceUnit))")
                    .padding(.bottom, 20)

                if workoutManager.workoutState == .saving {
                    ProgressView("Saving Workout...")
                        .padding()
                } else {
                    Button("Resume Workout") {
                        workoutManager.resumeWorkout()
                    }
                    .padding()

                    Button("Finish Workout") {
                        showConfirmation = true
                    }
                    .padding()
                }
            }
            .padding()
        }
        .alert("Finish Workout?", isPresented: $showConfirmation) {
            Button("Save", role: .none) {
                workoutManager.finishWorkout {
                    workoutManager.reset()
                    onFinish()
                }
            }
            Button("Discard", role: .destructive) {
                workoutManager.reset()
                onFinish()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Do you want to save or discard this workout?")
        }
    }
}
