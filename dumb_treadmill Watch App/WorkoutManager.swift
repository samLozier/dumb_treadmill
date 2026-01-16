// File: WorkoutManager.swift
import Foundation
import HealthKit
import Combine

enum WorkoutState {
    case idle, active, paused, saving
}

struct WorkoutSegment: Identifiable {
    let id = UUID()
    let paceMph: Double
    let startElapsed: TimeInterval
    let endElapsed: TimeInterval
    let distanceMeters: Double
    let calories: Double
}

class WorkoutManager: ObservableObject {
    @Published var heartRate: Double = 0.0
    @Published var elapsedTime: TimeInterval = 0
    @Published var distance: Double = 0
    @Published var totalEnergyBurned: Double = 0
    @Published var workoutState: WorkoutState = .idle
    @Published var saveError: Bool = false
    @Published var healthKitAvailable: Bool = false

    @Published var finalStartDate: Date = Date()
    @Published var finalDistance: Double = 0
    @Published var finalEnergyBurned: Double = 0
    @Published var saveCompleted: Bool = false
    @Published var finalWorkout: HKWorkout?
    @Published var currentPaceMph: Double = 3.0
    @Published var segments: [WorkoutSegment] = []
    @Published var userWeightLbs: Double = 185.0

    private let healthKitManager = HealthKitManager()
    private let heartRateManager: HeartRateManager
    private let timerManager = TimerManager()

    private var segmentStartElapsedTime: TimeInterval = 0
    private var segmentStartDistance: Double = 0
    private var segmentStartEnergy: Double = 0
    private var segmentPaceMph: Double = 0
    private var caloriesPerSecond: Double = 0.1

    private var lastRecordedDistance: Double = 0
    private var lastRecordedEnergy: Double = 0

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
        let calculatedCalories = caloriesPerSecondForPace(pace)
        currentPaceMph = pace
        self.caloriesPerSecond = calculatedCalories
        workoutState = .active

        healthKitManager.startWorkout()
        heartRateManager.startHeartRateQuery()
        timerManager.start(pace: pace, caloriesPerSecond: calculatedCalories)

        segments.removeAll()
        segmentStartElapsedTime = 0
        segmentStartDistance = 0
        segmentStartEnergy = 0
        segmentPaceMph = pace
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

    func updatePace(paceMph: Double) {
        currentPaceMph = paceMph
        let calculatedCalories = caloriesPerSecondForPace(paceMph)
        updateSegmentsForPaceChange(to: paceMph)
        timerManager.updatePace(pace: paceMph, caloriesPerSecond: calculatedCalories)
    }

