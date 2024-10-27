// File: <YourProjectName>/DuringWorkoutView.swift
import SwiftUI

struct DuringWorkoutView: View {
    @Binding var pace: Double
    @Binding var heartRate: Double
    @Binding var isTracking: Bool
    @Binding var showPausedView: Bool // Accept the binding for showPausedView
    @ObservedObject var timerManager: TimerManager
    @ObservedObject var heartRateManager: HeartRateManager
    
    var body: some View {
        VStack {
            Text("Workout in Progress")
            
            Text("Heart Rate: \(heartRate, specifier: "%.0f") bpm")
            Text("Elapsed Time: \(timerManager.elapsedTime.formattedTime())")
            Text("Distance: \(distanceTraveled(), specifier: "%.2f") miles")
            
            Button(action: {
                pauseWorkout()
            }) {
                Text("Pause")
            }
            .navigationBarBackButtonHidden(true) // Disable back button
        }
        .padding()
        .onAppear {
            startWorkout()
        }
        .onReceive(heartRateManager.$heartRate) { rate in
            self.heartRate = rate
        }
    }
    
    private func startWorkout() {
        timerManager.start()
        heartRateManager.startHeartRateQuery()
        isTracking = true
    }

    private func pauseWorkout() {
        timerManager.stop()
        heartRateManager.stopHeartRateQuery()
        isTracking = false
        showPausedView = true // Trigger navigation
    }
    
    private func distanceTraveled() -> Double {
        return (pace / 3600) * timerManager.elapsedTime
    }
}
