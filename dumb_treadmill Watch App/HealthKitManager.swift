import HealthKit
import Combine

class HealthKitManager: NSObject, ObservableObject {
    private let healthStore = HKHealthStore()
    private var workoutBuilder: HKWorkoutBuilder?
    private var workoutSession: HKWorkoutSession?
    @Published var isAuthorized = false

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

        var typesToShare: Set = [workoutType, heartRateType, distanceType, energyType, effortType]
        var typesToRead: Set = [workoutType, heartRateType, distanceType, energyType, effortType]

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

                let isHeartRateAuthorized = (heartRateStatus == .sharingAuthorized)
                let isWorkoutAuthorized = (workoutStatus == .sharingAuthorized)

                self.isAuthorized = isHeartRateAuthorized && isWorkoutAuthorized

                AppLog.healthKit.info("Authorization status — Heart Rate: \(heartRateStatus.rawValue), Workout: \(workoutStatus.rawValue)")

                if self.isAuthorized {
                    AppLog.healthKit.info("Authorization succeeded for all types.")
                } else {
                    AppLog.healthKit.info("Authorization incomplete. HeartRate: \(isHeartRateAuthorized), Workout: \(isWorkoutAuthorized)")
                }

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

        let workoutConfiguration = HKWorkoutConfiguration()
        workoutConfiguration.activityType = .walking
        workoutConfiguration.locationType = .indoor

        do {
            workoutSession = try HKWorkoutSession(healthStore: healthStore, configuration: workoutConfiguration)
            workoutSession?.delegate = self

            workoutBuilder = HKWorkoutBuilder(healthStore: healthStore, configuration: workoutConfiguration, device: .local())

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
