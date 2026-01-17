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
                    PausedView()
                        .environmentObject(workoutManager)
                case .saving:
                    SavingWorkoutView()
                        .environmentObject(workoutManager)
                }
            }
        }
        .onAppear {
            if ProcessInfo.processInfo.arguments.contains("UITEST_DISABLE_HEALTHKIT") {
                return
            }
            workoutManager.requestAuthorization()
        }
    }
}