    func finishWorkout(onComplete: @escaping () -> Void) {
        workoutState = .saving
        saveCompleted = false
        finalWorkout = nil

        finalizeCurrentSegment()

        timerManager.stop()
        heartRateManager.stopHeartRateQuery()

        let startDate = Date().addingTimeInterval(-elapsedTime)
        let endDate = Date()
        var didComplete = false

        self.finalStartDate = startDate
        self.finalDistance = distance
        self.finalEnergyBurned = totalEnergyBurned

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
        ) { workout in
            didComplete = true
            timeoutWorkItem.cancel()

            DispatchQueue.main.async {
                self.finalWorkout = workout
                self.saveCompleted = true
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
        lastRecordedDistance = 0
        lastRecordedEnergy = 0
        currentPaceMph = 0
        segments.removeAll()
        segmentStartElapsedTime = 0
        segmentStartDistance = 0
        segmentStartEnergy = 0
        segmentPaceMph = 0
    }

    func completeSaving() {
        saveCompleted = false
        finalWorkout = nil
        reset()
    }

    private func caloriesPerSecondForPace(_ paceMph: Double) -> Double {
        guard paceMph > 0 else {
            return 0
        }

        let met = metForTreadmillSpeed(paceMph)
        let weightKg = userWeightLbs * 0.45359237
        let caloriesPerMinute = met * weightKg * 3.5 / 200.0
        return caloriesPerMinute / 60.0
    }

    private func metForTreadmillSpeed(_ paceMph: Double) -> Double {
        let points: [(Double, Double)] = [
            (2.0, 2.5),
            (3.0, 3.3),
            (4.0, 5.0),
            (5.0, 8.3),
            (6.0, 9.8),
            (7.0, 11.0),
            (8.0, 11.8)
        ]

        if paceMph <= points[0].0 {
            return points[0].1
        }

        for index in 1..<points.count {
            let (prevPace, prevMet) = points[index - 1]
            let (nextPace, nextMet) = points[index]
            if paceMph <= nextPace {
                let ratio = (paceMph - prevPace) / (nextPace - prevPace)
                return prevMet + ratio * (nextMet - prevMet)
            }
        }

        let (lastPace, lastMet) = points[points.count - 1]
        let (priorPace, priorMet) = points[points.count - 2]
        let slope = (lastMet - priorMet) / (lastPace - priorPace)
        return lastMet + slope * (paceMph - lastPace)
    }

    private func updateSegmentsForPaceChange(to newPaceMph: Double) {
        let duration = elapsedTime - segmentStartElapsedTime
        guard duration > 0 else {
            segmentPaceMph = newPaceMph
            return
        }

        let segment = WorkoutSegment(
            paceMph: segmentPaceMph,
            startElapsed: segmentStartElapsedTime,
            endElapsed: elapsedTime,
            distanceMeters: distance - segmentStartDistance,
            calories: totalEnergyBurned - segmentStartEnergy
        )
        segments.append(segment)

        segmentStartElapsedTime = elapsedTime
        segmentStartDistance = distance
        segmentStartEnergy = totalEnergyBurned
        segmentPaceMph = newPaceMph
    }

    private func finalizeCurrentSegment() {
        let duration = elapsedTime - segmentStartElapsedTime
        guard duration > 0 else {
            return
        }

        let segment = WorkoutSegment(
            paceMph: segmentPaceMph,
            startElapsed: segmentStartElapsedTime,
            endElapsed: elapsedTime,
            distanceMeters: distance - segmentStartDistance,
            calories: totalEnergyBurned - segmentStartEnergy
        )
        segments.append(segment)

        segmentStartElapsedTime = elapsedTime
        segmentStartDistance = distance
        segmentStartEnergy = totalEnergyBurned
    }

    var canSaveWorkoutEffort: Bool {
        guard healthKitAvailable else {
            return false
        }

        guard let workout = finalWorkout else {
            return false
        }

        let effortType = HKObjectType.quantityType(forIdentifier: .workoutEffortScore)!
        return healthKitManager.authorizationStatus(for: effortType) == .sharingAuthorized && workout.duration > 0
    }

    func saveWorkoutEffort(score: Double, completion: @escaping (Bool) -> Void) {
        guard canSaveWorkoutEffort, let workout = finalWorkout else {
            completion(false)
            return
        }

        healthKitManager.saveWorkoutEffort(score: score, workout: workout, completion: completion)
    }

    private func recordSampleData() {
        guard healthKitAvailable else {
            print("HealthKit not available, skipping sample recording.")
            return
        }

        guard healthKitManager.isAuthorized else {
            print("HealthKit write access not granted, skipping sample recording.")
            return
        }

        let now = Date()
        let deltaDistance = distance - lastRecordedDistance
        let deltaEnergy = totalEnergyBurned - lastRecordedEnergy

        guard deltaDistance > 0 || deltaEnergy > 0 else {
            return
        }

        let distanceQuantity = HKQuantity(unit: .meter(), doubleValue: deltaDistance)
        let energyQuantity = HKQuantity(unit: .kilocalorie(), doubleValue: deltaEnergy)

        let startTime = now.addingTimeInterval(-1)
        let distanceSample = HKQuantitySample(type: HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!, quantity: distanceQuantity, start: startTime, end: now)
        let energySample = HKQuantitySample(type: HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!, quantity: energyQuantity, start: startTime, end: now)

        var samples: [HKSample] = [distanceSample, energySample]

        if #available(watchOS 10.0, *) {
            let speedMetersPerSecond = currentPaceMph * 1609.344 / 3600.0
            if speedMetersPerSecond > 0 {
                let speedUnit = HKUnit.meter().unitDivided(by: .second())
                let speedQuantity = HKQuantity(unit: speedUnit, doubleValue: speedMetersPerSecond)
                let speedType: HKQuantityType
                if currentPaceMph >= 5.0 {
                    speedType = HKQuantityType.quantityType(forIdentifier: .runningSpeed)!
                } else {
                    speedType = HKQuantityType.quantityType(forIdentifier: .walkingSpeed)!
                }

                if healthKitManager.authorizationStatus(for: speedType) == .sharingAuthorized {
                    let speedSample = HKQuantitySample(type: speedType, quantity: speedQuantity, start: startTime, end: now)
                    samples.append(speedSample)
                }
            }
        }

        healthKitManager.add(samples: samples)

        lastRecordedDistance = distance
        lastRecordedEnergy = totalEnergyBurned
    }
}
