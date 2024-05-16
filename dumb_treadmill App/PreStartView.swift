// File: <YourProjectName>/PreStartView.swift
import SwiftUI

struct PreStartView: View {
    @Binding var pace: Double
    @Binding var heartRate: Double
    @Binding var isTracking: Bool
    
    var body: some View {
        VStack {
            Text("Pace: \(pace, specifier: "%.1f") mph")
            Slider(value: $pace, in: 0...10, step: 0.1)
            
            Text("Heart Rate: \(heartRate, specifier: "%.0f") bpm")
            
            NavigationLink(destination: DuringWorkoutView(pace: $pace, heartRate: $heartRate, isTracking: $isTracking)) {
                Text("Start")
            }
        }
        .padding()
    }
}
