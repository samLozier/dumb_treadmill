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

    private let healthKitManager = HealthKitManager()
    private let heartRateManager: HeartRateManager
    private let timerManager = TimerManager()

    private var pace: Double = 0.0
    private var caloriesPerSecond: Double = 0.1

    private var cancellables = Set<AnyCancellable>()

    init() {
        self.heartRateManager = HeartRateManager(healthKitManager: healthKitManager)
        heartRateManager.$heartRate
            .receive(on: RunLoop.main)
            .assign(to: \.heartRate, on: self)
            .store(in: &cancellables)

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

        requestAuthorization()
    }

    func requestAuthorization() {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("Health data not available on this device.")
            return
        }

        let healthStore = healthKitManager.getHealthStore()

        let readTypes: Set = [
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.workoutType()
        ]

        let writeTypes: Set = [
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.workoutType(),
            HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!
        ]

        healthStore.requestAuthorization(toShare: writeTypes, read: readTypes) { success, error in
            if let error = error {
                print("HealthKit authorization error: \(error.localizedDescription)")
            } else if !success {
                print("HealthKit authorization not granted.")
            }
        }
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

        healthKitManager.endWorkout(
            startDate: Date().addingTimeInterval(-elapsedTime),
            endDate: Date(),
            distance: distance,
            totalEnergyBurned: totalEnergyBurned
        ) {
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
