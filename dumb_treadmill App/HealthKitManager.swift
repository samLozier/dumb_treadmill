// File: <YourProjectName>/HealthKitManager.swift
import HealthKit

class HealthKitManager: ObservableObject {
    private let healthStore = HKHealthStore()
    private var workoutSession: HKWorkoutSession?
    private var builder: HKLiveWorkoutBuilder?
    
    // Check if HealthKit is available
    func isHealthDataAvailable() -> Bool {
        return HKHealthStore.isHealthDataAvailable()
    }
    
    // Request HealthKit permissions
    func requestAuthorization() {
        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate),
              let distanceType = HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning) else { return }

        let workoutType = HKObjectType.workoutType() // No need to unwrap this
        let typesToShare: Set = [workoutType, distanceType]
        let typesToRead: Set = [heartRateType, distanceType, workoutType]
        
        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { (success, error) in
            if !success {
                print("HealthKit Authorization Failed: \(String(describing: error))")
            }
        }
    }
    
    // Start a workout session
    func startWorkout() {
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .running  // Adjust as needed (e.g., .walking)
        configuration.locationType = .indoor   // Specify location type
        
        do {
            workoutSession = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
            builder = workoutSession?.associatedWorkoutBuilder()
            
            // Set up the data source for collecting live metrics
            builder?.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore, workoutConfiguration: configuration)
            
            // Begin the workout session and start collecting data
            workoutSession?.startActivity(with: Date())
            builder?.beginCollection(withStart: Date()) { (success, error) in
                if let error = error {
                    print("Failed to start workout collection: \(error.localizedDescription)")
                }
            }
        } catch {
            print("Failed to start workout session: \(error.localizedDescription)")
        }
    }
    
    // End a workout session and save it
    func endWorkout(distance: Double, elapsedTime: TimeInterval, heartRateSamples: [HKQuantitySample]) {
        workoutSession?.end()
        builder?.endCollection(withEnd: Date()) { [weak self] success, error in
            guard success else {
                print("Failed to end workout collection: \(String(describing: error))")
                return
            }
            
            // Add final distance and heart rate samples to the builder
            self?.builder?.add(heartRateSamples) { success, error in
                if success {
                    print("Heart rate samples added successfully.")
                } else {
                    print("Error adding heart rate samples: \(String(describing: error))")
                }
            }
            
            // Finish the workout builder and save it to HealthKit
            self?.builder?.finishWorkout { workout, error in
                if workout != nil {
                    print("Workout successfully saved to HealthKit!")
                } else if let error = error {
                    print("Error saving workout: \(error.localizedDescription)")
                }
            }
        }
    }
}
