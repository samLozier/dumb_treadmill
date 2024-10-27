// File: <YourProjectName>/PausedView.swift
import SwiftUI

struct PausedView: View {
    @Binding var pace: Double
    @Binding var isTracking: Bool
    @Binding var showPausedView: Bool // Add this binding to control navigation
    @ObservedObject var timerManager: TimerManager
    @ObservedObject var heartRateManager: HeartRateManager
    
    var body: some View {
        VStack {
            Text("Workout Paused")
                .font(.title)
            
            Button(action: resumeWorkout) {
                Text("Resume Workout")
            }
            .padding()
            
            Button(action: finishWorkout) {
                Text("Finish Workout")
            }
            .padding()
        }
        .padding()
    }
    
    private func resumeWorkout() {
        // Set the state to resume workout
        isTracking = true
        showPausedView = false // Close the paused view and return to DuringWorkoutView
        timerManager.start() // Resume the timer
        heartRateManager.startHeartRateQuery() // Resume heart rate monitoring
    }
    
    private func finishWorkout() {
        // Save workout data if needed, then reset the tracking state
        isTracking = false
        showPausedView = false // Close the paused view and return to PreStartView
    }
}
