// File: <YourProjectName>/ContentView.swift
import SwiftUI
import HealthKit

struct ContentView: View {
    @State private var pace: Double = 0.0
    @State private var elapsedTime: TimeInterval = 0.0
    @State private var heartRate: Double = 0.0
    @State private var isTracking = false
    @ObservedObject private var timerManager = TimerManager()
    @ObservedObject private var heartRateManager = HeartRateManager()
    private let healthKitManager = HealthKitManager()
    
    var body: some View {
        VStack {
            Text("Pace: \(pace, specifier: "%.1f") mph")
            Slider(value: $pace, in: 0...10, step: 0.1)
            
            Text("Elapsed Time: \(elapsedTime.formattedTime())")
            Text("Heart Rate: \(heartRate, specifier: "%.0f") bpm")
            
            Button(isTracking ? "Stop" : "Start") {
                if isTracking {
                    timerManager.stop()
                    heartRateManager.stopHeartRateQuery()
                    saveWorkout()
                } else {
                    healthKitManager.requestAuthorization { success, error in
                        if success {
                            timerManager.start()
                            heartRateManager.startHeartRateQuery()
                        } else {
                            // Handle authorization failure
                            print("HealthKit authorization failed: \(String(describing: error?.localizedDescription))")
                        }
                    }
                }
                isTracking.toggle()
            }
        }
        .padding()
        .onReceive(timerManager.$elapsedTime) { time in
            self.elapsedTime = time
        }
        .onReceive(heartRateManager.$heartRate) { rate in
            self.heartRate = rate
        }
    }
    
    func saveWorkout() {
        let distance = (pace / 3600) * elapsedTime // Convert pace (mph) and time (seconds) to distance (miles)
        healthKitManager.saveWorkout(distance: distance, duration: elapsedTime, heartRate: [heartRate])
    }
}

extension TimeInterval {
    func formattedTime() -> String {
        let minutes = Int(self) / 60
        let seconds = Int(self) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
