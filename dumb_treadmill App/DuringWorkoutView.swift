// File: <YourProjectName>/DuringWorkoutView.swift
import SwiftUI

struct DuringWorkoutView: View {
    @Binding var pace: Double
    @Binding var heartRate: Double
    @Binding var isTracking: Bool
    @ObservedObject private var timerManager = TimerManager()
    @ObservedObject private var heartRateManager = HeartRateManager()
    private let healthKitManager = HealthKitManager()
    
    var body: some View {
        VStack {
            Text("Workout in Progress")
            
            Text("Heart Rate: \(heartRate, specifier: "%.0f") bpm")
            Text("Elapsed Time: \(timerManager.elapsedTime)")
            Text("Distance: \(distanceTraveled(), specifier: "%.2f") miles")
            
            Button(action: {
                timerManager.stop()
                heartRateManager.stopHeartRateQuery()
                isTracking = false
            }) {
                Text("Pause")
            }
            .navigationBarBackButtonHidden(true) // Disable back button
        }
        .padding()
        .onAppear {
            timerManager.start()
            heartRateManager.startHeartRateQuery()
        }
        .onReceive(heartRateManager.$heartRate) { rate in
            self.heartRate = rate
        }
        .background(
            NavigationLink(destination: PausedView(pace: $pace, isTracking: $isTracking, timerManager: timerManager, heartRateManager: heartRateManager), isActive: Binding(
                get: { !isTracking },
                set: { if $0 { isTracking = false } }
            )) {
                EmptyView()
            }
        )
    }
    
    private func distanceTraveled() -> Double {
        return (pace / 3600) * timerManager.elapsedTime
    }
}
