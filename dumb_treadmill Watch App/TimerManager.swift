import Foundation
import Combine

class TimerManager: ObservableObject {
    @Published var elapsedTime: TimeInterval = 0
    @Published var distance: Double = 0.0
    @Published var totalEnergyBurned: Double = 0.0
    var startDate: Date? // New property to track the workout start time

    private var timer: AnyCancellable?
    private var caloriesPerSecond: Double = 0.1 // Example calories per second (adjust as needed)
    private var pace: Double = 2.5 // Example pace in meters per second (adjust as needed)

    func start(pace: Double, caloriesPerSecond: Double) {
        timer?.cancel()
        startDate = Date()
        elapsedTime = 0
        distance = 0.0
        totalEnergyBurned = 0.0

        self.pace = pace / 3600.0
        self.caloriesPerSecond = caloriesPerSecond

        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.elapsedTime += 1
                self.distance += self.pace
                self.totalEnergyBurned += self.caloriesPerSecond
            }
    }

    func pause() {
        timer?.cancel()
    }

    func resume() {
        timer?.cancel()
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.elapsedTime += 1
                self.distance += self.pace
                self.totalEnergyBurned += self.caloriesPerSecond
            }
    }

    func stop() {
        // Stop the timer
        timer?.cancel()
    }
    
    func reset() {
        // Reset all metrics
        elapsedTime = 0
        distance = 0.0
        totalEnergyBurned = 0.0
        startDate = nil // Clear the start date when the workout is reset
        timer?.cancel()
    }
}
