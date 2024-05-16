// File: <YourProjectName>/ContentView.swift
import SwiftUI

struct ContentView: View {
    @State private var pace: Double = 0.0
    @State private var heartRate: Double = 0.0
    @State private var isTracking = false
    @ObservedObject private var heartRateManager = HeartRateManager()
    
    var body: some View {
        NavigationStack {
            if !isTracking {
                PreStartView(pace: $pace, heartRate: $heartRate, isTracking: $isTracking)
            } else {
                DuringWorkoutView(pace: $pace, heartRate: $heartRate, isTracking: $isTracking)
            }
        }
        .onReceive(heartRateManager.$heartRate) { rate in
            self.heartRate = rate
        }
    }
}
