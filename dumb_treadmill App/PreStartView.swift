// File: <YourProjectName>/PreStartView.swift
import SwiftUI

struct PreStartView: View {
    @Binding var pace: Double
    @Binding var heartRate: Double
    @Binding var isTracking: Bool
    @Binding var showPausedView: Bool // Add this line
    @ObservedObject var timerManager: TimerManager // Add this line
    @ObservedObject var heartRateManager: HeartRateManager // Add this line
    
    var body: some View {
        VStack {
            Text("Pace: \(pace, specifier: "%.1f") mph")
            Slider(value: $pace, in: 0...10, step: 0.1)
            
            Text("Heart Rate: \(heartRate, specifier: "%.0f") bpm")
            
            NavigationLink(destination: DuringWorkoutView(pace: $pace, heartRate: $heartRate, isTracking: $isTracking, showPausedView: $showPausedView, timerManager: timerManager, heartRateManager: heartRateManager)) {
                Text("Start")
            }
        }
        .padding()
    }
}
