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
            print("Health data is not available on this device.")
            completion(false)
            return
        }

        let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate)!
        let workoutType = HKObjectType.workoutType()
        let typesToShare: Set = [workoutType, heartRateType]
        let typesToRead: Set = [workoutType, heartRateType]

        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { (success, error) in
            DispatchQueue.main.async {
                if let error = error {
                    print("HealthKit authorization error: \(error.localizedDescription)")
                    self.isAuthorized = false
                    completion(false)
                    return
                }

                let heartRateStatus = self.healthStore.authorizationStatus(for: heartRateType)
                let workoutStatus = self.healthStore.authorizationStatus(for: workoutType)

                let isHeartRateAuthorized = (heartRateStatus == .sharingAuthorized)
                let isWorkoutAuthorized = (workoutStatus == .sharingAuthorized)

                self.isAuthorized = isHeartRateAuthorized && isWorkoutAuthorized

                print("Authorization status — Heart Rate: \(heartRateStatus.rawValue), Workout: \(workoutStatus.rawValue)")

                if self.isAuthorized {
                    print("HealthKit authorization succeeded for all types.")
                } else {
                    print("HealthKit not fully authorized. HeartRate (read or share): \(isHeartRateAuthorized), Workout: \(isWorkoutAuthorized)")
                }

                completion(self.isAuthorized)
            }
        }
    }
    
    // Start a workout session
    func startWorkout() {
        guard isAuthorized, HKHealthStore.isHealthDataAvailable() else {
            print("HealthKit not authorized or data unavailable.")
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
                    print("Error starting workout collection: \(error.localizedDescription)")
                } else {
                    print("Workout session and builder started successfully")
                }
            }
        } catch {
            print("Failed to start workout session: \(error.localizedDescription)")
        }
    }

    // End the workout and save it to HealthKit
    func endWorkout(startDate: Date, endDate: Date, distance: Double, totalEnergyBurned: Double, completion: @escaping () -> Void) {
        // Ensure to update the workout with actual distance and energy burned values from the tracked session
        print("Ending workout with startDate: \(startDate), endDate: \(endDate), distance: \(distance), energy burned: \(totalEnergyBurned)")

        let distanceQuantity = HKQuantity(unit: .meter(), doubleValue: distance)
        let energyQuantity = HKQuantity(unit: .kilocalorie(), doubleValue: totalEnergyBurned)
        
        // Create HKQuantitySample objects with the actual start and end times
        let distanceSample = HKQuantitySample(
            type: HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
            quantity: distanceQuantity,
            start: startDate,
            end: endDate
        )
        
        let energySample = HKQuantitySample(
            type: HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            quantity: energyQuantity,
            start: startDate,
            end: endDate
        )
        
        // Add the samples to the workout builder
        workoutBuilder?.add([distanceSample, energySample]) { success, error in
            print("Attempting to add samples to workout builder...")
            
            if let error = error {
                print("Error adding workout data: \(error.localizedDescription)")
                completion()
                return
            }
            
            print("Workout data added successfully. Ending workout collection...")
            
            self.workoutBuilder?.endCollection(withEnd: endDate) { success, error in
                if let error = error {
                    print("Error ending workout collection: \(error.localizedDescription)")
                    completion()
                    return
                }
                
                print("Workout collection ended successfully. Proceeding to finish workout...")
                self.workoutBuilder?.finishWorkout { workout, error in
                    // Debug point before finishing
                    print("Attempting to finish the workout...")
                    
                    if let error = error {
                        print("Error finishing workout: \(error.localizedDescription)")
                    } else {
                        print("Workout successfully saved: \(String(describing: workout))")
                    }
                    completion()
                }
            }
        }
    }

    // Expose the HKHealthStore instance
    func getHealthStore() -> HKHealthStore {
        return healthStore
    }
}

// MARK: - HKWorkoutSessionDelegate
extension HealthKitManager: HKWorkoutSessionDelegate {
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        print("Workout session changed from \(fromState.rawValue) to \(toState.rawValue) at \(date)")
    }

    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        print("Workout session failed: \(error.localizedDescription)")
    }
    // Stream samples to the active workout builder
    func add(samples: [HKSample]) {
        workoutBuilder?.add(samples) { success, error in
            if let error = error {
                print("Error adding samples: \(error.localizedDescription)")
            } else {
                print("Successfully added streaming samples.")
            }
        }
    }
}
