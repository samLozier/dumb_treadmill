// File: <YourProjectName>/ContentView.swift
import SwiftUI

struct ContentView: View {
    @State private var pace: Double = 0.0
    @State private var heartRate: Double = 0.0
    @State private var isTracking = false
    @State private var showPausedView = false
    @ObservedObject private var heartRateManager = HeartRateManager()
    private var timerManager = TimerManager()
    
    var body: some View {
        NavigationStack {
            VStack {
                if !isTracking {
                    PreStartView(
                        pace: $pace,
                        heartRate: $heartRate,
                        isTracking: $isTracking,
                        showPausedView: $showPausedView,
                        timerManager: timerManager,
                        heartRateManager: heartRateManager
                    )
                } else {
                    DuringWorkoutView(
                        pace: $pace,
                        heartRate: $heartRate,
                        isTracking: $isTracking,
                        showPausedView: $showPausedView,
                        timerManager: timerManager,
                        heartRateManager: heartRateManager
                    )
                }
            }
            // Ensure `navigationDestination` is directly in the NavigationStack
            .navigationDestination(isPresented: $showPausedView) {
                PausedView(
                    pace: $pace,
                    isTracking: $isTracking,
                    showPausedView: $showPausedView,
                    timerManager: timerManager,
                    heartRateManager: heartRateManager
                )
            }
        }
        .onReceive(heartRateManager.$heartRate) { rate in
            self.heartRate = rate
        }
    }
}
