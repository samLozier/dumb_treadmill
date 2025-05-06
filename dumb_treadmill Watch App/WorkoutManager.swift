// File: WorkoutManager.swift
import Foundation
import HealthKit
import Combine

enum WorkoutState {
    case idle, active, paused, saving
}

class WorkoutManager: ObservableObject {
    @Published var heartRate: Double = 0.0
    @Published var elapsedTime: TimeInterval = 0
    @Published var distance: Double = 0
    @Published var totalEnergyBurned: Double = 0
    @Published var workoutState: WorkoutState = .idle
    @Published var saveError: Bool = false
    @Published var healthKitAvailable: Bool = false

    private let healthKitManager = HealthKitManager()
    private let heartRateManager: HeartRateManager
    private let timerManager = TimerManager()

    private var pace: Double = 0.0
    private var caloriesPerSecond: Double = 0.1

    private var cancellables = Set<AnyCancellable>()

    init() {
        self.heartRateManager = HeartRateManager(healthKitManager: healthKitManager)

        timerManager.$elapsedTime
            .receive(on: RunLoop.main)
            .assign(to: \.elapsedTime, on: self)
            .store(in: &cancellables)

        timerManager.$distance
            .receive(on: RunLoop.main)
            .assign(to: \.distance, on: self)
            .store(in: &cancellables)

        timerManager.$totalEnergyBurned
            .receive(on: RunLoop.main)
            .assign(to: \.totalEnergyBurned, on: self)
            .store(in: &cancellables)

        timerManager.$elapsedTime
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.recordSampleData()
            }
            .store(in: &cancellables)
    }

    func requestAuthorization() {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("Health data not available on this device.")
            healthKitAvailable = false
            return
        }

        healthKitManager.requestAuthorization { success in
            DispatchQueue.main.async {
                self.healthKitAvailable = success
                if success {
                    print("HealthKit authorization granted.")
                    self.onHealthKitAuthorized()
                } else {
                    print("HealthKit authorization failed or not granted.")
                }
            }
        }
    }

    private func onHealthKitAuthorized() {
        heartRateManager.$heartRate
            .receive(on: RunLoop.main)
            .assign(to: \.heartRate, on: self)
            .store(in: &cancellables)

        heartRateManager.startHeartRateQuery()
    }

    func startWorkout(pace: Double, caloriesPerSecond: Double = 0.1) {
        self.pace = pace
        self.caloriesPerSecond = caloriesPerSecond
        workoutState = .active

        healthKitManager.startWorkout()
        heartRateManager.startHeartRateQuery()
        timerManager.start(pace: pace, caloriesPerSecond: caloriesPerSecond)
    }

    func pauseWorkout() {
        workoutState = .paused
        timerManager.pause()
        heartRateManager.stopHeartRateQuery()
    }

    func resumeWorkout() {
        workoutState = .active
        timerManager.resume()
        heartRateManager.startHeartRateQuery()
    }

    func finishWorkout(onComplete: @escaping () -> Void) {
        workoutState = .saving

        timerManager.stop()
        heartRateManager.stopHeartRateQuery()

        let startDate = Date().addingTimeInterval(-elapsedTime)
        let endDate = Date()
        var didComplete = false

        let timeoutWorkItem = DispatchWorkItem {
            if !didComplete {
                print("Timeout: Failed to save workout in time.")
                self.workoutState = .paused
                self.saveError = true
                onComplete()
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 10, execute: timeoutWorkItem)

        healthKitManager.endWorkout(
            startDate: startDate,
            endDate: endDate,
            distance: distance,
            totalEnergyBurned: totalEnergyBurned
        ) {
            didComplete = true
            timeoutWorkItem.cancel()

            DispatchQueue.main.async {
                self.workoutState = .idle
                self.reset()
                onComplete()
            }
        }
    }

    func reset() {
        heartRate = 0
        elapsedTime = 0
        distance = 0
        totalEnergyBurned = 0
        workoutState = .idle
    }

    private func recordSampleData() {
        let now = Date()
        let distanceQuantity = HKQuantity(unit: .mile(), doubleValue: distance)
        let energyQuantity = HKQuantity(unit: .kilocalorie(), doubleValue: totalEnergyBurned)

        let distanceSample = HKQuantitySample(type: HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!, quantity: distanceQuantity, start: now.addingTimeInterval(-1), end: now)
        let energySample = HKQuantitySample(type: HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!, quantity: energyQuantity, start: now.addingTimeInterval(-1), end: now)

        healthKitManager.add(samples: [distanceSample, energySample])
    }
}
