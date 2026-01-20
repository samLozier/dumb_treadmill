import HealthKit
import Combine

class HealthKitManager: NSObject, ObservableObject {
    private let healthStore = HKHealthStore()
    private var workoutBuilder: HKLiveWorkoutBuilder?
    private var workoutSession: HKWorkoutSession?
    @Published var isAuthorized = false
    @Published var isDistanceAuthorized = false
    @Published var isEnergyAuthorized = false
    @Published var activeEnergyBurned: Double = 0
    @Published var bodyMassKg: Double?
    @Published var heightCm: Double?
    @Published var ageYears: Int?
    @Published var biologicalSex: HKBiologicalSex?

    // Request authorization to read and write HealthKit data
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else {
            AppLog.healthKit.error("Health data is not available on this device.")
            completion(false)
            return
        }

        let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate)!
        let workoutType = HKObjectType.workoutType()
        let distanceType = HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!
        let energyType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!
        let effortType = HKObjectType.quantityType(forIdentifier: .workoutEffortScore)!
        let bodyMassType = HKObjectType.quantityType(forIdentifier: .bodyMass)!
        let heightType = HKObjectType.quantityType(forIdentifier: .height)!
        let biologicalSexType = HKObjectType.characteristicType(forIdentifier: .biologicalSex)!
        let dateOfBirthType = HKObjectType.characteristicType(forIdentifier: .dateOfBirth)!

        var typesToShare: Set = [workoutType, heartRateType, distanceType, energyType, effortType]
        var typesToRead: Set = [workoutType, heartRateType, distanceType, energyType, effortType, bodyMassType, heightType, biologicalSexType, dateOfBirthType]

        if #available(watchOS 10.0, *) {
            let walkingSpeedType = HKObjectType.quantityType(forIdentifier: .walkingSpeed)!
            let runningSpeedType = HKObjectType.quantityType(forIdentifier: .runningSpeed)!
            typesToShare.insert(walkingSpeedType)
            typesToShare.insert(runningSpeedType)
            typesToRead.insert(walkingSpeedType)
            typesToRead.insert(runningSpeedType)
        }

        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { (success, error) in
            DispatchQueue.main.async {
                if let error = error {
                    AppLog.healthKit.error("Authorization error: \(error.localizedDescription)")
                    self.isAuthorized = false
                    completion(false)
                    return
                }

                let heartRateStatus = self.healthStore.authorizationStatus(for: heartRateType)
                let workoutStatus = self.healthStore.authorizationStatus(for: workoutType)
                let distanceStatus = self.healthStore.authorizationStatus(for: distanceType)
                let energyStatus = self.healthStore.authorizationStatus(for: energyType)

                let isHeartRateAuthorized = (heartRateStatus == .sharingAuthorized)
                let isWorkoutAuthorized = (workoutStatus == .sharingAuthorized)
                let isDistanceAuthorized = (distanceStatus == .sharingAuthorized)
                let isEnergyAuthorized = (energyStatus == .sharingAuthorized)

                self.isAuthorized = isHeartRateAuthorized && isWorkoutAuthorized
                self.isDistanceAuthorized = isDistanceAuthorized
                self.isEnergyAuthorized = isEnergyAuthorized

                AppLog.healthKit.info("Authorization status — Heart Rate: \(heartRateStatus.rawValue), Workout: \(workoutStatus.rawValue), Distance: \(distanceStatus.rawValue), Energy: \(energyStatus.rawValue)")

                if self.isAuthorized {
                    AppLog.healthKit.info("Authorization succeeded for all types.")
                } else {
                    AppLog.healthKit.info("Authorization incomplete. HeartRate: \(isHeartRateAuthorized), Workout: \(isWorkoutAuthorized)")
                }

                self.refreshUserProfile()
                completion(self.isAuthorized)
            }
        }
    }
    
    // Start a workout session
    func startWorkout() {
        guard isAuthorized, HKHealthStore.isHealthDataAvailable() else {
            AppLog.healthKit.error("Not authorized or data unavailable.")
            return
        }

        activeEnergyBurned = 0

        let workoutConfiguration = HKWorkoutConfiguration()
        workoutConfiguration.activityType = .walking
        workoutConfiguration.locationType = .indoor

        do {
            workoutSession = try HKWorkoutSession(healthStore: healthStore, configuration: workoutConfiguration)
            workoutSession?.delegate = self

            guard let builder = workoutSession?.associatedWorkoutBuilder() else {
                AppLog.healthKit.error("Unable to create workout builder.")
                return
            }

            workoutBuilder = builder
            workoutBuilder?.delegate = self
            // Use manual samples for treadmill distance; avoid motion-derived distance.
            workoutBuilder?.dataSource = nil

            workoutSession?.startActivity(with: Date())
            workoutBuilder?.beginCollection(withStart: Date()) { (success, error) in
                if let error = error {
                    AppLog.healthKit.error("Start collection error: \(error.localizedDescription)")
                } else {
                    AppLog.healthKit.info("Workout session and builder started.")
                }
            }
        } catch {
            AppLog.healthKit.error("Failed to start workout session: \(error.localizedDescription)")
        }
    }

    func pauseWorkout() {
        workoutSession?.pause()
    }

    func resumeWorkout() {
        workoutSession?.resume()
    }

    // End the workout and save it to HealthKit
    func endWorkout(startDate: Date, endDate: Date, completion: @escaping (HKWorkout?) -> Void) {
        AppLog.healthKit.info("Ending workout start=\(startDate) end=\(endDate)")

        workoutSession?.end()

        guard let workoutBuilder = workoutBuilder else {
            AppLog.healthKit.error("Workout builder missing; cannot finish workout.")
            completion(nil)
            return
        }

        AppLog.healthKit.info("Ending workout collection.")
        workoutBuilder.endCollection(withEnd: endDate) { success, error in
            if let error = error {
                AppLog.healthKit.error("End collection error: \(error.localizedDescription)")
                completion(nil)
                return
            }

            AppLog.healthKit.info("Collection ended. Finishing workout.")
            workoutBuilder.finishWorkout { workout, error in
                AppLog.healthKit.info("Finishing workout.")

                if let error = error {
                    AppLog.healthKit.error("Finish error: \(error.localizedDescription)")
                    completion(nil)
                } else {
                    AppLog.healthKit.info("Workout saved: \(String(describing: workout))")
                    completion(workout)
                }
            }
        }
    }

    // Expose the HKHealthStore instance
    func getHealthStore() -> HKHealthStore {
        return healthStore
    }

    func authorizationStatus(for type: HKObjectType) -> HKAuthorizationStatus {
        return healthStore.authorizationStatus(for: type)
    }

    func saveWorkoutEffort(score: Double, workout: HKWorkout, completion: @escaping (Bool) -> Void) {
        let effortType = HKQuantityType.quantityType(forIdentifier: .workoutEffortScore)!
        let effortUnit = HKUnit.appleEffortScore()
        let effortQuantity = HKQuantity(unit: effortUnit, doubleValue: score)
        let sample = HKQuantitySample(type: effortType, quantity: effortQuantity, start: workout.startDate, end: workout.endDate)

        healthStore.save(sample) { success, error in
            if let error = error {
                AppLog.healthKit.error("Save effort error: \(error.localizedDescription)")
            }

            guard success else {
                DispatchQueue.main.async {
                    completion(false)
                }
                return
            }

            self.healthStore.relateWorkoutEffortSample(sample, with: workout, activity: nil) { relateSuccess, relateError in
                if let relateError = relateError {
                    AppLog.healthKit.error("Relate effort error: \(relateError.localizedDescription)")
                }

                DispatchQueue.main.async {
                    completion(relateSuccess)
                }
            }
        }
    }

    func discardWorkout() {
        workoutSession?.end()
        workoutBuilder?.discardWorkout()
        workoutBuilder = nil
        workoutSession = nil
        activeEnergyBurned = 0
    }

    func refreshUserProfile() {
        guard HKHealthStore.isHealthDataAvailable() else {
            return
        }

        readMostRecentQuantitySample(for: .bodyMass, unit: .gramUnit(with: .kilo)) { [weak self] value in
            self?.bodyMassKg = value
        }

        readMostRecentQuantitySample(for: .height, unit: .meter()) { [weak self] value in
            guard let value else {
                self?.heightCm = nil
                return
            }
            self?.heightCm = value * 100.0
        }

        do {
            let birthDateComponents = try healthStore.dateOfBirthComponents()
            if let birthYear = birthDateComponents.year {
                let currentYear = Calendar.current.component(.year, from: Date())
                let computedAge = max(0, currentYear - birthYear)
                DispatchQueue.main.async {
                    self.ageYears = computedAge
                }
            }
        } catch {
            AppLog.healthKit.info("Date of birth unavailable: \(error.localizedDescription)")
        }

        do {
            let sex = try healthStore.biologicalSex()
            DispatchQueue.main.async {
                self.biologicalSex = sex.biologicalSex
            }
        } catch {
            AppLog.healthKit.info("Biological sex unavailable: \(error.localizedDescription)")
        }
    }

    private func readMostRecentQuantitySample(for identifier: HKQuantityTypeIdentifier, unit: HKUnit, completion: @escaping (Double?) -> Void) {
        guard let quantityType = HKObjectType.quantityType(forIdentifier: identifier) else {
            completion(nil)
            return
        }

        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let query = HKSampleQuery(sampleType: quantityType, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor], resultsHandler: { _, samples, _ in
            guard let sample = samples?.first as? HKQuantitySample else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }

            let value = sample.quantity.doubleValue(for: unit)
            DispatchQueue.main.async {
                completion(value)
            }
        })

        healthStore.execute(query)
    }
}

// MARK: - HKWorkoutSessionDelegate
extension HealthKitManager: HKWorkoutSessionDelegate {
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        AppLog.healthKit.info("Workout session state \(fromState.rawValue) -> \(toState.rawValue) at \(date)")
    }

    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        AppLog.healthKit.error("Workout session failed: \(error.localizedDescription)")
    }
    // Stream samples to the active workout builder
    func add(samples: [HKSample]) {
        workoutBuilder?.add(samples) { success, error in
            if let error = error {
                AppLog.healthKit.error("Add sample error: \(error.localizedDescription)")
            } else {
                AppLog.healthKit.debug("Streaming samples added.")
            }
        }
    }
}

// MARK: - HKLiveWorkoutBuilderDelegate
extension HealthKitManager: HKLiveWorkoutBuilderDelegate {
    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) { }

    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
        guard collectedTypes.contains(energyType) else {
            return
        }

        if let statistics = workoutBuilder.statistics(for: energyType),
           let sum = statistics.sumQuantity() {
            let calories = sum.doubleValue(for: .kilocalorie())
            DispatchQueue.main.async {
                self.activeEnergyBurned = calories
            }
        }
    }
}
