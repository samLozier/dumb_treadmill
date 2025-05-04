import SwiftUI

@main
struct dumb_treadmillApp: App {
    @StateObject var workoutManager = WorkoutManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(workoutManager)
        }
    }
}
