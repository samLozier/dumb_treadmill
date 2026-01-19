import Foundation
import Combine

class TimerManager: ObservableObject {
    @Published var elapsedTime: TimeInterval = 0
    @Published var distance: Double = 0.0
    @Published var totalEnergyBurned: Double = 0.0

    private var timer: AnyCancellable?
    private var caloriesPerSecond: Double = 0.1 // Example calories per second (adjust as needed)
    private var paceMetersPerSecond: Double = 1.0
    private var lastTickDate: Date?

    func start(pace: Double, caloriesPerSecond: Double, useTimer: Bool = true) {
        timer?.cancel()
        elapsedTime = 0
        distance = 0.0
        totalEnergyBurned = 0.0
        lastTickDate = Date()

        updatePace(pace: pace, caloriesPerSecond: caloriesPerSecond)

        if useTimer {
            timer = Timer.publish(every: 1, on: .main, in: .common)
                .autoconnect()
                .sink { [weak self] _ in
                    self?.tick()
                }
        }
    }

    func pause() {
        timer?.cancel()
        lastTickDate = nil
    }

    func resume() {
        timer?.cancel()
        lastTickDate = Date()
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tick()
            }
    }

    func stop() {
        // Stop the timer
        timer?.cancel()
        lastTickDate = nil
    }
    
    func reset() {
        // Reset all metrics
        elapsedTime = 0
        distance = 0.0
        totalEnergyBurned = 0.0
        timer?.cancel()
        lastTickDate = nil
    }

    func updatePace(pace: Double, caloriesPerSecond: Double) {
        self.paceMetersPerSecond = pace * 1609.344 / 3600.0
        self.caloriesPerSecond = caloriesPerSecond
    }

    func tick(delta: TimeInterval? = nil) {
        let now = Date()
        let actualDelta: TimeInterval

        if let delta = delta {
            actualDelta = delta
        } else if let lastTickDate = lastTickDate {
            actualDelta = now.timeIntervalSince(lastTickDate)
        } else {
            lastTickDate = now
            return
        }

        lastTickDate = now
        elapsedTime += actualDelta
        distance += paceMetersPerSecond * actualDelta
        totalEnergyBurned += caloriesPerSecond * actualDelta
    }
}
