// File: <YourProjectName>/PausedView.swift
import SwiftUI

struct PausedView: View {
    @Binding var pace: Double
    @Binding var isTracking: Bool
    @ObservedObject var timerManager: TimerManager
    @ObservedObject var heartRateManager: HeartRateManager
    private let healthKitManager = HealthKitManager()
    
    var body: some View {
        VStack {
            Text("Workout Paused")
            
            Button(action: {
                timerManager.start()
                heartRateManager.startHeartRateQuery()
                isTracking = true
            }) {
                Text("Resume Workout")
            }
            
            Button(action: {
                saveWorkout()
                isTracking = false
            }) {
                Text("Finish Workout")
            }
        }
        .padding()
    }
    
    func saveWorkout() {
        let distance = (pace / 3600) * timerManager.elapsedTime // Convert pace (mph) and time (seconds) to distance (miles)
        healthKitManager.saveWorkout(distance: distance, duration: timerManager.elapsedTime, heartRate: [heartRateManager.heartRate])
    }
}
