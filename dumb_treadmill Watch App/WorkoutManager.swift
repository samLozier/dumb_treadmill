// File: WorkoutManager.swift
import Foundation
import HealthKit
import Combine

enum WorkoutState {
    case idle, active, paused, saving
}

enum SaveState {
    case idle, saving, completed, failed
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
    @Published var saveState: SaveState = .idle
    @Published var healthKitAvailable: Bool = false
    @Published var distanceWriteAuthorized: Bool = false

    @Published var finalStartDate: Date = Date()
    @Published var finalEndDate: Date = Date()
    @Published var finalDistance: Double = 0
    @Published var finalEnergyBurned: Double = 0
    @Published var finalWorkout: HKWorkout?
    @Published var currentPaceMph: Double = 3.0
    @Published var segments: [WorkoutSegment] = []
    @Published var userWeightLbs: Double = 185.0
    @Published var userHeightCm: Double?
    @Published var userAgeYears: Int?
    @Published var userBiologicalSex: HKBiologicalSex?

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
    private var lastSampleDate: Date?
    private var workoutStartDate: Date?
    private var usesHealthKitEnergy = false

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
            .sink { [weak self] value in
                guard let self else { return }
                if !self.usesHealthKitEnergy {
                    self.totalEnergyBurned = value
                }
            }
            .store(in: &cancellables)

