// File: <YourProjectName>/HeartRateManager.swift
import HealthKit
import Combine

class HeartRateManager: ObservableObject {
    @Published var heartRate: Double = 0.0
    private let healthStore = HKHealthStore() // HealthKit store
    private var heartRateQuery: HKAnchoredObjectQuery? // Heart rate query
    private var timer: Timer? // Timer for simulator data
    private var healthKitManager: HealthKitManager // HealthKit manager instance
    
    init(healthKitManager: HealthKitManager) {
        self.healthKitManager = healthKitManager
    }
    
    // Start heart rate query if HealthKit is authorized
    func startHeartRateQuery() {
        guard healthKitManager.isAuthorized else {
            print("HealthKit not authorized for heart rate data.")
            return
        }
        
        #if targetEnvironment(simulator)
        // Simulate heart rate data in the simulator
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            DispatchQueue.main.async {
                self.heartRate = Double(arc4random_uniform(40) + 60) // Simulated heart rate between 60 and 100 bpm
            }
        }
        #else
        // Real heart rate data on a physical device
        let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate)!
        let predicate = HKQuery.predicateForSamples(withStart: Date(), end: nil, options: .strictStartDate)
        
        heartRateQuery = HKAnchoredObjectQuery(type: heartRateType, predicate: predicate, anchor: nil, limit: HKObjectQueryNoLimit) { [weak self] query, samples, deletedObjects, newAnchor, error in
            if let error = error {
                print("Heart rate query error: \(error.localizedDescription)")
                return
            }
            self?.updateHeartRate(samples)
        }
        
        heartRateQuery?.updateHandler = { [weak self] query, samples, deletedObjects, newAnchor, error in
            if let error = error {
                print("Heart rate query update error: \(error.localizedDescription)")
                return
            }
            self?.updateHeartRate(samples)
        }
        
        if let query = heartRateQuery {
            healthStore.execute(query)
        }
        #endif
    }
    
    func stopHeartRateQuery() {
        #if targetEnvironment(simulator)
        timer?.invalidate()
        timer = nil
        #else
        if let query = heartRateQuery {
            healthStore.stop(query)
            heartRateQuery = nil
        }
        #endif
    }
    
    private func updateHeartRate(_ samples: [HKSample]?) {
        guard let heartRateSamples = samples as? [HKQuantitySample] else { return }

        DispatchQueue.main.async {
            if let mostRecent = heartRateSamples.max(by: { $0.endDate < $1.endDate }) {
                self.heartRate = mostRecent.quantity.doubleValue(for: HKUnit(from: "count/min"))
            }
        }
    }

    deinit {
        stopHeartRateQuery()
    }
}
