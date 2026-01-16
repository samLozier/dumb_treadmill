import SwiftUI

struct ContentView: View {
    @EnvironmentObject var workoutManager: WorkoutManager

    var body: some View {
        NavigationStack {
            VStack {
                switch workoutManager.workoutState {
                case .idle:
                    PreStartView()
                        .environmentObject(workoutManager)
                case .active:
                    DuringWorkoutView()
                        .environmentObject(workoutManager)
                case .paused:
                    PausedView(
                        onFinish: {
                            workoutManager.finishWorkout(onComplete: {})
                        }
                    )
                    .environmentObject(workoutManager)
                case .saving:
                    SavingWorkoutView()
                        .environmentObject(workoutManager)
                }
            }
        }
        .onAppear {
            workoutManager.requestAuthorization()
        }
    }
}