        timerManager.$distance
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.recordSampleData()
            }
            .store(in: &cancellables)

        healthKitManager.$activeEnergyBurned
            .receive(on: RunLoop.main)
            .sink { [weak self] value in
                guard let self else { return }
                if self.usesHealthKitEnergy {
                    self.totalEnergyBurned = value
                }
            }
            .store(in: &cancellables)

        healthKitManager.$isDistanceAuthorized
            .receive(on: RunLoop.main)
            .assign(to: \.distanceWriteAuthorized, on: self)
            .store(in: &cancellables)

        healthKitManager.$bodyMassKg
            .receive(on: RunLoop.main)
            .sink { [weak self] value in
                guard let self, let value else { return }
                self.userWeightLbs = value * 2.20462262
            }
            .store(in: &cancellables)

        healthKitManager.$heightCm
            .receive(on: RunLoop.main)
            .assign(to: \.userHeightCm, on: self)
            .store(in: &cancellables)

        healthKitManager.$ageYears
            .receive(on: RunLoop.main)
            .assign(to: \.userAgeYears, on: self)
            .store(in: &cancellables)

        healthKitManager.$biologicalSex
            .receive(on: RunLoop.main)
            .assign(to: \.userBiologicalSex, on: self)
            .store(in: &cancellables)
    }

    func requestAuthorization() {
        guard HKHealthStore.isHealthDataAvailable() else {
            AppLog.workout.error("Health data not available on this device.")
            healthKitAvailable = false
            return
        }

        healthKitManager.requestAuthorization { success in
            DispatchQueue.main.async {
                self.healthKitAvailable = success
                if success {
                    AppLog.workout.info("HealthKit authorization granted.")
                    self.onHealthKitAuthorized()
                } else {
                    AppLog.workout.error("HealthKit authorization failed or not granted.")
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

    func startWorkout(pace: Double) {
        if healthKitAvailable && !distanceWriteAuthorized {
            AppLog.workout.error("Distance write not authorized; blocking workout start.")
            return
        }

        let calculatedCalories = caloriesPerSecondForPace(pace)
        currentPaceMph = pace
        self.caloriesPerSecond = calculatedCalories
        workoutState = .active
        workoutStartDate = Date()
        // Use locally computed calories to avoid HealthKit motion-derived energy.
        usesHealthKitEnergy = false
        totalEnergyBurned = 0

        healthKitManager.startWorkout()
        heartRateManager.startHeartRateQuery()
        timerManager.start(pace: pace, caloriesPerSecond: calculatedCalories)

        segments.removeAll()
        segmentStartElapsedTime = 0
        segmentStartDistance = 0
        segmentStartEnergy = 0
        segmentPaceMph = pace
        lastRecordedDistance = 0
        lastRecordedEnergy = 0
        lastSampleDate = Date()
    }

    func pauseWorkout() {
        workoutState = .paused
        timerManager.pause()
        heartRateManager.stopHeartRateQuery()
        healthKitManager.pauseWorkout()
        lastSampleDate = nil
    }

    func resumeWorkout() {
        workoutState = .active
        timerManager.resume()
        heartRateManager.startHeartRateQuery()
        healthKitManager.resumeWorkout()
        lastSampleDate = Date()
    }

    func updatePace(paceMph: Double) {
        currentPaceMph = paceMph
        let calculatedCalories = caloriesPerSecondForPace(paceMph)
        updateSegmentsForPaceChange(to: paceMph)
        timerManager.updatePace(pace: paceMph, caloriesPerSecond: calculatedCalories)
    }

    func finishWorkout(onComplete: @escaping () -> Void) {
        workoutState = .saving
        saveState = .saving
        finalWorkout = nil

        finalizeCurrentSegment()
        recordSampleData()

        timerManager.stop()
        heartRateManager.stopHeartRateQuery()

        let endDate = Date()
        let startDate = workoutStartDate ?? endDate.addingTimeInterval(-elapsedTime)
        self.finalStartDate = startDate
        self.finalEndDate = endDate
        self.finalDistance = distance
        self.finalEnergyBurned = totalEnergyBurned

        healthKitManager.endWorkout(startDate: startDate, endDate: endDate) { workout in
            DispatchQueue.main.async {
                self.finalWorkout = workout
                if workout == nil {
                    self.saveState = .failed
                } else {
                    self.saveState = .completed
                }
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
        lastSampleDate = nil
        workoutStartDate = nil
        usesHealthKitEnergy = false
    }

    func completeSaving() {
        saveState = .idle
        finalWorkout = nil
        reset()
    }

    func handleSaveFailure() {
        saveState = .idle
        workoutState = .paused
    }

    func discardWorkout() {
        timerManager.stop()
        heartRateManager.stopHeartRateQuery()
        healthKitManager.pauseWorkout()
        healthKitManager.discardWorkout()
        saveState = .idle
        reset()
    }

    private func caloriesPerSecondForPace(_ paceMph: Double) -> Double {
        guard paceMph > 0 else {
            return 0
        }

        let met = metForTreadmillSpeed(paceMph)
        let weightKg = userWeightLbs * 0.45359237
        let caloriesPerMinute: Double

        if let heightCm = userHeightCm, let ageYears = userAgeYears, let sex = userBiologicalSex {
            let sexConstant: Double
            switch sex {
            case .male:
                sexConstant = 5.0
            case .female:
                sexConstant = -161.0
            default:
                sexConstant = 0.0
            }
            let bmr = 10.0 * weightKg + 6.25 * heightCm - 5.0 * Double(ageYears) + sexConstant
            caloriesPerMinute = met * (bmr / 1440.0)
        } else {
            caloriesPerMinute = met * weightKg * 3.5 / 200.0
        }

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
            AppLog.workout.info("HealthKit not available; skipping sample recording.")
            return
        }

        guard healthKitManager.isAuthorized else {
            AppLog.workout.info("HealthKit write access not granted; skipping sample recording.")
            return
        }

        let now = Date()
        guard let startTime = lastSampleDate else {
            lastSampleDate = now
            lastRecordedDistance = distance
            lastRecordedEnergy = totalEnergyBurned
            return
        }

        let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!
        let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
        let canWriteDistance = healthKitManager.authorizationStatus(for: distanceType) == .sharingAuthorized
        let canWriteEnergy = !usesHealthKitEnergy && healthKitManager.authorizationStatus(for: energyType) == .sharingAuthorized
        let rawDeltaDistance = distance - lastRecordedDistance
        let rawDeltaEnergy = totalEnergyBurned - lastRecordedEnergy
        let deltaDistance = canWriteDistance ? rawDeltaDistance : 0
        let deltaEnergy = canWriteEnergy ? rawDeltaEnergy : 0

        guard deltaDistance > 0 || deltaEnergy > 0 else {
            lastSampleDate = now
            lastRecordedDistance = distance
            lastRecordedEnergy = totalEnergyBurned
            return
        }

        var samples: [HKSample] = []
        if deltaDistance > 0 {
            let distanceQuantity = HKQuantity(unit: .meter(), doubleValue: deltaDistance)
            let distanceSample = HKQuantitySample(type: distanceType, quantity: distanceQuantity, start: startTime, end: now)
            samples.append(distanceSample)
        }

        if deltaEnergy > 0 {
            let energyQuantity = HKQuantity(unit: .kilocalorie(), doubleValue: deltaEnergy)
            let energySample = HKQuantitySample(type: energyType, quantity: energyQuantity, start: startTime, end: now)
            samples.append(energySample)
        }

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

        if !samples.isEmpty {
            healthKitManager.add(samples: samples)
        }

        lastRecordedDistance = distance
        lastRecordedEnergy = totalEnergyBurned
        lastSampleDate = now
    }
}
